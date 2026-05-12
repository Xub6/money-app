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
  bool _finishing = false;
  bool _transitioning = false;
  bool _wrongTap = false;
  int _currentTab = 0;

  Rect? _cachedTargetRect;
  int _lastPreparedTab = -1;

  void Function(int tab)? _goToTab;
  VoidCallback? _onTourEnd;
  VoidCallback? _onTourSkip;

  // ── Public state ─────────────────────────────────────────────

  bool get isActive => _active;
  bool get isHidden => _hidden;
  int get stepIndex => _stepIndex;
  int get totalSteps => _steps.length;
  bool get isLastStep => _stepIndex == _steps.length - 1;
  bool get showWrongTapHint => _wrongTap;
  Rect? get cachedTargetRect => _cachedTargetRect;

  TourStep? get currentStep =>
      (_active && _steps.isNotEmpty && _stepIndex < _steps.length)
          ? _steps[_stepIndex]
          : null;

  // ── Initialisation ───────────────────────────────────────────

  void init({
    required void Function(int tab) goToTab,
    VoidCallback? onTourEnd,
    VoidCallback? onTourSkip,
  }) {
    _goToTab = goToTab;
    _onTourEnd = onTourEnd;
    _onTourSkip = onTourSkip;
  }

  // ── Tour lifecycle ───────────────────────────────────────────

  Future<void> start(BuildContext context) async {
    _steps = buildTourSteps(context);
    _stepIndex = 0;
    _active = true;
    _hidden = true;
    _finishing = false;
    _transitioning = false;
    _wrongTap = false;
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

  // ── Event-driven completion ──────────────────────────────────

  /// Called by the main shell whenever the PageView settles on a new tab.
  void notifyTabChanged(int newTab) {
    _currentTab = newTab;
    if (!_active || _transitioning || _finishing) return;
    final step = currentStep;
    if (step?.actionType == TourActionType.waitForTabChange &&
        newTab == step?.expectedTab) {
      next();
    }
  }

  /// Called by FAB/card handlers when they open a specific route.
  /// [routeId]: 'addExpense' | 'addHolding' | 'accountPage'
  void notifyRouteOpened(String routeId) {
    if (!_active || _transitioning || _finishing) return;
    final step = currentStep;
    if (step?.actionType == TourActionType.waitForRouteOpen &&
        step?.expectedRouteId == routeId) {
      next();
    }
  }

  /// Called by interactive blockers when user taps outside the spotlight.
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

  // ── Step preparation ─────────────────────────────────────────

  Future<void> _prepareStep() async {
    if (_steps.isEmpty || _stepIndex >= _steps.length) return;
    final step = _steps[_stepIndex];

    final tabChanged = _lastPreparedTab != step.tab;
    _goToTab?.call(step.tab);
    _lastPreparedTab = step.tab;

    await Future.delayed(Duration(milliseconds: tabChanged ? 350 : 150));

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

    _cachedTargetRect = _findRectOnScreen(step.targetKey);
    for (int retry = 0; retry < 2 && _cachedTargetRect == null; retry++) {
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
