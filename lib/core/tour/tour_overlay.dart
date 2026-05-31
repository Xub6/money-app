import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/app_state.dart';
import 'tour_controller.dart';
import 'tour_step.dart';

class TourOverlay extends StatefulWidget {
  const TourOverlay({super.key});

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TourController>(
      builder: (context, ctrl, _) {
        if (!ctrl.isActive || ctrl.isHidden) return const SizedBox.shrink();
        final step = ctrl.currentStep;
        if (step == null) return const SizedBox.shrink();

        return Consumer<AppState>(
          builder: (context, appState, _) {
            final rawRect = ctrl.cachedTargetRect;
            final screen = MediaQuery.of(context).size;
            final safePad = MediaQuery.of(context).padding;

            // 超長卡片截斷
            Rect? effectiveRect = rawRect;
            if (rawRect != null && rawRect.height > screen.height * 0.65) {
              effectiveRect = Rect.fromLTWH(
                  rawRect.left, rawRect.top, rawRect.width, 250.0);
            }

            Rect? spotRect;
            if (effectiveRect != null) {
              final inflated = effectiveRect.inflate(10.0);
              spotRect = Rect.fromLTRB(
                inflated.left.clamp(0.0, screen.width),
                inflated.top.clamp(safePad.top, screen.height),
                inflated.right.clamp(0.0, screen.width),
                inflated.bottom.clamp(0.0, screen.height),
              );
              if (spotRect.width < 1 || spotRect.height < 1) spotRect = null;
            }

            const panelH = 210.0;
            final panelAtTop = spotRect != null &&
                spotRect.center.dy > screen.height * 0.60;
            // Demo Banner height: status bar + 2px padding + text (~14px) + 4px bottom
            final demoBannerH = ctrl.isDemoMode ? safePad.top + 20.0 : 0.0;

            // Resolve dynamic body text
            final bodyText = (step.dynamicBody != null && ctrl.session != null)
                ? step.dynamicBody!(appState, ctrl.session!, context)
                : step.body;

            // fullPageInteraction: actionRequired but no spotlight target
            // (e.g. fill-in-form steps). Panel is placed at the TOP so it
            // does not overlap the calculator BottomSheet or bottom form elements.
            // The NavigatorObserver hides the overlay entirely during BottomSheets.
            final isFullPageInteraction =
                step.isActionRequired && spotRect == null;

            if (isFullPageInteraction) {
              return Stack(
                children: [
                  _MissionPanel(
                    step: step,
                    bodyText: bodyText,
                    stepIndex: ctrl.stepIndex,
                    totalSteps: ctrl.totalSteps,
                    panelAtTop: false, // bottom panel keeps AppBar save button accessible
                    panelH: panelH,
                    safePad: safePad,
                    demoBannerH: demoBannerH,
                    wrongTap: ctrl.showWrongTapHint,
                    stepJustCompleted: ctrl.stepJustCompleted,
                    isCurrentStepCompleted: ctrl.isCurrentStepCompleted,
                    isLast: ctrl.isLastStep,
                    onNext: ctrl.next,
                    onPrev: ctrl.prev,
                    onSkipAll: ctrl.skip,
                  ),
                  if (ctrl.isDemoMode)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          padding: EdgeInsets.only(
                            top: safePad.top + 2,
                            bottom: 4,
                          ),
                          color: Colors.orange.withValues(alpha: 0.92),
                          alignment: Alignment.center,
                          child: Text(
                            AppLocalizations.of(context, 'tour_demo_banner'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            return Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  // ── 遮罩 + spotlight 切口 ──────────────────────
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (_, __) => CustomPaint(
                            painter:
                                _SpotlightPainter(spotRect, _glowAnim.value),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── 互動阻擋層 ───────────────────────────────────
                  // actionRequired + spotlight: 只阻擋 spotlight 外區域
                  // info / finish: 阻擋全畫面（只有面板按鈕可操作）
                  if (step.isActionRequired && spotRect != null)
                    ..._buildInteractiveBlockers(spotRect, screen, ctrl)
                  else if (!step.isActionRequired)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                      ),
                    ),

                  // ── 任務面板 ───────────────────────────────────
                  _MissionPanel(
                    step: step,
                    bodyText: bodyText,
                    stepIndex: ctrl.stepIndex,
                    totalSteps: ctrl.totalSteps,
                    panelAtTop: panelAtTop,
                    panelH: panelH,
                    safePad: safePad,
                    demoBannerH: demoBannerH,
                    wrongTap: ctrl.showWrongTapHint,
                    stepJustCompleted: ctrl.stepJustCompleted,
                    isCurrentStepCompleted: ctrl.isCurrentStepCompleted,
                    isLast: ctrl.isLastStep,
                    onNext: ctrl.next,
                    onPrev: ctrl.prev,
                    onSkipAll: ctrl.skip,
                  ),

                  // ── Demo 橫幅 ─────────────────────────────────
                  if (ctrl.isDemoMode)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          padding: EdgeInsets.only(
                            top: safePad.top + 2,
                            bottom: 4,
                          ),
                          color: Colors.orange.withValues(alpha: 0.92),
                          alignment: Alignment.center,
                          child: Text(
                            AppLocalizations.of(
                                context, 'tour_demo_banner'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static List<Widget> _buildInteractiveBlockers(
      Rect spot, Size screen, TourController ctrl) {
    onWrongTap() => ctrl.notifyWrongTap();
    const minH = 0.0;
    return [
      if (spot.top > 0)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: spot.top.clamp(minH, screen.height),
          child: GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onWrongTap),
        ),
      if (spot.bottom < screen.height)
        Positioned(
          top: spot.bottom.clamp(0, screen.height),
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onWrongTap),
        ),
      if (spot.left > 0)
        Positioned(
          top: spot.top.clamp(0, screen.height),
          left: 0,
          width: spot.left.clamp(0, screen.width),
          height: spot.height,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onWrongTap),
        ),
      if (spot.right < screen.width)
        Positioned(
          top: spot.top.clamp(0, screen.height),
          left: spot.right.clamp(0, screen.width),
          right: 0,
          height: spot.height,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onWrongTap),
        ),
    ];
  }
}

// ─── Spotlight painter ────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect? spotRect;
  final double glowValue;
  const _SpotlightPainter(this.spotRect, this.glowValue);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.72);
    if (spotRect != null) {
      final path = Path()
        ..addRect(fullRect)
        ..addRRect(
            RRect.fromRectAndRadius(spotRect!, const Radius.circular(16)));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, overlayPaint);
    } else {
      canvas.drawRect(fullRect, overlayPaint);
    }
    if (spotRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            spotRect!.inflate(1.5), const Radius.circular(17)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final expand = 3.0 + 6.0 * glowValue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            spotRect!.inflate(expand), const Radius.circular(22)),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.35 + 0.55 * glowValue)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotRect != spotRect || old.glowValue != glowValue;
}

// ─── Mission panel ────────────────────────────────────────────────────────────

class _MissionPanel extends StatelessWidget {
  final TourStep step;
  final String bodyText;
  final int stepIndex, totalSteps;
  final bool panelAtTop, wrongTap, stepJustCompleted, isCurrentStepCompleted,
      isLast;
  final double panelH;
  final EdgeInsets safePad;
  // Height of the Demo Banner (safePad.top + text + padding). 0 when not demo mode.
  final double demoBannerH;
  final AsyncCallback onNext, onPrev, onSkipAll;

  const _MissionPanel({
    required this.step,
    required this.bodyText,
    required this.stepIndex,
    required this.totalSteps,
    required this.panelAtTop,
    required this.panelH,
    required this.safePad,
    required this.demoBannerH,
    required this.wrongTap,
    required this.stepJustCompleted,
    required this.isCurrentStepCompleted,
    required this.isLast,
    required this.onNext,
    required this.onPrev,
    required this.onSkipAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg =
        isDark ? const Color(0xF2111111) : const Color(0xF8FFFFFF);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;
    final divColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final borderRadius = panelAtTop
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          );

    final panel = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: panelAtTop ? const Offset(0, 6) : const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        // In demo mode with panel at top, SafeArea top is skipped because the
        // panel is positioned below the banner (demoBannerH already clears status bar).
        top: panelAtTop && demoBannerH == 0,
        bottom: !panelAtTop,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: 步驟徽章 + 跳過導覽 ──────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stepIndex + 1} / $totalSteps',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onSkipAll,
                    child: Text(
                      AppLocalizations.of(context, 'tour_skip'),
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: divColor),
              const SizedBox(height: 10),

              // ── 標題 ─────────────────────────────────────
              Text(
                step.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),

              // ── 說明文字（可動態）──────────────────────────
              Text(
                bodyText,
                style: TextStyle(fontSize: 13, color: subColor, height: 1.5),
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: divColor),
              const SizedBox(height: 10),

              // ── Footer ────────────────────────────────────
              _buildFooter(context, subColor),
            ],
          ),
        ),
      ),
    );

    if (panelAtTop) {
      // When demo banner is active, start panel below the banner so it is not covered.
      final top = demoBannerH > 0 ? demoBannerH : 0.0;
      return Positioned(top: top, left: 0, right: 0, child: panel);
    } else {
      return Positioned(bottom: 0, left: 0, right: 0, child: panel);
    }
  }

  Widget _buildFooter(BuildContext context, Color subColor) {
    if (step.isActionRequired) {
      return _buildActionRequiredFooter(context, subColor);
    }
    return _buildInfoFooter(context, subColor);
  }

  Widget _buildActionRequiredFooter(BuildContext context, Color subColor) {
    // actionRequired: 左側空，右側顯示狀態
    Widget rightWidget;

    if (stepJustCompleted) {
      // 完成閃爍 ✓
      rightWidget = AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
        child: Text(AppLocalizations.of(context, 'tour_step_done')),
      );
    } else {
      // 等待完成：顯示 step-specific 操作提示
      final hintKey = step.actionHintLocKey ?? 'tour_action_hint_below';
      final hintText = wrongTap
          ? AppLocalizations.of(context, 'tour_wrong_tap')
          : AppLocalizations.of(context, hintKey);
      final hintColor = wrongTap ? Colors.orange : AppColors.gold;
      rightWidget = AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          color: hintColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        child: Text(hintText, textAlign: TextAlign.right),
      );
    }

    return Row(
      children: [
        // 上一步（若不是第一步）
        if (stepIndex > 0)
          _TextBtn(
            label: AppLocalizations.of(context, 'tour_prev'),
            color: subColor,
            onTap: onPrev,
          )
        else
          const SizedBox(width: 60),
        const Spacer(),
        rightWidget,
      ],
    );
  }

  Widget _buildInfoFooter(BuildContext context, Color subColor) {
    return Row(
      children: [
        // 上一步（info 步驟）
        if (!step.isFinish && stepIndex > 0)
          _TextBtn(
            label: AppLocalizations.of(context, 'tour_prev'),
            color: subColor,
            onTap: onPrev,
          )
        else
          const SizedBox(width: 60),
        const Spacer(),
        // 下一步 / 完成
        _FilledBtn(
          label: (isLast || step.isFinish)
              ? AppLocalizations.of(context, 'tour_done')
              : AppLocalizations.of(context, 'tour_next'),
          onTap: onNext,
        ),
      ],
    );
  }
}

// ─── Reusable button widgets ──────────────────────────────────────────────────

class _TextBtn extends StatelessWidget {
  final String label;
  final Color color;
  final AsyncCallback onTap;
  const _TextBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final AsyncCallback onTap;
  const _FilledBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      );
}
