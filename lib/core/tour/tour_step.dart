import 'package:flutter/widgets.dart';
import '../../config/localization.dart';
import 'tour_keys.dart';

enum OnboardingMode { quickStart, fullSetup, demo }

enum TourActionType {
  infoOnly,         // 純說明，按「下一步」
  waitForTabChange, // 必須切換到 expectedTab 才進下一步
  waitForRouteOpen, // 必須打開 expectedRouteId 的頁面才進下一步
  finish,           // 最終完成步驟
}

class TourStep {
  final String id;
  final int tab;
  final GlobalKey? targetKey;
  final TourActionType actionType;
  final int? expectedTab;
  final String? expectedRouteId;
  final bool allowSkipStep;
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

  bool get isInteractive =>
      actionType == TourActionType.waitForTabChange ||
      actionType == TourActionType.waitForRouteOpen;

  bool get isFinish => actionType == TourActionType.finish;
}

// ─── Quick Start: 7 steps (qs_s0 ~ qs_s6) ────────────────────────────────────
// 目標：建立帳戶 → 第一筆支出 → 回首頁看結果
List<TourStep> buildQuickStartSteps(
  BuildContext context, {
  bool hasAccounts = false,
  bool hasTransactions = false,
}) {
  String t(String key) => AppLocalizations.of(context, key);
  return [
    // qs_s0: 歡迎說明
    TourStep(
      id: 'qs_s0',
      tab: 0,
      targetKey: TourKeys.appBarTitle,
      allowSkipStep: false,
      title: t('tour_qs_s0_title'),
      body: t('tour_qs_s0_body'),
    ),
    // qs_s1: 前往管理頁 (waitForTabChange → 3)
    TourStep(
      id: 'qs_s1',
      tab: 0,
      targetKey: TourKeys.navManage,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 3,
      title: t('tour_qs_s1_title'),
      body: t('tour_qs_s1_body'),
    ),
    // qs_s2: 進入帳戶頁 (waitForRouteOpen → accountPage)
    TourStep(
      id: 'qs_s2',
      tab: 3,
      targetKey: TourKeys.accountCard,
      actionType: TourActionType.waitForRouteOpen,
      expectedRouteId: 'accountPage',
      title: hasAccounts ? t('tour_qs_s2_has_title') : t('tour_qs_s2_title'),
      body: hasAccounts ? t('tour_qs_s2_has_body') : t('tour_qs_s2_body'),
    ),
    // qs_s3: 回到記帳頁 (waitForTabChange → 0)
    TourStep(
      id: 'qs_s3',
      tab: 3,
      targetKey: TourKeys.navDashboard,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 0,
      title: t('tour_qs_s3_title'),
      body: t('tour_qs_s3_body'),
    ),
    // qs_s4: 點 FAB 新增支出 (waitForRouteOpen → addExpense)
    TourStep(
      id: 'qs_s4',
      tab: 0,
      targetKey: TourKeys.fab,
      actionType: TourActionType.waitForRouteOpen,
      expectedRouteId: 'addExpense',
      allowSkipStep: !hasAccounts,
      title: t('tour_qs_s4_title'),
      body: hasAccounts ? t('tour_qs_s4_body') : t('tour_qs_s4_no_account_body'),
    ),
    // qs_s5: 查看月收支同步
    TourStep(
      id: 'qs_s5',
      tab: 0,
      targetKey: TourKeys.monthCard,
      title: t('tour_qs_s5_title'),
      body: t('tour_qs_s5_body'),
    ),
    // qs_s6: 完成
    TourStep(
      id: 'qs_s6',
      tab: 0,
      actionType: TourActionType.finish,
      allowSkipStep: false,
      title: t('tour_qs_s6_title'),
      body: t('tour_qs_s6_body'),
    ),
  ];
}

// ─── Full Setup: 11 steps (fs_s0 ~ fs_s10) ───────────────────────────────────
// 目標：帳戶 + 支出 + 預算 + 明細 + 備份
List<TourStep> buildFullSetupSteps(
  BuildContext context, {
  bool hasAccounts = false,
  bool hasTransactions = false,
}) {
  String t(String key) => AppLocalizations.of(context, key);
  final hasData = hasAccounts || hasTransactions;
  return [
    // fs_s0: 歡迎
    TourStep(
      id: 'fs_s0',
      tab: 0,
      targetKey: TourKeys.appBarTitle,
      allowSkipStep: false,
      title: t('tour_fs_s0_title'),
      body: t('tour_fs_s0_body'),
    ),
    // fs_s1: 前往管理頁 (waitForTabChange → 3)
    TourStep(
      id: 'fs_s1',
      tab: 0,
      targetKey: TourKeys.navManage,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 3,
      title: t('tour_fs_s1_title'),
      body: t('tour_fs_s1_body'),
    ),
    // fs_s2: 進入帳戶頁 (waitForRouteOpen → accountPage)
    TourStep(
      id: 'fs_s2',
      tab: 3,
      targetKey: TourKeys.accountCard,
      actionType: TourActionType.waitForRouteOpen,
      expectedRouteId: 'accountPage',
      title: hasAccounts ? t('tour_fs_s2_has_title') : t('tour_fs_s2_title'),
      body: hasAccounts ? t('tour_fs_s2_has_body') : t('tour_fs_s2_body'),
    ),
    // fs_s3: 回到記帳頁 (waitForTabChange → 0)
    TourStep(
      id: 'fs_s3',
      tab: 3,
      targetKey: TourKeys.navDashboard,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 0,
      title: t('tour_fs_s3_title'),
      body: t('tour_fs_s3_body'),
    ),
    // fs_s4: 點 FAB 記支出 (waitForRouteOpen → addExpense)
    TourStep(
      id: 'fs_s4',
      tab: 0,
      targetKey: TourKeys.fab,
      actionType: TourActionType.waitForRouteOpen,
      expectedRouteId: 'addExpense',
      allowSkipStep: !hasAccounts,
      title: t('tour_fs_s4_title'),
      body: hasAccounts ? t('tour_fs_s4_body') : t('tour_fs_s4_no_account_body'),
    ),
    // fs_s5: 每月收支總覽
    TourStep(
      id: 'fs_s5',
      tab: 0,
      targetKey: TourKeys.monthCard,
      title: t('tour_fs_s5_title'),
      body: t('tour_fs_s5_body'),
    ),
    // fs_s6: 月預算目標
    TourStep(
      id: 'fs_s6',
      tab: 0,
      targetKey: TourKeys.budgetCard,
      title: t('tour_fs_s6_title'),
      body: t('tour_fs_s6_body'),
    ),
    // fs_s7: 前往明細頁 (waitForTabChange → 1)
    TourStep(
      id: 'fs_s7',
      tab: 0,
      targetKey: TourKeys.navDetail,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 1,
      title: t('tour_fs_s7_title'),
      body: hasTransactions ? t('tour_fs_s7_has_tx_body') : t('tour_fs_s7_body'),
    ),
    // fs_s8: 前往管理頁 (waitForTabChange → 3)
    TourStep(
      id: 'fs_s8',
      tab: 1,
      targetKey: TourKeys.navManage,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 3,
      title: t('tour_fs_s8_title'),
      body: t('tour_fs_s8_body'),
    ),
    // fs_s9: 備份說明
    TourStep(
      id: 'fs_s9',
      tab: 3,
      targetKey: TourKeys.backupCard,
      allowSkipStep: false,
      title: t('tour_fs_s9_title'),
      body: hasData ? t('tour_fs_s9_has_data_body') : t('tour_fs_s9_body'),
    ),
    // fs_s10: 完成
    TourStep(
      id: 'fs_s10',
      tab: 3,
      targetKey: TourKeys.rewatchTile,
      actionType: TourActionType.finish,
      allowSkipStep: false,
      title: t('tour_fs_s10_title'),
      body: t('tour_fs_s10_body'),
    ),
  ];
}

// ─── Demo: 5 steps (demo_s0 ~ demo_s4) ───────────────────────────────────────
// 全程 infoOnly，示範資料由 AppState.loadDemoData() 注入
List<TourStep> buildDemoSteps(BuildContext context) {
  String t(String key) => AppLocalizations.of(context, key);
  return [
    // demo_s0: 示範說明
    TourStep(
      id: 'demo_s0',
      tab: 0,
      targetKey: TourKeys.appBarTitle,
      allowSkipStep: false,
      title: t('tour_demo_s0_title'),
      body: t('tour_demo_s0_body'),
    ),
    // demo_s1: 月收支總覽
    TourStep(
      id: 'demo_s1',
      tab: 0,
      targetKey: TourKeys.monthCard,
      title: t('tour_demo_s1_title'),
      body: t('tour_demo_s1_body'),
    ),
    // demo_s2: 類別分析
    TourStep(
      id: 'demo_s2',
      tab: 0,
      targetKey: TourKeys.categoryCard,
      title: t('tour_demo_s2_title'),
      body: t('tour_demo_s2_body'),
    ),
    // demo_s3: 前往明細頁 (waitForTabChange → 1)
    TourStep(
      id: 'demo_s3',
      tab: 0,
      targetKey: TourKeys.navDetail,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 1,
      title: t('tour_demo_s3_title'),
      body: t('tour_demo_s3_body'),
    ),
    // demo_s4: 完成
    TourStep(
      id: 'demo_s4',
      tab: 1,
      actionType: TourActionType.finish,
      allowSkipStep: false,
      title: t('tour_demo_s4_title'),
      body: t('tour_demo_s4_body'),
    ),
  ];
}
