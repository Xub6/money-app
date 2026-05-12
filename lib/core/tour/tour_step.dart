import 'package:flutter/widgets.dart';
import '../../config/localization.dart';
import '../../data/repositories/app_state.dart';
import 'tour_keys.dart';
import 'tour_session.dart';

enum OnboardingMode { quickStart, fullSetup, demo }

enum TourStepType {
  info,           // 純說明，可按「下一步」
  actionRequired, // 必須滿足 completionPredicate 才進下一步，Next 按鈕禁用
  finish,         // 最終完成步驟
}

typedef StepPredicate = bool Function(
    AppState appState, TourSession session, int currentTab);
typedef DynamicBodyBuilder = String Function(
    AppState appState, TourSession session, BuildContext context);

class TourStep {
  final String id;
  final int tab;
  final GlobalKey? targetKey;
  final TourStepType type;
  final StepPredicate? completionPredicate;
  final String? actionHintLocKey;
  final DynamicBodyBuilder? dynamicBody;
  final String title;
  final String body;

  TourStep({
    required this.id,
    required this.tab,
    this.targetKey,
    this.type = TourStepType.info,
    this.completionPredicate,
    this.actionHintLocKey,
    this.dynamicBody,
    required this.title,
    required this.body,
  });

  bool get isActionRequired => type == TourStepType.actionRequired;
  bool get isFinish => type == TourStepType.finish;
  bool get isInfo => type == TourStepType.info;
}

// ─── Shared predicate helpers ─────────────────────────────────────────────────

int _realAccountCount(AppState a) =>
    a.accounts.where((ac) => !ac.id.startsWith('tour_demo_')).length;

bool _hasNewRealExpense(AppState a, TourSession s) => a.expenses.any((e) =>
    !e.id.startsWith('tour_demo_') && e.createdAt.isAfter(s.createdAt));

// ─── Quick Start: 7 steps (qs_s0 ~ qs_s6) ────────────────────────────────────
// 目標：建立帳戶 → 第一筆支出 → 查看同步結果
List<TourStep> buildQuickStartSteps(BuildContext context) {
  String t(String key) => AppLocalizations.of(context, key);

  return [
    // qs_s0: 歡迎說明（info）
    TourStep(
      id: 'qs_s0',
      tab: 0,
      targetKey: TourKeys.appBarTitle,
      title: t('tour_qs_s0_title'),
      body: t('tour_qs_s0_body'),
    ),

    // qs_s1: 前往管理頁（必須切到 tab 3）
    TourStep(
      id: 'qs_s1',
      tab: 0,
      targetKey: TourKeys.navManage,
      type: TourStepType.actionRequired,
      completionPredicate: (_, __, tab) => tab == 3,
      actionHintLocKey: 'tour_qs_s1_action_hint',
      title: t('tour_qs_s1_title'),
      body: t('tour_qs_s1_body'),
    ),

    // qs_s2: 建立帳戶（進入帳戶頁並實際新增帳戶）
    TourStep(
      id: 'qs_s2',
      tab: 3,
      targetKey: TourKeys.accountCard,
      type: TourStepType.actionRequired,
      completionPredicate: (appState, session, _) =>
          _realAccountCount(appState) > session.startAccountCount,
      actionHintLocKey: 'tour_qs_s2_action_hint',
      title: t('tour_qs_s2_title'),
      body: t('tour_qs_s2_body'),
    ),

    // qs_s3: 回到記帳頁（tab 0）且確認帳戶已存在
    TourStep(
      id: 'qs_s3',
      tab: 3,
      targetKey: TourKeys.navDashboard,
      type: TourStepType.actionRequired,
      completionPredicate: (appState, session, tab) =>
          tab == 0 && _realAccountCount(appState) > session.startAccountCount,
      actionHintLocKey: 'tour_qs_s3_action_hint',
      title: t('tour_qs_s3_title'),
      body: t('tour_qs_s3_body'),
    ),

    // qs_s4: 記錄第一筆支出（實際存入）
    TourStep(
      id: 'qs_s4',
      tab: 0,
      targetKey: TourKeys.fab,
      type: TourStepType.actionRequired,
      completionPredicate: (appState, session, _) =>
          _hasNewRealExpense(appState, session),
      actionHintLocKey: 'tour_qs_s4_action_hint',
      title: t('tour_qs_s4_title'),
      body: t('tour_qs_s4_body'),
    ),

    // qs_s5: 查看同步結果（info，動態內文根據支出是否關聯帳戶）
    TourStep(
      id: 'qs_s5',
      tab: 0,
      targetKey: TourKeys.monthCard,
      title: t('tour_qs_s5_title'),
      body: t('tour_qs_s5_body'),
      dynamicBody: (appState, session, ctx) {
        final latest = appState.expenses
            .where((e) =>
                !e.id.startsWith('tour_demo_') &&
                e.createdAt.isAfter(session.createdAt))
            .firstOrNull;
        if (latest == null) return AppLocalizations.of(ctx, 'tour_qs_s5_body');
        final key = latest.accountId != null
            ? 'tour_qs_s5_body_linked'
            : 'tour_qs_s5_body_unlinked';
        return AppLocalizations.ofParam(
            ctx, key, {'amount': latest.amount.toString()});
      },
    ),

    // qs_s6: 完成
    TourStep(
      id: 'qs_s6',
      tab: 0,
      type: TourStepType.finish,
      title: t('tour_qs_s6_title'),
      body: t('tour_qs_s6_body'),
    ),
  ];
}

// ─── Full Setup: 11 steps (fs_s0 ~ fs_s10) ───────────────────────────────────
// 目標：帳戶 + 支出 + 預算 + 明細 + 備份
List<TourStep> buildFullSetupSteps(BuildContext context) {
  String t(String key) => AppLocalizations.of(context, key);

  return [
    // fs_s0: 歡迎（info）
    TourStep(
      id: 'fs_s0',
      tab: 0,
      targetKey: TourKeys.appBarTitle,
      title: t('tour_fs_s0_title'),
      body: t('tour_fs_s0_body'),
    ),

    // fs_s1: 前往管理頁
    TourStep(
      id: 'fs_s1',
      tab: 0,
      targetKey: TourKeys.navManage,
      type: TourStepType.actionRequired,
      completionPredicate: (_, __, tab) => tab == 3,
      actionHintLocKey: 'tour_fs_s1_action_hint',
      title: t('tour_fs_s1_title'),
      body: t('tour_fs_s1_body'),
    ),

    // fs_s2: 建立帳戶
    TourStep(
      id: 'fs_s2',
      tab: 3,
      targetKey: TourKeys.accountCard,
      type: TourStepType.actionRequired,
      completionPredicate: (appState, session, _) =>
          _realAccountCount(appState) > session.startAccountCount,
      actionHintLocKey: 'tour_fs_s2_action_hint',
      title: t('tour_fs_s2_title'),
      body: t('tour_fs_s2_body'),
    ),

    // fs_s3: 回到記帳頁
    TourStep(
      id: 'fs_s3',
      tab: 3,
      targetKey: TourKeys.navDashboard,
      type: TourStepType.actionRequired,
      completionPredicate: (appState, session, tab) =>
          tab == 0 && _realAccountCount(appState) > session.startAccountCount,
      actionHintLocKey: 'tour_fs_s3_action_hint',
      title: t('tour_fs_s3_title'),
      body: t('tour_fs_s3_body'),
    ),

    // fs_s4: 記錄第一筆支出
    TourStep(
      id: 'fs_s4',
      tab: 0,
      targetKey: TourKeys.fab,
      type: TourStepType.actionRequired,
      completionPredicate: (appState, session, _) =>
          _hasNewRealExpense(appState, session),
      actionHintLocKey: 'tour_fs_s4_action_hint',
      title: t('tour_fs_s4_title'),
      body: t('tour_fs_s4_body'),
    ),

    // fs_s5: 月收支總覽（info，動態內文）
    TourStep(
      id: 'fs_s5',
      tab: 0,
      targetKey: TourKeys.monthCard,
      title: t('tour_fs_s5_title'),
      body: t('tour_fs_s5_body'),
      dynamicBody: (appState, session, ctx) {
        final latest = appState.expenses
            .where((e) =>
                !e.id.startsWith('tour_demo_') &&
                e.createdAt.isAfter(session.createdAt))
            .firstOrNull;
        if (latest == null) return AppLocalizations.of(ctx, 'tour_fs_s5_body');
        final key = latest.accountId != null
            ? 'tour_fs_s5_body_linked'
            : 'tour_fs_s5_body_unlinked';
        return AppLocalizations.ofParam(
            ctx, key, {'amount': latest.amount.toString()});
      },
    ),

    // fs_s6: 月預算目標（info）
    TourStep(
      id: 'fs_s6',
      tab: 0,
      targetKey: TourKeys.budgetCard,
      title: t('tour_fs_s6_title'),
      body: t('tour_fs_s6_body'),
    ),

    // fs_s7: 前往明細頁
    TourStep(
      id: 'fs_s7',
      tab: 0,
      targetKey: TourKeys.navDetail,
      type: TourStepType.actionRequired,
      completionPredicate: (_, __, tab) => tab == 1,
      actionHintLocKey: 'tour_fs_s7_action_hint',
      title: t('tour_fs_s7_title'),
      body: t('tour_fs_s7_body'),
    ),

    // fs_s8: 前往管理頁（從明細頁）
    TourStep(
      id: 'fs_s8',
      tab: 1,
      targetKey: TourKeys.navManage,
      type: TourStepType.actionRequired,
      completionPredicate: (_, __, tab) => tab == 3,
      actionHintLocKey: 'tour_fs_s8_action_hint',
      title: t('tour_fs_s8_title'),
      body: t('tour_fs_s8_body'),
    ),

    // fs_s9: 備份說明（info）
    TourStep(
      id: 'fs_s9',
      tab: 3,
      targetKey: TourKeys.backupCard,
      title: t('tour_fs_s9_title'),
      body: t('tour_fs_s9_body'),
    ),

    // fs_s10: 完成
    TourStep(
      id: 'fs_s10',
      tab: 3,
      targetKey: TourKeys.rewatchTile,
      type: TourStepType.finish,
      title: t('tour_fs_s10_title'),
      body: t('tour_fs_s10_body'),
    ),
  ];
}

// ─── Demo: 5 steps (demo_s0 ~ demo_s4) ───────────────────────────────────────
// 全程展示示範資料，不要求實際操作（除 demo_s3 切換明細頁）
List<TourStep> buildDemoSteps(BuildContext context) {
  String t(String key) => AppLocalizations.of(context, key);
  return [
    TourStep(
      id: 'demo_s0',
      tab: 0,
      targetKey: TourKeys.appBarTitle,
      title: t('tour_demo_s0_title'),
      body: t('tour_demo_s0_body'),
    ),
    TourStep(
      id: 'demo_s1',
      tab: 0,
      targetKey: TourKeys.monthCard,
      title: t('tour_demo_s1_title'),
      body: t('tour_demo_s1_body'),
    ),
    TourStep(
      id: 'demo_s2',
      tab: 0,
      targetKey: TourKeys.categoryCard,
      title: t('tour_demo_s2_title'),
      body: t('tour_demo_s2_body'),
    ),
    TourStep(
      id: 'demo_s3',
      tab: 0,
      targetKey: TourKeys.navDetail,
      type: TourStepType.actionRequired,
      completionPredicate: (_, __, tab) => tab == 1,
      actionHintLocKey: 'tour_demo_s3_action_hint',
      title: t('tour_demo_s3_title'),
      body: t('tour_demo_s3_body'),
    ),
    TourStep(
      id: 'demo_s4',
      tab: 1,
      type: TourStepType.finish,
      title: t('tour_demo_s4_title'),
      body: t('tour_demo_s4_body'),
    ),
  ];
}
