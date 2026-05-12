import 'package:flutter/widgets.dart';

/// Central registry of all GlobalKeys used by the guided tour.
class TourKeys {
  TourKeys._();

  // ── Tab 0: Dashboard ──────────────────────────────
  static final appBarTitle   = GlobalKey(debugLabel: 'tour_appBarTitle');
  static final monthCard     = GlobalKey(debugLabel: 'tour_monthCard');
  static final budgetCard    = GlobalKey(debugLabel: 'tour_budgetCard');
  static final categoryCard  = GlobalKey(debugLabel: 'tour_categoryCard');

  // ── FAB (all tabs) ────────────────────────────────
  static final fab           = GlobalKey(debugLabel: 'tour_fab');

  // ── Bottom nav items ──────────────────────────────
  static final navDashboard  = GlobalKey(debugLabel: 'tour_navDashboard');
  static final navDetail     = GlobalKey(debugLabel: 'tour_navDetail');
  static final navInvest     = GlobalKey(debugLabel: 'tour_navInvest');
  static final navManage     = GlobalKey(debugLabel: 'tour_navManage');

  // ── Tab 1: Detail ─────────────────────────────────
  static final detailList    = GlobalKey(debugLabel: 'tour_detailList');

  // ── Tab 2: Invest ─────────────────────────────────
  static final investHeader  = GlobalKey(debugLabel: 'tour_investHeader');

  // ── Tab 3: Manage ─────────────────────────────────
  static final accountCard   = GlobalKey(debugLabel: 'tour_accountCard');
  static final accountAddBtn = GlobalKey(debugLabel: 'tour_accountAddBtn');
  static final backupCard    = GlobalKey(debugLabel: 'tour_backupCard');
  static final rewatchTile   = GlobalKey(debugLabel: 'tour_rewatchTile');
  static final feedbackTile  = GlobalKey(debugLabel: 'tour_feedbackTile');
  static final investRefresh = GlobalKey(debugLabel: 'tour_investRefresh');
}
