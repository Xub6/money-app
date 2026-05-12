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

/// 13-step guided tour — follows the logical first-time setup order:
/// Accounts → Dashboard → Budget → Add Expense → Detail → Investments → Backup
///
/// Interactive steps:
///   S6  = FAB tab-0 (add expense)
///   S8  = detailList long-press
///   S10 = FAB tab-2 (add holding)
List<TourStep> buildTourSteps(BuildContext context) {
  String t(String key) => AppLocalizations.of(context, key);
  return [
    // S0 ── Welcome ───────────────────────────────────────────────
    TourStep(targetKey: TourKeys.appBarTitle, tab: 0, side: TooltipSide.below,
      title: t('tour_s0_title'), body: t('tour_s0_body')),

    // S1 ── Go to Manage tab first ─────────────────────────────── 1
    TourStep(targetKey: TourKeys.navManage, tab: 3, side: TooltipSide.above,
      title: t('tour_s1_title'), body: t('tour_s1_body')),

    // S2 ── Accounts (foundation of all tracking) ─────────────── 2
    TourStep(targetKey: TourKeys.accountCard, tab: 3, side: TooltipSide.below,
      title: t('tour_s2_title'), body: t('tour_s2_body')),

    // S3 ── Dashboard: monthly overview ───────────────────────── 3
    TourStep(targetKey: TourKeys.monthCard, tab: 0, side: TooltipSide.below,
      title: t('tour_s3_title'), body: t('tour_s3_body')),

    // S4 ── Budget progress ────────────────────────────────────── 4
    TourStep(targetKey: TourKeys.budgetCard, tab: 0, side: TooltipSide.below,
      title: t('tour_s4_title'), body: t('tour_s4_body')),

    // S5 ── Category analysis ─────────────────────────────────── 5
    TourStep(targetKey: TourKeys.categoryCard, tab: 0, side: TooltipSide.above,
      title: t('tour_s5_title'), body: t('tour_s5_body')),

    // S6 ── FAB tab-0 (add expense) ───────────────────────────── 6
    TourStep(targetKey: TourKeys.fab, tab: 0, side: TooltipSide.above,
      title: t('tour_s6_title'), body: t('tour_s6_body')),

    // S7 ── Detail list ────────────────────────────────────────── 7
    TourStep(targetKey: TourKeys.detailList, tab: 1, side: TooltipSide.below,
      title: t('tour_s7_title'), body: t('tour_s7_body')),

    // S8 ── detailList long-press ─────────────────────────────── 8
    TourStep(targetKey: TourKeys.detailList, tab: 1, side: TooltipSide.below,
      title: t('tour_s8_title'), body: t('tour_s8_body')),

    // S9 ── Invest tab overview ───────────────────────────────── 9
    TourStep(targetKey: TourKeys.investHeader, tab: 2, side: TooltipSide.below,
      title: t('tour_s9_title'), body: t('tour_s9_body')),

    // S10 ── FAB tab-2 (add holding) ──────────────────────────── 10
    TourStep(targetKey: TourKeys.fab, tab: 2, side: TooltipSide.above,
      title: t('tour_s10_title'), body: t('tour_s10_body')),

    // S11 ── Backup ───────────────────────────────────────────── 11
    TourStep(targetKey: TourKeys.backupCard, tab: 3, side: TooltipSide.below,
      title: t('tour_s11_title'), body: t('tour_s11_body')),

    // S12 ── Done / rewatch ───────────────────────────────────── 12
    TourStep(targetKey: TourKeys.rewatchTile, tab: 3, side: TooltipSide.above,
      title: t('tour_s12_title'), body: t('tour_s12_body')),
  ];
}
