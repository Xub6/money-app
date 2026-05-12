import 'dart:developer' as dev;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../data/repositories/app_state.dart';
import 'tour_session.dart';
import 'tour_step.dart';

class TourController extends ChangeNotifier {
  List<TourStep> _steps = [];
  bool _active = false;
  bool _hidden = false;
  int _stepIndex = 0;
  bool _finishing = false;
  bool _transitioning = false;
  bool _wrongTap = false;
  bool _stepJustCompleted = false;
  bool _currentStepCompleted = false;
  OnboardingMode _mode = OnboardingMode.quickStart;

  Rect? _cachedTargetRect;
  int _lastPreparedTab = -1;
  int _currentTab = 0;

  AppState? _appState;
  TourSession? _session;

  Future<void> Function(int tab)? _goToTab;
  VoidCallback? _onTourEnd;
  VoidCallback? _onTourSkip;

  // ── Public state ─────────────────────────────────────────────

  bool get isActive => _active;
  bool get isHidden => _hidden;
  int get stepIndex => _stepIndex;
  int get totalSteps => _steps.length;
  bool get isLastStep => _stepIndex == _steps.length - 1;
  bool get showWrongTapHint => _wrongTap;
  bool get stepJustCompleted => _stepJustCompleted;
  bool get isCurrentStepCompleted => _currentStepCompleted;
  Rect? get cachedTargetRect => _cachedTargetRect;
  OnboardingMode get mode => _mode;
  bool get isDemoMode => _mode == OnboardingMode.demo;
  TourSession? get session => _session;

  TourStep? get currentStep =>
      (_active && _steps.isNotEmpty && _stepIndex < _steps.length)
          ? _steps[_stepIndex]
          : null;

  // ── Initialisation ───────────────────────────────────────────

  void init({
    required Future<void> Function(int tab) goToTab,
    required AppState appState,
    VoidCallback? onTourEnd,
    VoidCallback? onTourSkip,
  }) {
    _goToTab = goToTab;
    _onTourEnd = onTourEnd;
    _onTourSkip = onTourSkip;
    _appState?.removeListener(_onAppStateChanged);
    _appState = appState;
    _appState!.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateChanged);
    super.dispose();
  }

  // ── Tour lifecycle ───────────────────────────────────────────

  Future<void> startMission(
    BuildContext context,
    OnboardingMode mode,
  ) async {
    _mode = mode;
    final appState = _appState;

    final realAccountCount = appState?.accounts
            .where((a) => !a.id.startsWith('tour_demo_'))
            .length ??
        0;
    _session = TourSession(startAccountCount: realAccountCount);

    dev.log('[Onboarding] start mode=${mode.name}  '
        'startAccounts=$realAccountCount  '
        'sessionAt=${_session!.createdAt}');

    _steps = switch (mode) {
      OnboardingMode.quickStart => buildQuickStartSteps(context),
      OnboardingMode.fullSetup => buildFullSetupSteps(context),
      OnboardingMode.demo => buildDemoSteps(context),
    };

    _stepIndex = 0;
    _active = true;
    _hidden = true;
    _finishing = false;
    _transitioning = false;
    _wrongTap = false;
    _stepJustCompleted = false;
    _currentStepCompleted = false;
    _cachedTargetRect = null;
    _lastPreparedTab = -1;
    _currentTab = 0;

    await _prepareStep();
    _hidden = false;
    notifyListeners();
    _checkCurrentStepPredicate();
  }

  Future<void> next() async {
    if (_finishing || !_active || _transitioning) return;
    final step = currentStep;
    // actionRequired 步驟：predicate 未滿足時禁止前進
    if (step != null && step.isActionRequired && !_currentStepCompleted) return;
    if (isLastStep) {
      await finish();
      return;
    }
    _transitioning = true;
    _stepIndex++;
    _wrongTap = false;
    _stepJustCompleted = false;
    _currentStepCompleted = false;
    _cachedTargetRect = null;
    _hidden = true;
    notifyListeners();
    await _prepareStep();
    _hidden = false;
    _transitioning = false;
    notifyListeners();
    _checkCurrentStepPredicate();
  }

  Future<void> prev() async {
    if (_finishing || !_active || _stepIndex == 0 || _transitioning) return;
    _transitioning = true;
    _stepIndex--;
    _wrongTap = false;
    _stepJustCompleted = false;
    _currentStepCompleted = false;
    _cachedTargetRect = null;
    _hidden = true;
    notifyListeners();
    await _prepareStep();
    _hidden = false;
    _transitioning = false;
    notifyListeners();
    _checkCurrentStepPredicate();
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
    _wrongTap = false;
    _stepJustCompleted = false;
    _currentStepCompleted = false;
    _transitioning = false;
    notifyListeners();
    _onTourEnd?.call();
  }

  void clearDemoMode() {
    _mode = OnboardingMode.quickStart;
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

  // ── Event notifications ──────────────────────────────────────

  void notifyTabChanged(int newTab) {
    _currentTab = newTab;
    if (!_active || _finishing) return;
    _checkCurrentStepPredicate();
  }

  void notifyRouteOpened(String routeId) {
    if (!_active || _finishing) return;
    if (routeId == 'accountPage') _session?.accountPageWasOpened = true;
    _checkCurrentStepPredicate();
  }

  void notifyWrongTap() {
    if (!_active || _finishing) return;
    if (_wrongTap) return;
    _wrongTap = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!_wrongTap) return;
      _wrongTap = false;
      notifyListeners();
    });
  }

  // ── Predicate evaluation ─────────────────────────────────────

  void _onAppStateChanged() {
    if (!_active || _finishing || _transitioning) return;
    _checkCurrentStepPredicate();
  }

  void _checkCurrentStepPredicate() {
    if (_currentStepCompleted || _transitioning || _finishing) return;
    final step = currentStep;
    if (step == null || !step.isActionRequired) return;
    final pred = step.completionPredicate;
    if (pred == null) return;
    final appState = _appState;
    final session = _session;
    if (appState == null || session == null) return;

    final satisfied = pred(appState, session, _currentTab);
    if (satisfied) _onActionCompleted();
  }

  // ── Completion feedback + auto-advance ───────────────────────

  Future<void> _onActionCompleted() async {
    if (_currentStepCompleted) return;
    _currentStepCompleted = true;
    _stepJustCompleted = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!_active || _finishing) return;
    _stepJustCompleted = false;
    await next(); // guard in next() passes because _currentStepCompleted == true
  }

  // ── Step preparation ─────────────────────────────────────────

  Future<void> _prepareStep() async {
    if (_steps.isEmpty || _stepIndex >= _steps.length) return;
    final step = _steps[_stepIndex];

    final tabChanged = _lastPreparedTab != step.tab;
    _lastPreparedTab = step.tab;

    if (_goToTab != null) {
      await _goToTab!(step.tab);
    }
    if (tabChanged) {
      await Future.delayed(const Duration(milliseconds: 80));
    }

    final ctx = step.targetKey?.currentContext;
    if (ctx != null) {
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (_) {}
    }

    // Stability-based rect detection: require 2 consecutive readings < 2px diff
    Rect? prevRect;
    _cachedTargetRect = null;
    for (int i = 0; i < 5; i++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 16));
      final curr = _findRectOnScreen(step.targetKey);
      if (curr != null && prevRect != null) {
        final dx = (curr.left - prevRect.left).abs();
        final dy = (curr.top - prevRect.top).abs();
        if (dx < 2.0 && dy < 2.0) {
          _cachedTargetRect = curr;
          break;
        }
      }
      prevRect = curr;
      if (curr != null) _cachedTargetRect = curr;
    }
  }

  static Rect? _findRectOnScreen(GlobalKey? key) {
    if (key == null) return null;
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) return null;
      if (box.size.width < 1 || box.size.height < 1) return null;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dx < -600 || pos.dy < -600 || pos.dx > 4000 || pos.dy > 4000) {
        return null;
      }
      return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
    } catch (_) {
      return null;
    }
  }
}
