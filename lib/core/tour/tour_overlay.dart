import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  static Rect? _findRect(GlobalKey key) {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) return null;
      final pos = box.localToGlobal(Offset.zero);
      return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TourController>(
      builder: (context, ctrl, _) {
        if (!ctrl.isActive || ctrl.isHidden) return const SizedBox.shrink();
        final step = ctrl.currentStep;
        if (step == null) return const SizedBox.shrink();

        final rawRect = _findRect(step.targetKey);
        final spotRect = rawRect?.inflate(10.0);
        final screen = MediaQuery.of(context).size;

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // ── Animated spotlight overlay ─────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _SpotlightPainter(spotRect, _glowAnim.value),
                    ),
                  ),
                ),
              ),

              // ── Hit-testing layer ──────────────────────────────
              if (ctrl.isWaitingForInteraction && spotRect != null)
                ..._buildInteractiveBlockers(spotRect, screen)
              else
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),

              // ── Tooltip card ───────────────────────────────────
              _TourTooltip(
                step: step,
                stepIndex: ctrl.stepIndex,
                totalSteps: ctrl.totalSteps,
                spotRect: spotRect,
                isWaiting: ctrl.isWaitingForInteraction,
                isLast: ctrl.isLastStep,
                onNext: ctrl.next,
                onPrev: ctrl.prev,
                onSkip: ctrl.skip,
              ),
            ],
          ),
        );
      },
    );
  }

  static List<Widget> _buildInteractiveBlockers(Rect spot, Size screen) {
    const minH = 0.0;
    return [
      if (spot.top > 0)
        Positioned(
          top: 0, left: 0, right: 0,
          height: spot.top.clamp(minH, screen.height),
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
      if (spot.bottom < screen.height)
        Positioned(
          top: spot.bottom.clamp(0, screen.height),
          left: 0, right: 0, bottom: 0,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
      if (spot.left > 0)
        Positioned(
          top: spot.top.clamp(0, screen.height),
          left: 0,
          width: spot.left.clamp(0, screen.width),
          height: spot.height,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
      if (spot.right < screen.width)
        Positioned(
          top: spot.top.clamp(0, screen.height),
          left: spot.right.clamp(0, screen.width),
          right: 0,
          height: spot.height,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
    ];
  }
}

// ─── Spotlight painter ────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect? spotRect;
  final double glowValue; // 0.0–1.0 from animation

  const _SpotlightPainter(this.spotRect, this.glowValue);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Dark overlay with spotlight hole
    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(
      fullRect,
      Paint()..color = Colors.black.withValues(alpha: 0.70),
    );
    if (spotRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotRect!, const Radius.circular(16)),
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();

    // Animated gold glow ring (drawn after restore so it's visible in hole)
    if (spotRect != null) {
      final expand = 2.0 + 5.0 * glowValue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotRect!.inflate(expand), const Radius.circular(20)),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.20 + 0.40 * glowValue)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotRect != spotRect || old.glowValue != glowValue;
}

// ─── Tooltip card ─────────────────────────────────────────────────────────────

class _TourTooltip extends StatelessWidget {
  final TourStep step;
  final int stepIndex, totalSteps;
  final Rect? spotRect;
  final bool isWaiting, isLast;
  final AsyncCallback onNext, onPrev, onSkip;

  const _TourTooltip({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.spotRect,
    required this.isWaiting,
    required this.isLast,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    const padding = 20.0;
    const cardMaxH = 280.0;

    double cardTop;
    if (spotRect == null) {
      cardTop = screen.height / 2 - cardMaxH / 2;
    } else {
      final belowTop = spotRect!.bottom + 14;
      final aboveTop = spotRect!.top - cardMaxH - 14;
      final showBelow = step.side == TooltipSide.below &&
          belowTop + cardMaxH + 60 < screen.height;
      cardTop = showBelow ? belowTop : aboveTop;
    }
    cardTop = cardTop.clamp(padding, screen.height - cardMaxH - padding);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Positioned(
      top: cardTop,
      left: padding,
      right: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.68)
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Skip button ────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        '跳過導覽',
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Title ─────────────────────────────────────
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Body ──────────────────────────────────────
                  Text(
                    step.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: subColor,
                      height: 1.55,
                    ),
                  ),

                  // ── Interactive hint (left gold stripe) ────────
                  if (isWaiting && step.hint != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: const Border(
                          left: BorderSide(color: AppColors.gold, width: 3),
                        ),
                      ),
                      child: Text(
                        step.hint!,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── Navigation row ────────────────────────────
                  Row(
                    children: [
                      // 上一步
                      if (stepIndex > 0)
                        _NavButton(
                          label: '上一步',
                          onTap: onPrev,
                          filled: false,
                          textColor: subColor,
                        )
                      else
                        const SizedBox(width: 72),

                      const Spacer(),

                      // Dot progress indicator
                      _DotProgress(
                          current: stepIndex, total: totalSteps),

                      const Spacer(),

                      // 下一步 / 完成
                      if (!isWaiting)
                        _NavButton(
                          label: isLast ? '完成 ✓' : '下一步',
                          onTap: onNext,
                          filled: true,
                          textColor: Colors.white,
                        )
                      else
                        const SizedBox(width: 72),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dot progress indicator ───────────────────────────────────────────────────

class _DotProgress extends StatelessWidget {
  final int current, total;
  const _DotProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: active ? 14.0 : 5.0,
          height: 5.0,
          decoration: BoxDecoration(
            color: active
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Navigation button ────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final AsyncCallback onTap;
  final bool filled;
  final Color textColor;

  const _NavButton({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: filled
              ? null
              : Border.all(
                  color: textColor.withValues(alpha: 0.4),
                  width: 1,
                ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
