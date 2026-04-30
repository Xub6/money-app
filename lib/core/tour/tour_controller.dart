import 'package:flutter/foundation.dart';
import '../../screens/onboarding/onboarding_service.dart';
import 'tour_step.dart';

class TourController extends ChangeNotifier {
  List<TourStep> _steps = [];
  bool _active = false;
  int _stepIndex = 0;
  bool _waitingForInteraction = false;
  bool _finishing = false;

  // Injected by MainShell after first frame
  void Function(int tab)? _goToTab;
  Future<void> Function()? _scrollToFeedback;

  // ── Public state ─────────────────────────────────────────────

  bool get isActive => _active;
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
    required Future<void> Function() scrollToFeedback,
  }) {
    _goToTab = goToTab;
    _scrollToFeedback = scrollToFeedback;
  }

  // ── Tour lifecycle ───────────────────────────────────────────

  Future<void> start() async {
    _steps = buildTourSteps();
    _stepIndex = 0;
    _active = true;
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
    await _prepareStep();
    notifyListeners();
  }

  Future<void> prev() async {
    if (_finishing || !_active || _stepIndex == 0) return;
    _stepIndex--;
    _waitingForInteraction = false;
    await _prepareStep();
    notifyListeners();
  }

  Future<void> skip() => finish();

  Future<void> finish() async {
    if (_finishing) return;
    _finishing = true;
    _active = false;
    _waitingForInteraction = false;
    notifyListeners();
    await OnboardingService.markOnboardingSeen();
  }

  // Called by interactive target widgets (FAB, feedback tile) after
  // the user has completed the interaction.
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

    // Navigate to the correct tab
    _goToTab?.call(step.tab);

    // Wait for tab animation + widget layout
    await Future.delayed(const Duration(milliseconds: 420));

    // For manage-page steps near the bottom, scroll down
    if (step.tab == 3 && _stepIndex >= 12) {
      await _scrollToFeedback?.call();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _waitingForInteraction = step.isInteractive;
  }
}
