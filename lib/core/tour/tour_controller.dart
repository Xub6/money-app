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
  bool _transitioning = false; // debounce rapid taps

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
    _transitioning = false;
    await _prepareStep();
    notifyListeners();
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
    _hidden = false;
    notifyListeners(); // immediate feedback: new tooltip visible, spotlight may be null
    await _prepareStep();
    _transitioning = false;
    notifyListeners(); // spotlight settles at final position
  }

  Future<void> prev() async {
    if (_finishing || !_active || _stepIndex == 0 || _transitioning) return;
    _transitioning = true;
    _stepIndex--;
    _waitingForInteraction = false;
    _hidden = false;
    notifyListeners();
    await _prepareStep();
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

    _goToTab?.call(step.tab);
    await Future.delayed(const Duration(milliseconds: 150)); // reduced from 420

    // Scroll the target widget into view. Widgets not inside a Scrollable
    // (AppBar, FAB, BottomAppBar) will throw — caught silently since always visible.
    final ctx = step.targetKey.currentContext;
    if (ctx != null) {
      try {
        final alignment = step.side == TooltipSide.above ? 0.6 : 0.1;
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300), // reduced from 350
          curve: Curves.easeInOut,
          alignment: alignment,
        );
        await Future.delayed(const Duration(milliseconds: 60)); // reduced from 120
      } catch (_) {}
    }

    _waitingForInteraction = step.isInteractive;
  }
}
