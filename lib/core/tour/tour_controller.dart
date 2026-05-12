import 'dart:developer' as dev;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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
  OnboardingMode _mode = OnboardingMode.quickStart;

  Rect? _cachedTargetRect;
  int _lastPreparedTab = -1;

  // goToTab 改為 async，讓呼叫端 await animateToPage 完成後再算 rect
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
  Rect? get cachedTargetRect => _cachedTargetRect;
  OnboardingMode get mode => _mode;
  bool get isDemoMode => _mode == OnboardingMode.demo;

  TourStep? get currentStep =>
      (_active && _steps.isNotEmpty && _stepIndex < _steps.length)
          ? _steps[_stepIndex]
          : null;

  // ── Initialisation ───────────────────────────────────────────

  void init({
    required Future<void> Function(int tab) goToTab,
    VoidCallback? onTourEnd,
    VoidCallback? onTourSkip,
  }) {
    _goToTab = goToTab;
    _onTourEnd = onTourEnd;
    _onTourSkip = onTourSkip;
  }

  // ── Tour lifecycle ───────────────────────────────────────────

  Future<void> startMission(
    BuildContext context,
    OnboardingMode mode, {
    bool hasAccounts = false,
    bool hasTransactions = false,
  }) async {
    _mode = mode;
    dev.log('[Onboarding] start mode=${mode.name}  hasAccounts=$hasAccounts  hasTransactions=$hasTransactions');

    _steps = switch (mode) {
      OnboardingMode.quickStart => buildQuickStartSteps(
          context,
          hasAccounts: hasAccounts,
          hasTransactions: hasTransactions,
        ),
      OnboardingMode.fullSetup => buildFullSetupSteps(
          context,
          hasAccounts: hasAccounts,
          hasTransactions: hasTransactions,
        ),
      OnboardingMode.demo => buildDemoSteps(context),
    };

    _stepIndex = 0;
    _active = true;
    _hidden = true;
    _finishing = false;
    _transitioning = false;
    _wrongTap = false;
    _stepJustCompleted = false;
    _cachedTargetRect = null;
    _lastPreparedTab = -1;
    await _prepareStep();
    _hidden = false;
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
    _wrongTap = false;
    _stepJustCompleted = false;
    _cachedTargetRect = null;
    _hidden = true;
    notifyListeners();
    await _prepareStep();
    _hidden = false;
    _transitioning = false;
    notifyListeners();
  }

  Future<void> prev() async {
    if (_finishing || !_active || _stepIndex == 0 || _transitioning) return;
    _transitioning = true;
    _stepIndex--;
    _wrongTap = false;
    _stepJustCompleted = false;
    _cachedTargetRect = null;
    _hidden = true;
    notifyListeners();
    await _prepareStep();
    _hidden = false;
    _transitioning = false;
    notifyListeners();
  }

  Future<void> skipStep() async => next();

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
    _transitioning = false;
    notifyListeners();
    _onTourEnd?.call();
    // markOnboardingSeen 由 main.dart 的 _handleTourEnd 負責
  }

  /// Demo 模式結束後（dialog 處理完）呼叫以清除 mode 旗標
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

  // ── Event-driven completion ──────────────────────────────────

  void notifyTabChanged(int newTab) {
    if (!_active || _transitioning || _finishing || _stepJustCompleted) return;
    final step = currentStep;
    if (step?.actionType == TourActionType.waitForTabChange &&
        newTab == step?.expectedTab) {
      _onActionCompleted();
    }
  }

  void notifyRouteOpened(String routeId) {
    if (!_active || _transitioning || _finishing || _stepJustCompleted) return;
    final step = currentStep;
    if (step?.actionType == TourActionType.waitForRouteOpen &&
        step?.expectedRouteId == routeId) {
      _onActionCompleted();
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

  // ── Completion feedback + auto-advance ───────────────────────

  Future<void> _onActionCompleted() async {
    _stepJustCompleted = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!_active || _finishing) return;
    _stepJustCompleted = false;
    await next();
  }

  // ── Step preparation ─────────────────────────────────────────

  Future<void> _prepareStep() async {
    if (_steps.isEmpty || _stepIndex >= _steps.length) return;
    final step = _steps[_stepIndex];

    final tabChanged = _lastPreparedTab != step.tab;
    _lastPreparedTab = step.tab;

    // await animateToPage 完成，確認 PageView 切換動畫真正結束後才計算 rect
    if (_goToTab != null) {
      await _goToTab!(step.tab);
    }
    // 動畫結束後再等一幀讓 layout 穩定
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

    await WidgetsBinding.instance.endOfFrame;

    // 最多重試 3 次，確認 rect 不為 null 且有實際 size
    _cachedTargetRect = _findRectOnScreen(step.targetKey);
    for (int retry = 0; retry < 3 && _cachedTargetRect == null; retry++) {
      await WidgetsBinding.instance.endOfFrame;
      _cachedTargetRect = _findRectOnScreen(step.targetKey);
    }
  }

  static Rect? _findRectOnScreen(GlobalKey? key) {
    if (key == null) return null;
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) return null;
      // size 為 0 時不框（禁止亂框）
      if (box.size.width < 1 || box.size.height < 1) return null;
      final pos = box.localToGlobal(Offset.zero);
      // ±600 sanity check：過濾 PageView 相鄰頁 off-screen 座標
      if (pos.dx < -600 || pos.dy < -600 || pos.dx > 4000 || pos.dy > 4000) {
        return null;
      }
      return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
    } catch (_) {
      return null;
    }
  }
}
