import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';
import '../models/fixed_item.dart';
import '../models/stock_holding.dart';
import '../../core/utils/logger.dart';
import '../databases/migration_helper.dart';

/// Enhanced app state with CRUD operations
class AppState extends ChangeNotifier {
  List<ExpenseItem> expenses = [];
  List<FixedItem> fixedItems = [];
  List<StockHolding> holdings = [];
  double usdTwdRate = 32.0;
  int budget = 30000;
  int streak = 0;
  String _lastDate = '';
  SharedPreferences? _prefs;
  bool loaded = false;

  AppState() {
    _load();
  }

  int get fixedTotal => fixedItems.fold(0, (s, i) => s + i.amount);

  bool get recordedToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _lastDate == today;
  }

  List<ExpenseItem> monthExpenses(DateTime m) => expenses.where(
    (e) => e.date.year == m.year && e.date.month == m.month,
  ).toList();

  int dynamicTotal(DateTime m) => monthExpenses(m).fold(0, (s, e) => s + e.amount);
  int usedTotal(DateTime m) => dynamicTotal(m) + fixedTotal;
  int remaining(DateTime m) => budget - usedTotal(m);
  double usedRate(DateTime m) => (usedTotal(m) / budget).clamp(0.0, 1.0);

  int dailyAvg(DateTime m) {
    final now = DateTime.now();
    final days = (now.year == m.year && now.month == m.month) ? max(1, now.day) : 30;
    return (dynamicTotal(m) / days).round();
  }

  int recommendedDaily(DateTime m) {
    final now = DateTime.now();
    final lastDay = DateTime(m.year, m.month + 1, 0).day;
    final daysLeft = (now.year == m.year && now.month == m.month)
        ? max(1, lastDay - now.day + 1)
        : lastDay;
    return (remaining(m) / daysLeft).round();
  }

  Map<String, int> categoryTotals(DateTime m) {
    final map = <String, int>{};
    for (final e in monthExpenses(m)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // ─── CRUD Operations ───

  /// Add new expense
  void addExpense(ExpenseItem item) {
    expenses.insert(0, item);
    _updateStreak();
    _save();
    notifyListeners();
    AppLogger.info('Expense added: ${item.title}');
  }

  /// Update existing expense
  void updateExpense(String id, ExpenseItem newItem) {
    final index = expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      expenses[index] = newItem.copyWith(editedAt: DateTime.now());
      _save();
      notifyListeners();
      AppLogger.info('Expense updated: ${newItem.title}');
    } else {
      AppLogger.warning('Expense not found for update: $id');
    }
  }

  /// Delete expense, returns original index for undo
  int deleteExpense(String id) {
    final index = expenses.indexWhere((e) => e.id == id);
    if (index >= 0) expenses.removeAt(index);
    _save();
    notifyListeners();
    AppLogger.info('Expense deleted: $id');
    return index;
  }

  /// Insert expense at specific index (for undo)
  void insertExpenseAt(int index, ExpenseItem item) {
    final safeIndex = index.clamp(0, expenses.length);
    expenses.insert(safeIndex, item);
    _save();
    notifyListeners();
  }

  /// Add fixed item
  void addFixed(FixedItem item) {
    fixedItems.add(item);
    _save();
    notifyListeners();
    AppLogger.info('Fixed item added: ${item.title}');
  }

  /// Update fixed item
  void updateFixed(String id, FixedItem newItem) {
    final index = fixedItems.indexWhere((f) => f.id == id);
    if (index >= 0) {
      fixedItems[index] = newItem.copyWith(editedAt: DateTime.now());
      _save();
      notifyListeners();
      AppLogger.info('Fixed item updated: ${newItem.title}');
    }
  }

  /// Delete fixed item
  void deleteFixed(String id) {
    fixedItems.removeWhere((f) => f.id == id);
    _save();
    notifyListeners();
    AppLogger.info('Fixed item deleted: $id');
  }

  // ─── Stock Holdings ───

  void addHolding(StockHolding h) {
    holdings.insert(0, h);
    _save();
    notifyListeners();
  }

  void updateHolding(String id, StockHolding updated) {
    final i = holdings.indexWhere((h) => h.id == id);
    if (i >= 0) {
      holdings[i] = updated;
      _save();
      notifyListeners();
    }
  }

  void deleteHolding(String id) {
    holdings.removeWhere((h) => h.id == id);
    _save();
    notifyListeners();
  }

  void updateHoldingPrice(String id, double price, {String? name}) {
    final i = holdings.indexWhere((h) => h.id == id);
    if (i >= 0) {
      holdings[i] = holdings[i].copyWith(currentPrice: price, name: name);
      _save();
      notifyListeners();
    }
  }

  void setUsdTwdRate(double rate) {
    usdTwdRate = rate;
    _save();
    notifyListeners();
  }

  double get totalPortfolioValue => holdings.fold(0.0, (s, h) => s + h.currentValueTwd(usdTwdRate));
  double get totalPortfolioCost => holdings.fold(0.0, (s, h) => s + h.totalCost);
  double get totalPortfolioProfit => totalPortfolioValue - totalPortfolioCost;
  double get totalPortfolioProfitPct => totalPortfolioCost == 0 ? 0 : totalPortfolioProfit / totalPortfolioCost * 100;

  /// Set budget
  void setBudget(int v) {
    budget = v;
    _save();
    notifyListeners();
    AppLogger.info('Budget updated to: $v');
  }

  /// Get expense by ID
  ExpenseItem? getExpense(String id) {
    try {
      return expenses.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get fixed item by ID
  FixedItem? getFixed(String id) {
    try {
      return fixedItems.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // ─── Utility ───

  void _updateStreak() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_lastDate == today) return;
    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    streak = (_lastDate == yesterday) ? streak + 1 : 1;
    _lastDate = today;
    _prefs?.setInt('streak', streak);
    _prefs?.setString('lastDate', _lastDate);
  }

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('✓ SharedPreferences initialized');
    } catch (e) {
      AppLogger.warning('⚠ SharedPreferences not available: $e');
      _prefs = null;
    }

    try {
      if (!await MigrationHelper.hasMigrated()) {
        AppLogger.info('Starting SharedPreferences → SQLite migration...');
        final result = await MigrationHelper.migrateFromSharedPreferences();
        if (result.success) {
          AppLogger.info('✓ Migration completed: ${result.message}');
        } else {
          AppLogger.warning('⚠ Migration failed: ${result.message}');
        }
      }
    } catch (e) {
      AppLogger.warning('⚠ Migration skipped: $e');
    }

    try {
      budget = _prefs?.getInt('budget') ?? 30000;
      streak = _prefs?.getInt('streak') ?? 0;
      _lastDate = _prefs?.getString('lastDate') ?? '';
      usdTwdRate = (_prefs?.getDouble('usdTwdRate')) ?? 32.0;

      final raw = _prefs?.getString('expenses');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        expenses = list.map((j) => ExpenseItem.fromJson(j)).toList();
        AppLogger.info('✓ Loaded ${expenses.length} expenses');
      } else {
        final now = DateTime.now();
        expenses = [
          ExpenseItem(title: '午餐便當', category: '餐飲', amount: 120, date: now, note: '【範例】可左滑刪除'),
          ExpenseItem(title: '咖啡', category: '餐飲', amount: 65, date: now, note: '【範例】可左滑刪除'),
          ExpenseItem(title: '線上課程', category: '教育', amount: 1800, date: now, note: '【範例】可左滑刪除'),
          ExpenseItem(title: '電影', category: '娛樂', amount: 420, date: now, note: '【範例】可左滑刪除'),
          ExpenseItem(title: '文具', category: '教育', amount: 430, date: now, note: '【範例】可左滑刪除'),
        ];
        AppLogger.info('✓ Using default expenses');
      }

      final fixedRaw = _prefs?.getString('fixed');
      if (fixedRaw != null) {
        final list = jsonDecode(fixedRaw) as List;
        fixedItems = list.map((j) => FixedItem.fromJson(j)).toList();
        AppLogger.info('✓ Loaded ${fixedItems.length} fixed items');
      } else {
        fixedItems = [
          FixedItem(title: 'YouTube Premium', amount: 100),
          FixedItem(title: 'ChatGPT', amount: 620),
          FixedItem(title: 'Claude', amount: 600),
          FixedItem(title: '魚油', amount: 200),
        ];
        AppLogger.info('✓ Using default fixed items');
      }

      final holdingsRaw = _prefs?.getString('holdings');
      if (holdingsRaw != null) {
        final list = jsonDecode(holdingsRaw) as List;
        holdings = list.map((j) => StockHolding.fromJson(j)).toList();
        AppLogger.info('✓ Loaded ${holdings.length} holdings');
      }

      loaded = true;
      AppLogger.info('✓ AppState loaded successfully');
      notifyListeners();
    } catch (e) {
      AppLogger.error('✗ Error during load: $e');
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      _prefs?.setString('expenses', jsonEncode(expenses.map((e) => e.toJson()).toList()));
      _prefs?.setString('fixed', jsonEncode(fixedItems.map((f) => f.toJson()).toList()));
      _prefs?.setString('holdings', jsonEncode(holdings.map((h) => h.toJson()).toList()));
      _prefs?.setDouble('usdTwdRate', usdTwdRate);
      _prefs?.setInt('budget', budget);
      AppLogger.debug('Data saved to SharedPreferences');
    } catch (e) {
      AppLogger.error('Save failed', error: e);
    }
  }

  void clearAll() {
    expenses = [];
    streak = 0;
    _lastDate = '';
    _prefs?.remove('expenses');
    _prefs?.setInt('streak', 0);
    _prefs?.setString('lastDate', '');
    notifyListeners();
    AppLogger.info('All data cleared');
  }

  /// Export data to JSON
  String exportToJson() {
    return jsonEncode({
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'fixedItems': fixedItems.map((f) => f.toJson()).toList(),
      'budget': budget,
    });
  }

  /// Import data from JSON
  void importFromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final expensesList = data['expenses'] as List? ?? [];
      expenses = expensesList.map((e) => ExpenseItem.fromJson(e)).toList();
      final fixedList = data['fixedItems'] as List? ?? [];
      fixedItems = fixedList.map((f) => FixedItem.fromJson(f)).toList();
      budget = data['budget'] as int? ?? 30000;
      _save();
      notifyListeners();
      AppLogger.info('Data imported from JSON');
    } catch (e) {
      AppLogger.error('Import failed', error: e);
      rethrow;
    }
  }
}
