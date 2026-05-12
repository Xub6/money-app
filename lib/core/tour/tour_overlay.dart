import 'dart:ui';
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

        // Use the pre-calculated rect from the controller.
        // This was computed AFTER scroll + endOfFrame, so it is always the
        // stable on-screen position — never a stale off-tab coordinate.
        final rawRect = ctrl.cachedTargetRect;
        final screen = MediaQuery.of(context).size;
        final safePad = MediaQuery.of(context).padding;

        // When a widget spans more than 40 % of the screen height (e.g. an
        // Expanded list or a tall card with many buttons), showing it as a
        // full spotlight leaves almost no dark overlay and forces the tooltip
        // into a centered fallback that overlaps the target.  Clip to the top
        // 80 dp so the spotlight is a meaningful focal point and the tooltip
        // has room to sit naturally below it.
        Rect? effectiveRect = rawRect;
        if (rawRect != null && rawRect.height > screen.height * 0.4) {
          effectiveRect = Rect.fromLTWH(
              rawRect.left, rawRect.top, rawRect.width, 80.0);
        }

        // Clamp spotlight rect to screen bounds so the hole never escapes.
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

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // ── Animated spotlight overlay ─────────────────────
              // RepaintBoundary isolates 60 fps animation repaints.
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
                screen: screen,
                safePad: safePad,
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

    // Dark overlay with spotlight hole.
    // Path.evenOdd avoids canvas.saveLayer — no offscreen GPU buffer needed.
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.70);
    if (spotRect != null) {
      final path = Path()
        ..addRect(fullRect)
        ..addRRect(RRect.fromRectAndRadius(spotRect!, const Radius.circular(16)));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, overlayPaint);
    } else {
      canvas.drawRect(fullRect, overlayPaint);
    }

    // Solid white border at the spotlight edge — makes the cutout clearly visible.
    if (spotRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotRect!.inflate(1.5), const Radius.circular(17)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Animated gold glow ring — sigma 8 for clear visibility on real devices.
    if (spotRect != null) {
      final expand = 3.0 + 6.0 * glowValue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotRect!.inflate(expand), const Radius.circular(22)),
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

// ─── Tooltip card ─────────────────────────────────────────────────────────────

class _TourTooltip extends StatelessWidget {
  final TourStep step;
  final int stepIndex, totalSteps;
  final Rect? spotRect;
  final Size screen;
  final EdgeInsets safePad;
  final bool isWaiting, isLast;
  final AsyncCallback onNext, onPrev, onSkip;

  const _TourTooltip({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.spotRect,
    required this.screen,
    required this.safePad,
    required this.isWaiting,
    required this.isLast,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    const hPad = 12.0; // horizontal margin from screen edge
    const gap = 14.0;  // gap between spotlight and tooltip
    const cardMaxH = 300.0;
    final minTop = safePad.top + hPad;
    final maxTop = screen.height - cardMaxH - hPad;

    double cardTop;
    if (spotRect == null) {
      // No target visible — center tooltip on screen.
      cardTop = (screen.height - cardMaxH) / 2;
    } else {
      final belowTop = spotRect!.bottom + gap;
      final aboveTop = spotRect!.top - cardMaxH - gap;
      // Prefer the side indicated by the step; fall back to opposite if no room.
      final preferBelow = step.side == TooltipSide.below;
      final roomBelow = belowTop + cardMaxH + hPad < screen.height;
      final roomAbove = aboveTop > minTop;

      if (preferBelow && roomBelow) {
        cardTop = belowTop;
      } else if (!preferBelow && roomAbove) {
        cardTop = aboveTop;
      } else if (roomBelow) {
        cardTop = belowTop;
      } else if (roomAbove) {
        cardTop = aboveTop;
      } else {
        // Neither side has room — center tooltip.
        cardTop = (screen.height - cardMaxH) / 2;
      }
    }

    // Final clamp: tooltip must stay within safe area vertically.
    cardTop = cardTop.clamp(minTop, maxTop.toDouble());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Positioned(
      top: cardTop,
      left: hPad,
      right: hPad,
      // Solid card replaces BackdropFilter — eliminates GPU framebuffer readback.
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xEE111111) : const Color(0xF8FFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
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
                    AppLocalizations.of(context, 'tour_skip'),
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
                  if (stepIndex > 0)
                    _NavButton(
                      label: AppLocalizations.of(context, 'tour_prev'),
                      onTap: onPrev,
                      filled: false,
                      textColor: subColor,
                    )
                  else
                    const SizedBox(width: 72),

                  const Spacer(),

                  _DotProgress(current: stepIndex, total: totalSteps),

                  const Spacer(),

                  if (!isWaiting)
                    _NavButton(
                      label: isLast
                          ? AppLocalizations.of(context, 'tour_done')
                          : AppLocalizations.of(context, 'tour_next'),
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
