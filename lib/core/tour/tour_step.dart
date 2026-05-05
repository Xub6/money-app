import 'package:flutter/widgets.dart';
import '../../config/localization.dart';
import 'tour_keys.dart';

enum TooltipSide { above, below }

class TourStep {
  final GlobalKey targetKey;
  final int tab;
  final String title;
  final String body;
  final bool isInteractive;
  final String? hint;
  final TooltipSide side;

  const TourStep({
    required this.targetKey,
    required this.tab,
    required this.title,
    required this.body,
    this.isInteractive = false,
    this.hint,
    this.side = TooltipSide.below,
  });
}

/// The 16-step guided tour definition.
/// Index 4  = FAB tab-0 (interactive — add expense)
/// Index 6  = detailList (interactive — long press)
/// Index 9  = FAB tab-2 (interactive — add investment)
/// Index 14 = Feedback tile (interactive)
List<TourStep> buildTourSteps(BuildContext context) {
  String t(String key) => AppLocalizations.of(context, key);
  return [
    // ── Dashboard ────────────────────────────────────────────────── 0
    TourStep(targetKey: TourKeys.appBarTitle, tab: 0, side: TooltipSide.below,
      title: t('tour_s0_title'), body: t('tour_s0_body')),
    // 1
    TourStep(targetKey: TourKeys.monthCard, tab: 0, side: TooltipSide.below,
      title: t('tour_s1_title'), body: t('tour_s1_body')),
    // 2
    TourStep(targetKey: TourKeys.budgetCard, tab: 0, side: TooltipSide.below,
      title: t('tour_s2_title'), body: t('tour_s2_body')),
    // 3
    TourStep(targetKey: TourKeys.categoryCard, tab: 0, side: TooltipSide.above,
      title: t('tour_s3_title'), body: t('tour_s3_body')),
    // 4 ── FAB tab-0 interactive ───────────────────────────────────
    TourStep(targetKey: TourKeys.fab, tab: 0, isInteractive: true, side: TooltipSide.above,
      title: t('tour_s4_title'), body: t('tour_s4_body'), hint: t('tour_s4_hint')),
    // ── Detail ───────────────────────────────────────────────────── 5
    TourStep(targetKey: TourKeys.detailList, tab: 1, side: TooltipSide.below,
      title: t('tour_s5_title'), body: t('tour_s5_body')),
    // 6 ── detailList long-press interactive ──────────────────────
    TourStep(targetKey: TourKeys.detailList, tab: 1, isInteractive: true, side: TooltipSide.below,
      title: t('tour_s6_title'), body: t('tour_s6_body'), hint: t('tour_s6_hint')),
    // ── Invest ───────────────────────────────────────────────────── 7
    TourStep(targetKey: TourKeys.investHeader, tab: 2, side: TooltipSide.below,
      title: t('tour_s7_title'), body: t('tour_s7_body')),
    // 8
    TourStep(targetKey: TourKeys.investRefresh, tab: 2, side: TooltipSide.below,
      title: t('tour_s8_title'), body: t('tour_s8_body')),
    // 9 ── FAB tab-2 interactive ───────────────────────────────────
    TourStep(targetKey: TourKeys.fab, tab: 2, isInteractive: true, side: TooltipSide.above,
      title: t('tour_s9_title'), body: t('tour_s9_body'), hint: t('tour_s9_hint')),
    // ── Manage ──────────────────────────────────────────────────── 10
    TourStep(targetKey: TourKeys.navManage, tab: 3, side: TooltipSide.above,
      title: t('tour_s10_title'), body: t('tour_s10_body')),
    // 11
    TourStep(targetKey: TourKeys.accountCard, tab: 3, side: TooltipSide.below,
      title: t('tour_s11_title'), body: t('tour_s11_body')),
    // 12
    TourStep(targetKey: TourKeys.fixedCard, tab: 3, side: TooltipSide.below,
      title: t('tour_s12_title'), body: t('tour_s12_body')),
    // 13
    TourStep(targetKey: TourKeys.backupCard, tab: 3, side: TooltipSide.below,
      title: t('tour_s13_title'), body: t('tour_s13_body')),
    // 14 ── Feedback interactive ────────────────────────────────────
    TourStep(targetKey: TourKeys.feedbackTile, tab: 3, isInteractive: true, side: TooltipSide.above,
      title: t('tour_s14_title'), body: t('tour_s14_body'), hint: t('tour_s14_hint')),
    // 15 ── Finish ──────────────────────────────────────────────────
    TourStep(targetKey: TourKeys.rewatchTile, tab: 3, side: TooltipSide.above,
      title: t('tour_s15_title'), body: t('tour_s15_body')),
  ];
}
