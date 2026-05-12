import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
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

        final rawRect = ctrl.cachedTargetRect;
        final screen = MediaQuery.of(context).size;
        final safePad = MediaQuery.of(context).padding;

        // 超長列表限制高度到 250dp；正常卡片不截斷
        Rect? effectiveRect = rawRect;
        if (rawRect != null && rawRect.height > screen.height * 0.65) {
          effectiveRect =
              Rect.fromLTWH(rawRect.left, rawRect.top, rawRect.width, 250.0);
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

        // spotlight 在螢幕下方 60% 時，panel 移到頂部
        const panelH = 210.0;
        final panelAtTop = spotRect != null &&
            spotRect.center.dy > screen.height * 0.60;

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // ── 遮罩 + spotlight 切口 ────────────────────────
              Positioned.fill(
                child: RepaintBoundary(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => CustomPaint(
                        painter: _SpotlightPainter(spotRect, _glowAnim.value),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 互動阻擋層 ───────────────────────────────────
              if (step.isInteractive && spotRect != null)
                ..._buildInteractiveBlockers(spotRect, screen, ctrl)
              else
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),

              // ── 任務面板 ─────────────────────────────────────
              _MissionPanel(
                step: step,
                stepIndex: ctrl.stepIndex,
                totalSteps: ctrl.totalSteps,
                panelAtTop: panelAtTop,
                panelH: panelH,
                safePad: safePad,
                wrongTap: ctrl.showWrongTapHint,
                stepJustCompleted: ctrl.stepJustCompleted,
                isLast: ctrl.isLastStep,
                onNext: ctrl.next,
                onPrev: ctrl.prev,
                onSkipStep: ctrl.skipStep,
                onSkipAll: ctrl.skip,
              ),
            ],
          ),
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
            behavior: HitTestBehavior.opaque,
            onTap: onWrongTap,
          ),
        ),
      if (spot.bottom < screen.height)
        Positioned(
          top: spot.bottom.clamp(0, screen.height),
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onWrongTap,
          ),
        ),
      if (spot.left > 0)
        Positioned(
          top: spot.top.clamp(0, screen.height),
          left: 0,
          width: spot.left.clamp(0, screen.width),
          height: spot.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onWrongTap,
          ),
        ),
      if (spot.right < screen.width)
        Positioned(
          top: spot.top.clamp(0, screen.height),
          left: spot.right.clamp(0, screen.width),
          right: 0,
          height: spot.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onWrongTap,
          ),
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
      // 白色實線框
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            spotRect!.inflate(1.5), const Radius.circular(17)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // 金色脈動光暈
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
  final int stepIndex, totalSteps;
  final bool panelAtTop, wrongTap, stepJustCompleted, isLast;
  final double panelH;
  final EdgeInsets safePad;
  final AsyncCallback onNext, onPrev, onSkipStep, onSkipAll;

  const _MissionPanel({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.panelAtTop,
    required this.panelH,
    required this.safePad,
    required this.wrongTap,
    required this.stepJustCompleted,
    required this.isLast,
    required this.onNext,
    required this.onPrev,
    required this.onSkipStep,
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

    // 方向提示文字
    final hintKey =
        panelAtTop ? 'tour_action_hint_below' : 'tour_action_hint_above';
    final hintText = AppLocalizations.of(
        context, wrongTap ? 'tour_wrong_tap' : hintKey);
    final hintColor = wrongTap ? Colors.orange : AppColors.gold;

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
        top: panelAtTop,
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

              // ── 說明文字 ──────────────────────────────────
              Text(
                step.body,
                style: TextStyle(fontSize: 13, color: subColor, height: 1.5),
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: divColor),
              const SizedBox(height: 10),

              // ── Footer ────────────────────────────────────
              Row(
                children: [
                  // 左側：略過此步 / 上一步
                  if (step.allowSkipStep && step.isInteractive)
                    _TextBtn(
                      label: AppLocalizations.of(
                          context, 'tour_skip_step'),
                      color: subColor,
                      onTap: onSkipStep,
                    )
                  else if (!step.isInteractive && stepIndex > 0)
                    _TextBtn(
                      label:
                          AppLocalizations.of(context, 'tour_prev'),
                      color: subColor,
                      onTap: onPrev,
                    )
                  else
                    const SizedBox(width: 60),

                  const Spacer(),

                  // 右側：互動提示 / ✓完成閃爍 / 下一步按鈕
                  if (stepJustCompleted && step.isInteractive)
                    // 互動步驟剛完成：閃爍 ✓ 回饋
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      child: Text(AppLocalizations.of(
                          context, 'tour_step_done')),
                    )
                  else if (step.isInteractive)
                    // 等待互動：顯示方向提示
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      child: Text(hintText),
                    )
                  else
                    // 純說明步驟或 finish 步驟：顯示按鈕
                    _FilledBtn(
                      label: (isLast || step.isFinish)
                          ? AppLocalizations.of(
                              context, 'tour_done')
                          : AppLocalizations.of(
                              context, 'tour_next'),
                      onTap: onNext,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (panelAtTop) {
      return Positioned(top: 0, left: 0, right: 0, child: panel);
    } else {
      return Positioned(bottom: 0, left: 0, right: 0, child: panel);
    }
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
