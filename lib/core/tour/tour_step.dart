import 'package:flutter/widgets.dart';
import '../../config/localization.dart';
import 'tour_keys.dart';

enum TourActionType {
  infoOnly,         // 純說明，使用者按「下一步」
  waitForTabChange, // 使用者必須點 nav 切換到 expectedTab
  waitForRouteOpen, // 使用者必須點 target 打開指定 route（expectedRouteId）
}

class TourStep {
  final String id;
  final int tab;                 // 顯示此步驟時要在哪個 tab
  final GlobalKey? targetKey;   // spotlight 對準的 widget（null = 全螢幕暗色）
  final TourActionType actionType;
  final int? expectedTab;       // waitForTabChange 完成條件
  final String? expectedRouteId; // waitForRouteOpen 完成條件
  final bool allowSkipStep;     // 是否顯示「略過此步」按鈕
  final String title;
  final String body;

  const TourStep({
    required this.id,
    required this.tab,
    this.targetKey,
    this.actionType = TourActionType.infoOnly,
    this.expectedTab,
    this.expectedRouteId,
    this.allowSkipStep = true,
    required this.title,
    required this.body,
  });

  bool get isInteractive => actionType != TourActionType.infoOnly;
}

List<TourStep> buildTourSteps(BuildContext context) {
  String t(String key) => AppLocalizations.of(context, key);
  return [
    // S0 ── Welcome ──────────────────────────────────── 0
    TourStep(
      id: 's0', tab: 0, targetKey: TourKeys.appBarTitle,
      allowSkipStep: false,
      title: t('tour_s0_title'), body: t('tour_s0_body'),
    ),
    // S1 ── Navigate to Manage tab ───────────────────── 1
    TourStep(
      id: 's1', tab: 0, targetKey: TourKeys.navManage,
      actionType: TourActionType.waitForTabChange, expectedTab: 3,
      title: t('tour_s1_title'), body: t('tour_s1_body'),
    ),
    // S2 ── Tap account card ──────────────────────────── 2
    TourStep(
      id: 's2', tab: 3, targetKey: TourKeys.accountCard,
      actionType: TourActionType.waitForRouteOpen, expectedRouteId: 'accountPage',
      title: t('tour_s2_title'), body: t('tour_s2_body'),
    ),
    // S3 ── Account info (returns from AccountPage) ───── 3
    TourStep(
      id: 's3', tab: 3, targetKey: TourKeys.accountCard,
      title: t('tour_s3_title'), body: t('tour_s3_body'),
    ),
    // S4 ── Navigate to Dashboard ────────────────────── 4
    TourStep(
      id: 's4', tab: 3, targetKey: TourKeys.navDashboard,
      actionType: TourActionType.waitForTabChange, expectedTab: 0,
      title: t('tour_s4_title'), body: t('tour_s4_body'),
    ),
    // S5 ── Monthly overview ─────────────────────────── 5
    TourStep(
      id: 's5', tab: 0, targetKey: TourKeys.monthCard,
      title: t('tour_s5_title'), body: t('tour_s5_body'),
    ),
    // S6 ── Budget card ──────────────────────────────── 6
    TourStep(
      id: 's6', tab: 0, targetKey: TourKeys.budgetCard,
      title: t('tour_s6_title'), body: t('tour_s6_body'),
    ),
    // S7 ── Category chart ───────────────────────────── 7
    TourStep(
      id: 's7', tab: 0, targetKey: TourKeys.categoryCard,
      title: t('tour_s7_title'), body: t('tour_s7_body'),
    ),
    // S8 ── Tap FAB to add expense ───────────────────── 8
    TourStep(
      id: 's8', tab: 0, targetKey: TourKeys.fab,
      actionType: TourActionType.waitForRouteOpen, expectedRouteId: 'addExpense',
      title: t('tour_s8_title'), body: t('tour_s8_body'),
    ),
    // S9 ── Navigate to Detail tab ───────────────────── 9
    TourStep(
      id: 's9', tab: 0, targetKey: TourKeys.navDetail,
      actionType: TourActionType.waitForTabChange, expectedTab: 1,
      title: t('tour_s9_title'), body: t('tour_s9_body'),
    ),
    // S10 ── Detail list info ────────────────────────── 10
    TourStep(
      id: 's10', tab: 1, targetKey: TourKeys.detailList,
      title: t('tour_s10_title'), body: t('tour_s10_body'),
    ),
    // S11 ── Navigate to Invest tab ──────────────────── 11
    TourStep(
      id: 's11', tab: 1, targetKey: TourKeys.navInvest,
      actionType: TourActionType.waitForTabChange, expectedTab: 2,
      title: t('tour_s11_title'), body: t('tour_s11_body'),
    ),
    // S12 ── Tap FAB to add holding ──────────────────── 12
    TourStep(
      id: 's12', tab: 2, targetKey: TourKeys.fab,
      actionType: TourActionType.waitForRouteOpen, expectedRouteId: 'addHolding',
      title: t('tour_s12_title'), body: t('tour_s12_body'),
    ),
    // S13 ── Navigate back to Manage ─────────────────── 13
    TourStep(
      id: 's13', tab: 2, targetKey: TourKeys.navManage,
      actionType: TourActionType.waitForTabChange, expectedTab: 3,
      title: t('tour_s13_title'), body: t('tour_s13_body'),
    ),
    // S14 ── Backup info ─────────────────────────────── 14
    TourStep(
      id: 's14', tab: 3, targetKey: TourKeys.backupCard,
      allowSkipStep: false,
      title: t('tour_s14_title'), body: t('tour_s14_body'),
    ),
    // S15 ── Done ────────────────────────────────────── 15
    TourStep(
      id: 's15', tab: 3, targetKey: TourKeys.rewatchTile,
      allowSkipStep: false,
      title: t('tour_s15_title'), body: t('tour_s15_body'),
    ),
  ];
}
