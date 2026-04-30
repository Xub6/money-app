import 'package:flutter/foundation.dart';
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
  Future<void> Function()? _scrollToFeedback;
  Future<void> Function()? _scrollToCategoryCard;

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
    required Future<void> Function() scrollToFeedback,
    required Future<void> Function() scrollToCategoryCard,
  }) {
    _goToTab = goToTab;
    _scrollToFeedback = scrollToFeedback;
    _scrollToCategoryCard = scrollToCategoryCard;
  }

  // ── Tour lifecycle ───────────────────────────────────────────

  Future<void> start() async {
    _steps = buildTourSteps();
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
    _hidden = false;
    _waitingForInteraction = false;
    notifyListeners();
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

    // Dashboard: scroll so categoryCard (step 3) is visible
    if (_stepIndex == 3) {
      await _scrollToCategoryCard?.call();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Manage page: scroll to bottom for steps 12+
    if (step.tab == 3 && _stepIndex >= 12) {
      await _scrollToFeedback?.call();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _waitingForInteraction = step.isInteractive;
  }
}
