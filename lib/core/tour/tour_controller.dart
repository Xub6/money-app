import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../screens/onboarding/onboarding_service.dart';
import 'tour_step.dart';

class TourController extends ChangeNotifier {
  List<TourStep> _steps = [];
  bool _active = false;
  bool _hidden = false;
  int _stepIndex = 0;
  bool _waitingForInteraction = false;
  bool _finishing = false;
  bool _transitioning = false;

  // Pre-calculated target rect — set after scroll+layout settle, never stale.
  // Overlay reads this instead of calling _findRect() in build(), which
  // prevents spotlights from appearing at off-screen / off-tab positions.
  Rect? _cachedTargetRect;

  void Function(int tab)? _goToTab;
  VoidCallback? _onTourStart;
  VoidCallback? _onTourEnd;
  VoidCallback? _onTourSkip;

  // ── Public state ─────────────────────────────────────────────

  bool get isActive => _active;
  bool get isHidden => _hidden;
  int get stepIndex => _stepIndex;
  int get totalSteps => _steps.length;
  bool get isWaitingForInteraction => _waitingForInteraction;
  bool get isLastStep => _stepIndex == _steps.length - 1;

  /// Stable target rect calculated after layout.  Null during transitions and
  /// when the target widget cannot be located on-screen.
  Rect? get cachedTargetRect => _cachedTargetRect;

  TourStep? get currentStep =>
      (_active && _steps.isNotEmpty && _stepIndex < _steps.length)
          ? _steps[_stepIndex]
          : null;

  // ── Initialisation ───────────────────────────────────────────

  void init({
    required void Function(int tab) goToTab,
    VoidCallback? onTourStart,
    VoidCallback? onTourEnd,
    VoidCallback? onTourSkip,
  }) {
    _goToTab = goToTab;
    _onTourStart = onTourStart;
    _onTourEnd = onTourEnd;
    _onTourSkip = onTourSkip;
  }

  // ── Tour lifecycle ───────────────────────────────────────────

  Future<void> start(BuildContext context) async {
    _onTourStart?.call();
    _steps = buildTourSteps(context);
    _stepIndex = 0;
    _active = true;
    _hidden = true; // keep hidden until position is ready
    _finishing = false;
    _transitioning = false;
    _cachedTargetRect = null;
    await _prepareStep(); // calculates _cachedTargetRect
    _hidden = false;
    notifyListeners(); // single reveal at correct position
  }

  Future<void> next() async {
    if (_finishing || !_active || _transitioning) return;
    if (isLastStep) {
      await finish();
      return;
    }
    _transitioning = true;
    _stepIndex++;
    _waitingForInteraction = false;
    _cachedTargetRect = null;
    _hidden = true; // hide overlay — prevents showing at stale / off-tab position
    notifyListeners(); // overlay disappears cleanly
    await _prepareStep(); // tab switch → scroll → endOfFrame → rect calc
    _hidden = false;
    _transitioning = false;
    notifyListeners(); // single reveal at stable position
  }

  Future<void> prev() async {
    if (_finishing || !_active || _stepIndex == 0 || _transitioning) return;
    _transitioning = true;
    _stepIndex--;
    _waitingForInteraction = false;
    _cachedTargetRect = null;
    _hidden = true;
    notifyListeners();
    await _prepareStep();
    _hidden = false;
    _transitioning = false;
    notifyListeners();
  }

  Future<void> skip() async {
    await finish();
    _onTourSkip?.call();
  }

  Future<void> finish() async {
    if (_finishing) return;
    _finishing = true;
    _active = false;
    _hidden = false;
    _waitingForInteraction = false;
    _transitioning = false;
    notifyListeners();
    _onTourEnd?.call();
    await OnboardingService.markOnboardingSeen();
  }

  void hide() {
    if (_hidden) return;
    _hidden = true;
    notifyListeners();
  }

  void unhide() {
    if (!_hidden) return;
    _hidden = false;
    notifyListeners();
  }

  // Called by interactive target widgets after the user completes the action.
  void onInteractionComplete() {
    if (!_waitingForInteraction) return;
    _waitingForInteraction = false;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), next);
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<void> _prepareStep() async {
    if (_steps.isEmpty || _stepIndex >= _steps.length) return;
    final step = _steps[_stepIndex];

    // 1. Switch to the correct tab.
    _goToTab?.call(step.tab);

    // 2. Wait for the tab's page to mount and its first layout to complete.
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Scroll the target widget into view if it is inside a Scrollable.
    //    Widgets not in a Scrollable (AppBar, FAB, BottomAppBar) throw — caught
    //    silently since those are always visible.
    final ctx = step.targetKey.currentContext;
    if (ctx != null) {
      try {
        final alignment = step.side == TooltipSide.above ? 0.6 : 0.1;
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: alignment,
        );
        // Short settle time after scroll animation ends.
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (_) {}
    }

    // 4. Wait for the current frame to fully paint before reading RenderBox.
    //    This ensures localToGlobal() returns the post-scroll final position.
    await WidgetsBinding.instance.endOfFrame;

    // 5. Calculate rect.  Retry up to 2 extra frames for widgets that need
    //    a post-frame callback to finish their own layout (e.g. lazy builders).
    _cachedTargetRect = _findRectOnScreen(step.targetKey);
    for (int retry = 0; retry < 2 && _cachedTargetRect == null; retry++) {
      await WidgetsBinding.instance.endOfFrame;
      _cachedTargetRect = _findRectOnScreen(step.targetKey);
    }
    // If still null, overlay shows full dark overlay with centered tooltip as fallback.

    _waitingForInteraction = step.isInteractive;
  }

  /// Reads the on-screen bounding rect of [key]'s widget.
  ///
  /// Returns null when:
  ///   - the context is not yet mounted
  ///   - the RenderBox is detached or has no size
  ///   - the position is clearly off-screen (e.g. widget belongs to an
  ///     adjacent PageView page whose global-x is several screen-widths away)
  static Rect? _findRectOnScreen(GlobalKey key) {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) return null;
      final pos = box.localToGlobal(Offset.zero);
      // Sanity-check: reject positions that are grossly off-screen.
      // PageView keeps adjacent pages rendered at ±screenWidth offset; using
      // a ±600 dp guard catches those without needing the actual screen size.
      if (pos.dx < -600 || pos.dy < -600 || pos.dx > 4000 || pos.dy > 4000) {
        return null;
      }
      return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
    } catch (_) {
      return null;
    }
  }
}
