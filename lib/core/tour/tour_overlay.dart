import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import 'tour_controller.dart';
import 'tour_step.dart';

/// Full-screen guided-tour overlay.  Inserted once into the Navigator's
/// Overlay so it sits above every route (FAB, BottomAppBar included).
class TourOverlay extends StatelessWidget {
  const TourOverlay({super.key});

  // Find the on-screen Rect of a GlobalKey's render object.
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
              // ── Visual dark overlay with spotlight hole ────────
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SpotlightPainter(spotRect),
                  ),
                ),
              ),

              // ── Hit-testing layer ──────────────────────────────
              if (ctrl.isWaitingForInteraction && spotRect != null)
                // Interactive: block dark areas, leave spotlight open
                ..._buildInteractiveBlockers(spotRect, screen)
              else
                // Non-interactive: block entire screen (tooltip card is on top)
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

  // Build 4 tap-absorbing rectangles around the spotlight so the spotlight
  // area remains tappable (interactive steps).
  static List<Widget> _buildInteractiveBlockers(Rect spot, Size screen) {
    const minH = 0.0;
    return [
      // Above
      if (spot.top > 0)
        Positioned(
          top: 0, left: 0, right: 0,
          height: spot.top.clamp(minH, screen.height),
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
      // Below
      if (spot.bottom < screen.height)
        Positioned(
          top: spot.bottom.clamp(0, screen.height),
          left: 0, right: 0, bottom: 0,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
      // Left of spotlight
      if (spot.left > 0)
        Positioned(
          top: spot.top.clamp(0, screen.height),
          left: 0,
          width: spot.left.clamp(0, screen.width),
          height: spot.height,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
      // Right of spotlight
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
  const _SpotlightPainter(this.spotRect);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(fullRect, Paint());

    // Dark overlay
    canvas.drawRect(
      fullRect,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );

    // Punch out the spotlight
    if (spotRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotRect!, const Radius.circular(16)),
        Paint()..blendMode = BlendMode.clear,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.spotRect != spotRect;
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
    const cardH = 240.0;
    const padding = 20.0;

    double cardTop;
    if (spotRect == null) {
      cardTop = screen.height / 2 - cardH / 2;
    } else {
      // Prefer below; fall back to above if not enough room
      final belowTop = spotRect!.bottom + 14;
      final aboveTop = spotRect!.top - cardH - 14;
      final showBelow = step.side == TooltipSide.below &&
          belowTop + cardH + 60 < screen.height;
      cardTop = showBelow ? belowTop : aboveTop;
    }
    cardTop = cardTop.clamp(padding, screen.height - cardH - padding);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Positioned(
      top: cardTop,
      left: padding,
      right: padding,
      child: Card(
        elevation: 12,
        shadowColor: Colors.black45,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header row: step badge + skip button ──────────
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Step ${stepIndex + 1} / $totalSteps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onSkip,
                  child: Text(
                    '跳過導覽',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 10),

              // ── Title ─────────────────────────────────────────
              Text(
                step.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 6),

              // ── Body ──────────────────────────────────────────
              Text(
                step.body,
                style: TextStyle(
                  fontSize: 13,
                  color: subColor,
                  height: 1.55,
                ),
              ),

              // ── Interactive hint ───────────────────────────────
              if (isWaiting && step.hint != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35)),
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

              const SizedBox(height: 14),

              // ── Navigation buttons ─────────────────────────────
              Row(children: [
                if (stepIndex > 0)
                  OutlinedButton(
                    onPressed: onPrev,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: subColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      '上一步',
                      style: TextStyle(color: subColor, fontSize: 13),
                    ),
                  ),
                const Spacer(),
                if (!isWaiting)
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 11),
                      elevation: 0,
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      isLast ? '完成 ✓' : '下一步',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
