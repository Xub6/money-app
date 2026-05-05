import 'package:flutter/foundation.dart';
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
    _hidden = false;
    _finishing = false;
    await _prepareStep();
    notifyListeners();
  }

  Future<void> next() async {
    if (_finishing || !_active) return;
    if (isLastStep) {
      await finish();
      return;
    }
    _stepIndex++;
    _waitingForInteraction = false;
    _hidden = false; // ensure overlay visible on new step
    await _prepareStep();
    notifyListeners();
  }

  Future<void> prev() async {
    if (_finishing || !_active || _stepIndex == 0) return;
    _stepIndex--;
    _waitingForInteraction = false;
    _hidden = false;
    await _prepareStep();
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
    notifyListeners();
    _onTourEnd?.call();
    await OnboardingService.markOnboardingSeen();
  }

  /// Temporarily hide the overlay (e.g. while a modal route is open).
  void hide() {
    if (_hidden) return;
    _hidden = true;
    notifyListeners();
  }

  /// Restore the overlay after hiding.
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

    _goToTab?.call(step.tab);
    await Future.delayed(const Duration(milliseconds: 420));

    // Scroll the target widget into view using Flutter's built-in mechanism.
    // Widgets not inside a Scrollable (AppBar, FAB, BottomAppBar) will throw —
    // we catch silently since those widgets are always visible on screen.
    final ctx = step.targetKey.currentContext;
    if (ctx != null) {
      try {
        final alignment = step.side == TooltipSide.above ? 0.6 : 0.1;
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: alignment,
        );
        await Future.delayed(const Duration(milliseconds: 120));
      } catch (_) {}
    }

    _waitingForInteraction = step.isInteractive;
  }
}
