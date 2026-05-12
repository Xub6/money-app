import 'package:flutter/widgets.dart';
import '../../config/localization.dart';
import 'tour_keys.dart';

enum TourActionType {
  infoOnly,         // 純說明，按「下一步」
  waitForTabChange, // 必須切換到 expectedTab 才進下一步
  waitForRouteOpen, // 必須打開 expectedRouteId 的頁面才進下一步
  finish,           // 最終完成步驟，顯示任務總結
}

class TourStep {
  final String id;
  final int tab;                  // 此步驟要在哪個 tab 顯示
  final GlobalKey? targetKey;    // spotlight 對準目標（null = 全螢幕遮罩）
  final TourActionType actionType;
  final int? expectedTab;        // waitForTabChange 完成條件
  final String? expectedRouteId; // waitForRouteOpen 完成條件
  final bool allowSkipStep;      // 是否顯示「略過此步」按鈕
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

  /// 需要使用者主動操作才能推進（tab 切換 or 頁面打開）
  bool get isInteractive =>
      actionType == TourActionType.waitForTabChange ||
      actionType == TourActionType.waitForRouteOpen;

  bool get isFinish => actionType == TourActionType.finish;
}

/// 建立主線任務步驟（Quick Start 13 步）
///
/// [hasAccounts]    用戶是否已有帳戶
/// [hasTransactions] 用戶是否已有支出/收入記錄
List<TourStep> buildMissionSteps(
  BuildContext context, {
  bool hasAccounts = false,
  bool hasTransactions = false,
}) {
  String t(String key) => AppLocalizations.of(context, key);

  return [
    // ── S0: 任務開始 ────────────────────────────────────── 0
    TourStep(
      id: 's0',
      tab: 0,
      targetKey: TourKeys.appBarTitle,
      allowSkipStep: false,
      title: t('tour_s0_title'),
      body: t('tour_s0_body'),
    ),

    // ── S1: 前往管理頁 ──────────────────────────────────── 1
    // 已有帳戶：改為「確認帳戶」措辭；無帳戶：「建立帳戶」措辭
    TourStep(
      id: 's1',
      tab: 0,
      targetKey: TourKeys.navManage,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 3,
      title: hasAccounts ? t('tour_s1_has_accounts_title') : t('tour_s1_title'),
      body: hasAccounts ? t('tour_s1_has_accounts_body') : t('tour_s1_body'),
    ),

    // ── S2: 進入帳戶頁 ──────────────────────────────────── 2
    // 已有帳戶：「查看設定」；無帳戶：「建立第一個帳戶」
    TourStep(
      id: 's2',
      tab: 3,
      targetKey: TourKeys.accountCard,
      actionType: TourActionType.waitForRouteOpen,
      expectedRouteId: 'accountPage',
      title: hasAccounts ? t('tour_s2_has_accounts_title') : t('tour_s2_title'),
      body: hasAccounts ? t('tour_s2_has_accounts_body') : t('tour_s2_body'),
    ),

    // ── S3: 回到記帳頁 ──────────────────────────────────── 3
    TourStep(
      id: 's3',
      tab: 3,
      targetKey: TourKeys.navDashboard,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 0,
      title: t('tour_s3_title'),
      body: t('tour_s3_body'),
    ),

    // ── S4: 每月收支總覽 ────────────────────────────────── 4
    TourStep(
      id: 's4',
      tab: 0,
      targetKey: TourKeys.monthCard,
      title: t('tour_s4_title'),
      body: t('tour_s4_body'),
    ),

    // ── S5: 月預算目標 ──────────────────────────────────── 5
    TourStep(
      id: 's5',
      tab: 0,
      targetKey: TourKeys.budgetCard,
      title: t('tour_s5_title'),
      body: t('tour_s5_body'),
    ),

    // ── S6: 支出類別分析 ────────────────────────────────── 6
    TourStep(
      id: 's6',
      tab: 0,
      targetKey: TourKeys.categoryCard,
      title: t('tour_s6_title'),
      body: t('tour_s6_body'),
    ),

    // ── S7: 記錄第一筆支出 ──────────────────────────────── 7
    // 無帳戶：顯示警告 + allowSkipStep=true（不能強迫卡死）
    // 有帳戶：正常引導點 FAB
    TourStep(
      id: 's7',
      tab: 0,
      targetKey: TourKeys.fab,
      actionType: TourActionType.waitForRouteOpen,
      expectedRouteId: 'addExpense',
      allowSkipStep: !hasAccounts,
      title: t('tour_s7_title'),
      body: hasAccounts ? t('tour_s7_body') : t('tour_s7_no_accounts_body'),
    ),

    // ── S8: 前往明細頁 ──────────────────────────────────── 8
    // 有交易：「看看剛才的記錄」；無交易：普通說明
    TourStep(
      id: 's8',
      tab: 0,
      targetKey: TourKeys.navDetail,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 1,
      title: t('tour_s8_title'),
      body: hasTransactions ? t('tour_s8_has_tx_body') : t('tour_s8_body'),
    ),

    // ── S9: 收支明細說明 ────────────────────────────────── 9
    // 有記錄：長按/左滑操作說明；無記錄：空狀態文案
    TourStep(
      id: 's9',
      tab: 1,
      targetKey: TourKeys.detailList,
      title: t('tour_s9_title'),
      body: hasTransactions ? t('tour_s9_has_tx_body') : t('tour_s9_body'),
    ),

    // ── S10: 前往管理頁看備份 ───────────────────────────── 10
    TourStep(
      id: 's10',
      tab: 1,
      targetKey: TourKeys.navManage,
      actionType: TourActionType.waitForTabChange,
      expectedTab: 3,
      title: t('tour_s10_title'),
      body: t('tour_s10_body'),
    ),

    // ── S11: 備份功能說明 ───────────────────────────────── 11
    // 有資料：強調備份重要；無資料：輕提示即可
    TourStep(
      id: 's11',
      tab: 3,
      targetKey: TourKeys.backupCard,
      allowSkipStep: false,
      title: t('tour_s11_title'),
      body: (hasAccounts || hasTransactions)
          ? t('tour_s11_has_data_body')
          : t('tour_s11_body'),
    ),

    // ── S12: 完成任務 ───────────────────────────────────── 12
    TourStep(
      id: 's12',
      tab: 3,
      targetKey: TourKeys.rewatchTile,
      actionType: TourActionType.finish,
      allowSkipStep: false,
      title: t('tour_s12_title'),
      body: t('tour_s12_body'),
    ),
  ];
}
