import 'package:flutter/widgets.dart';
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

/// The 15-step guided tour definition.
/// Index 4  = FAB (interactive)
/// Index 13 = Feedback tile (interactive)
List<TourStep> buildTourSteps() => [
  // ── Dashboard ────────────────────────────────────────────────── 0
  TourStep(
    targetKey: TourKeys.appBarTitle,
    tab: 0,
    title: '歡迎來到錢錢管家 👋',
    body: '這套 App 幫你輕鬆管理個人財務、追蹤投資，讓你的錢用得更聰明。跟著導覽了解主要功能！',
    side: TooltipSide.below,
  ),
  // 1
  TourStep(
    targetKey: TourKeys.monthCard,
    tab: 0,
    title: '月份切換',
    body: '點選不同月份，快速切換瀏覽該月的記帳資料。',
    side: TooltipSide.below,
  ),
  // 2
  TourStep(
    targetKey: TourKeys.budgetCard,
    tab: 0,
    title: '預算進度',
    body: '顯示本月支出佔預算的比例、剩餘預算，以及日均建議消費額。可切換「含固定開銷」。',
    side: TooltipSide.below,
  ),
  // 3
  TourStep(
    targetKey: TourKeys.categoryCard,
    tab: 0,
    title: '本月支出圓餅圖',
    body: '依類別分析本月支出比例，點「年度」可以看全年每月趨勢。',
    side: TooltipSide.above,
  ),
  // 4 ── FAB interactive ─────────────────────────────────────────
  TourStep(
    targetKey: TourKeys.fab,
    tab: 0,
    title: '新增支出',
    body: '這是主要新增按鈕！在記帳頁點它可新增支出，在投資頁點它可新增持股，在管理頁可新增固定開銷。',
    isInteractive: true,
    hint: '👉 點下方金色按鈕，試著新增一筆支出',
    side: TooltipSide.above,
  ),
  // ── Detail ───────────────────────────────────────────────────── 5
  TourStep(
    targetKey: TourKeys.detailList,
    tab: 1,
    title: '支出明細',
    body: '這裡列出所有支出記錄，可依分類篩選，方便查找特定類型的支出。',
    side: TooltipSide.below,
  ),
  // 6
  TourStep(
    targetKey: TourKeys.detailList,
    tab: 1,
    title: '長按可編輯或刪除',
    body: '長按任一筆支出，可以編輯、複製或刪除。也可以左滑右側快速刪除。',
    side: TooltipSide.below,
  ),
  // ── Invest ───────────────────────────────────────────────────── 7
  TourStep(
    targetKey: TourKeys.investHeader,
    tab: 2,
    title: '投資追蹤',
    body: '管理你的持股組合，同時支援台股與美股，自動換算台幣，即時計算損益。',
    side: TooltipSide.below,
  ),
  // 8
  TourStep(
    targetKey: TourKeys.investRefresh,
    tab: 2,
    title: '即時股價刷新',
    body: '點此按鈕從 Yahoo Finance 取得最新股價，所有持股損益立即更新。',
    side: TooltipSide.below,
  ),
  // ── Manage ───────────────────────────────────────────────────── 9
  TourStep(
    targetKey: TourKeys.navManage,
    tab: 3,
    title: '管理頁面',
    body: '底部「管理」頁包含帳戶管理、預算設定、備份匯出與意見回報等功能。',
    side: TooltipSide.above,
  ),
  // 10
  TourStep(
    targetKey: TourKeys.accountCard,
    tab: 3,
    title: '帳戶管理',
    body: '管理儲蓄帳戶和信用卡，支援多幣別，自動計算淨資產總覽。',
    side: TooltipSide.below,
  ),
  // 11
  TourStep(
    targetKey: TourKeys.fixedCard,
    tab: 3,
    title: '固定開銷',
    body: '設定每月固定費用（租金、訂閱服務等），可設定分期期數自動追蹤剩餘。',
    side: TooltipSide.below,
  ),
  // 12
  TourStep(
    targetKey: TourKeys.backupCard,
    tab: 3,
    title: '備份與匯出',
    body: '備份所有資料到本機，或匯出 CSV / Excel 做進一步分析。建議定期備份！',
    side: TooltipSide.below,
  ),
  // 13 ── Feedback interactive ────────────────────────────────────
  TourStep(
    targetKey: TourKeys.feedbackTile,
    tab: 3,
    title: '意見回報',
    body: '遇到問題或有功能建議？點這裡告訴我們，每一則回饋都是改善的動力。',
    isInteractive: true,
    hint: '👉 點這裡試試看開啟意見回報',
    side: TooltipSide.above,
  ),
  // 14 ── Finish ──────────────────────────────────────────────────
  TourStep(
    targetKey: TourKeys.rewatchTile,
    tab: 3,
    title: '導覽完成！🎉',
    body: '你已了解錢錢管家的主要功能，開始記帳吧！若需要重新觀看，隨時可以在這裡開啟。',
    side: TooltipSide.above,
  ),
];
