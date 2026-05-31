import 'dart:developer' as dev;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../data/models/account.dart';
import '../../data/models/expense_item.dart';
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
  // Tracks number of open ModalBottomSheets; overlay is hidden while > 0
  int _bottomSheetDepth = 0;
  // Set when a PageRoute push/pop occurs; _prepareStep waits for layout
  bool _routeTransitionPending = false;

  Rect? _cachedTargetRect;
  int _lastPreparedTab = -1;
  int _currentTab = 0;

  AppState? _appState;
  TourSession? _session;

  Future<void> Function(int tab)? _goToTab;
  VoidCallback? _popToMain;
  void Function(String locKey)? _showSuccessMsg;
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
    VoidCallback? popToMain,
    void Function(String locKey)? onShowSuccess,
  }) {
    _goToTab = goToTab;
    _popToMain = popToMain;
    _showSuccessMsg = onShowSuccess;
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
    _routeTransitionPending = false;
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

  /// Called from AccountPage when the + AppBar button is tapped.
  void notifyAddAccountPageOpened() {
    if (!_active || _finishing) return;
    _session?.addAccountPageOpened = true;
    // Immediately clear spotlight so AddEditAccountPage is fully interactive.
    _cachedTargetRect = null;
    notifyListeners();
    _checkCurrentStepPredicate();
  }

  /// Call just before pushing any form page. Clears spotlight so the overlay
  /// enters fullPageInteraction mode (no dark overlay, no blockers).
  void notifyFormOpened() {
    if (!_active || _finishing) return;
    _cachedTargetRect = null;
    notifyListeners();
  }

  /// Call when a form page is dismissed without saving (user cancelled).
  /// Re-prepares the current step to restore the spotlight.
  Future<void> notifyFormDismissed() async {
    if (!_active || _finishing) return;
    await _prepareStep();
    notifyListeners();
  }

  /// Called from AccountPage after a new account is saved.
  void onAccountCreated(Account account) {
    if (!_active || _finishing) return;
    _session?.accountCreated = true;
    dev.log('[Tour] onAccountCreated: ${account.displayName}');
    _checkCurrentStepPredicate();
  }

  /// Called from main.dart after a new expense is saved.
  void onTransactionCreated(ExpenseItem expense) {
    if (!_active || _finishing) return;
    _session?.transactionCreated = true;
    dev.log('[Tour] onTransactionCreated: ${expense.amount}');
    _checkCurrentStepPredicate();
  }

  /// Called by NavigatorObserver when a ModalBottomSheet is pushed.
  /// Hides the overlay so bottom-sheet content is not obscured by the panel.
  /// Called by NavigatorObserver when a regular PageRoute is pushed.
  /// Clears stale rect immediately; _prepareStep will wait for new layout.
  void notifyPageRoutePushed() {
    if (!_active || _finishing) return;
    _routeTransitionPending = true;
    _cachedTargetRect = null;
    notifyListeners();
  }

  /// Called by NavigatorObserver when a regular PageRoute is popped.
  /// Clears stale rect immediately; _prepareStep will wait for new layout.
  void notifyPageRoutePopped() {
    if (!_active || _finishing) return;
    _routeTransitionPending = true;
    _cachedTargetRect = null;
    notifyListeners();
  }

  void notifyBottomSheetOpened() {
    _bottomSheetDepth++;
    if (!_hidden) {
      _hidden = true;
      notifyListeners();
    }
  }

  /// Called by NavigatorObserver when a ModalBottomSheet is popped.
  /// Restores the overlay once all sheets are closed.
  void notifyBottomSheetClosed() {
    if (_bottomSheetDepth > 0) _bottomSheetDepth--;
    if (_bottomSheetDepth == 0 && _active && !_finishing && _hidden) {
      _hidden = false;
      notifyListeners();
    }
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
    try {
      await _handleStepCompletionSideEffects();
    } catch (e) {
      dev.log('[Tour] _handleStepCompletionSideEffects error: $e');
    }
    if (!_active || _finishing) return;
    await next(); // guard in next() passes because _currentStepCompleted == true
  }

  // Steps that require post-completion navigation (pop pushed routes, switch tab,
  // show success feedback) before auto-advancing to the next step.
  Future<void> _handleStepCompletionSideEffects() async {
    final step = currentStep;
    if (step == null) return;
    dev.log('[Tour] sideEffects: step=${step.id}');
    // After account created: pop back to MainShell → switch to tab 0 → success toast
    if (step.id == 'qs_s4' || step.id == 'fs_s2') {
      // Pop AccountPage (and any other pushed routes) back to root.
      // _popToMain uses Navigator.popUntil(isFirst) captured at MainShell context.
      _popToMain?.call();
      dev.log('[Tour] popToMain called for ${step.id}');
      // Wait for pop animation to complete (default Flutter pop animation ≈ 300ms)
      await Future.delayed(const Duration(milliseconds: 420));
      // Switch to dashboard tab and await the page-switch animation
      await _goToTab?.call(0);
      // Wait one stable frame after tab switch
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 80));
      // Show success toast — uses overlay toast (not SnackBar) so FAB stays at bottom
      _showSuccessMsg?.call('tour_account_created_success');
      // Give the toast one frame to render before _prepareStep reads FAB rect
      await WidgetsBinding.instance.endOfFrame;
    }
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

    // Wait for route animation to complete before measuring rects.
    // Cleared after waiting so subsequent _prepareStep calls are not delayed.
    if (_routeTransitionPending) {
      _routeTransitionPending = false;
      await Future.delayed(const Duration(milliseconds: 380));
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

    // Stability-based rect detection: require 2 consecutive readings < 2px diff.
    // No fallback to stale rects — if target is mid-animation or not yet mounted,
    // keep _cachedTargetRect null so the overlay does not display a wrong spotlight.
    Rect? prevRect;
    _cachedTargetRect = null;
    for (int i = 0; i < 6; i++) {
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
      // Intentionally no fallback: don't assign _cachedTargetRect unless stable.
    }

    // If still null after stability loop, schedule a post-frame retry so that
    // widgets becoming mounted on the next frame are caught without extra delay.
    if (_cachedTargetRect == null && step.targetKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_active || _finishing || _transitioning) return;
        final rect = _findRectOnScreen(step.targetKey);
        if (rect != null) {
          _cachedTargetRect = rect;
          notifyListeners();
        }
      });
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
