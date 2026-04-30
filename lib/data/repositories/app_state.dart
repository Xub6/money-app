import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';
import '../models/fixed_item.dart';
import '../models/stock_holding.dart';
import '../models/account.dart';
import '../../core/utils/logger.dart';
import '../databases/migration_helper.dart';
import '../databases/app_database.dart';
import '../../services/encryption_service.dart';
import '../../services/stock_service.dart';

/// Enhanced app state with CRUD operations
class AppState extends ChangeNotifier {
  List<ExpenseItem> expenses = [];
  List<FixedItem> fixedItems = [];
  List<StockHolding> holdings = [];
  List<Account> accounts = [];
  Map<String, double> fxRates = {
    'USD': 32.0,
    'JPY': 0.22,
    'EUR': 35.0,
    'GBP': 41.0,
    'CNY': 4.4,
    'HKD': 4.1,
  };
  double get usdTwdRate => fxRates['USD'] ?? 32.0;
  int budget = 30000;
  int streak = 0;
  String _lastDate = '';
  SharedPreferences? _prefs;
  bool loaded = false;

  final _db = AppDatabase();
  final _enc = EncryptionService();

  AppState() {
    _load();
  }

  int get fixedTotal {
    final now = DateTime.now();
    return fixedItems
        .where((i) => i.isActiveAt(now))
        .fold(0, (s, i) => s + i.amount);
  }

  bool get recordedToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _lastDate == today;
  }

  List<ExpenseItem> monthExpenses(DateTime m) => expenses
      .where(
        (e) => e.date.year == m.year && e.date.month == m.month,
      )
      .toList();

  int dynamicTotal(DateTime m) =>
      monthExpenses(m).fold(0, (s, e) => s + e.amount);
  int usedTotal(DateTime m) => dynamicTotal(m) + fixedTotal;
  int remaining(DateTime m) => budget - usedTotal(m);
  double usedRate(DateTime m) => (usedTotal(m) / budget).clamp(0.0, 1.0);

  int dailyAvg(DateTime m) {
    final now = DateTime.now();
    final days =
        (now.year == m.year && now.month == m.month) ? max(1, now.day) : 30;
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
    _db.insertExpense(item).catchError((e) {
      AppLogger.error('DB insertExpense failed', error: e);
    });
    _save();
    notifyListeners();
    AppLogger.info('Expense added: ${item.title}');
  }

  /// Update existing expense
  void updateExpense(String id, ExpenseItem newItem) {
    final index = expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final updated = newItem.copyWith(editedAt: DateTime.now());
      expenses[index] = updated;
      _db.updateExpense(updated).catchError((e) {
        AppLogger.error('DB updateExpense failed', error: e);
      });
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
    _db.deleteExpense(id).catchError((e) {
      AppLogger.error('DB deleteExpense failed', error: e);
    });
    _save();
    notifyListeners();
    AppLogger.info('Expense deleted: $id');
    return index;
  }

  /// Insert expense at specific index (for undo)
  void insertExpenseAt(int index, ExpenseItem item) {
    final safeIndex = index.clamp(0, expenses.length);
    expenses.insert(safeIndex, item);
    _db.insertExpense(item).catchError((e) {
      AppLogger.error('DB insertExpense (undo) failed', error: e);
    });
    _save();
    notifyListeners();
  }

  /// Add fixed item
  void addFixed(FixedItem item) {
    fixedItems.add(item);
    _db.insertFixedItem(item).catchError((e) {
      AppLogger.error('DB insertFixedItem failed', error: e);
    });
    _save();
    notifyListeners();
    AppLogger.info('Fixed item added: ${item.title}');
  }

  /// Update fixed item
  void updateFixed(String id, FixedItem newItem) {
    final index = fixedItems.indexWhere((f) => f.id == id);
    if (index >= 0) {
      final updated = newItem.copyWith(editedAt: DateTime.now());
      fixedItems[index] = updated;
      _db.updateFixedItem(updated).catchError((e) {
        AppLogger.error('DB updateFixedItem failed', error: e);
      });
      _save();
      notifyListeners();
      AppLogger.info('Fixed item updated: ${newItem.title}');
    }
  }

  /// Delete fixed item
  void deleteFixed(String id) {
    fixedItems.removeWhere((f) => f.id == id);
    _db.deleteFixedItem(id).catchError((e) {
      AppLogger.error('DB deleteFixedItem failed', error: e);
    });
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

  // ─── Accounts ───

  void addAccount(Account a) {
    accounts.add(a);
    _save();
    notifyListeners();
  }

  void updateAccount(String id, Account updated) {
    final i = accounts.indexWhere((a) => a.id == id);
    if (i >= 0) {
      accounts[i] = updated;
      _save();
      notifyListeners();
    }
  }

  void deleteAccount(String id) {
    accounts.removeWhere((a) => a.id == id);
    _save();
    notifyListeners();
  }

  double get totalAssets => accounts
      .where((a) => a.category == AccountCategory.savings && a.countInTotal)
      .fold(0.0, (s, a) => s + a.balanceTwd(fxRates));

  double get totalLiabilities => accounts
      .where((a) => a.category == AccountCategory.credit && a.countInTotal)
      .fold(0.0, (s, a) => s + a.balanceTwd(fxRates).abs());

  double get netAssets => totalAssets - totalLiabilities;

  void setUsdTwdRate(double rate) {
    fxRates['USD'] = rate;
    _save();
    notifyListeners();
  }

  Future<void> refreshUsdTwdRate() async {
    final rates = await StockService.fetchFxRates();
    if (rates.isNotEmpty) {
      fxRates.addAll(rates);
      _save();
      notifyListeners();
    }
  }

  double get totalPortfolioValue =>
      holdings.fold(0.0, (s, h) => s + h.netCurrentValueTwd(usdTwdRate));
  double get totalPortfolioCost =>
      holdings.fold(0.0, (s, h) => s + h.totalCost);
  double get totalPortfolioProfit => totalPortfolioValue - totalPortfolioCost;
  double get totalPortfolioProfitPct => totalPortfolioCost == 0
      ? 0
      : totalPortfolioProfit / totalPortfolioCost * 100;

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
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
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
      await _enc.init();
    } catch (e) {
      AppLogger.warning('⚠ EncryptionService init failed: $e');
    }

    // Run one-time migration from SharedPreferences → SQLite
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

    // Load meta fields from SharedPreferences (encrypted keys preferred, plain fallback)
    try {
      streak = _prefs?.getInt('streak') ?? 0;
      _lastDate = _prefs?.getString('lastDate') ?? '';

      // budget — encrypted preferred
      final budgetEnc = _prefs?.getString('budget_enc');
      if (budgetEnc != null) {
        budget = int.tryParse(_enc.decrypt(budgetEnc)) ?? 30000;
      } else {
        budget = _prefs?.getInt('budget') ?? 30000;
      }

      // fxRates — encrypted preferred
      final fxEnc = _prefs?.getString('fxRates_enc');
      if (fxEnc != null) {
        final map = _enc.decryptMap(fxEnc);
        map?.forEach((k, v) => fxRates[k] = (v as num).toDouble());
      } else {
        final legacyUsd = _prefs?.getDouble('usdTwdRate');
        if (legacyUsd != null) fxRates['USD'] = legacyUsd;
        final fxRaw = _prefs?.getString('fxRates');
        if (fxRaw != null) {
          final map = jsonDecode(fxRaw) as Map<String, dynamic>;
          map.forEach((k, v) => fxRates[k] = (v as num).toDouble());
        }
      }

      // holdings — encrypted preferred
      final holdingsEnc = _prefs?.getString('holdings_enc');
      if (holdingsEnc != null) {
        final map = _enc.decryptMap(holdingsEnc);
        final list = map?['data'] as List? ?? [];
        holdings = list
            .map((j) => StockHolding.fromJson(j as Map<String, dynamic>))
            .toList();
        AppLogger.info('✓ Loaded ${holdings.length} holdings (encrypted)');
      } else {
        final holdingsRaw = _prefs?.getString('holdings');
        if (holdingsRaw != null) {
          final list = jsonDecode(holdingsRaw) as List;
          holdings = list.map((j) => StockHolding.fromJson(j)).toList();
          AppLogger.info('✓ Loaded ${holdings.length} holdings (plain)');
        }
      }

      // accounts — encrypted preferred
      final accountsEnc = _prefs?.getString('accounts_enc');
      if (accountsEnc != null) {
        final map = _enc.decryptMap(accountsEnc);
        final list = map?['data'] as List? ?? [];
        accounts = list
            .map((j) => Account.fromJson(j as Map<String, dynamic>))
            .toList();
        AppLogger.info('✓ Loaded ${accounts.length} accounts (encrypted)');
      } else {
        final accountsRaw = _prefs?.getString('accounts');
        if (accountsRaw != null) {
          final list = jsonDecode(accountsRaw) as List;
          accounts = list.map((j) => Account.fromJson(j)).toList();
          AppLogger.info('✓ Loaded ${accounts.length} accounts (plain)');
        }
      }
    } catch (e) {
      AppLogger.error('✗ Error loading meta from SharedPreferences: $e');
    }

    // Load expenses from SQLite (primary), fall back to SharedPreferences if empty
    try {
      expenses = await _db.getAllExpenses();
      AppLogger.info('✓ Loaded ${expenses.length} expenses from SQLite');

      if (expenses.isEmpty) {
        final raw = _prefs?.getString('expenses');
        if (raw != null) {
          final list = jsonDecode(raw) as List;
          expenses = list.map((j) => ExpenseItem.fromJson(j)).toList();
          AppLogger.info(
              '✓ Fallback: loaded ${expenses.length} expenses from SharedPreferences, syncing to SQLite');
          for (final e in expenses) {
            _db.insertExpense(e).catchError((_) {});
          }
        } else {
          final now = DateTime.now();
          expenses = [
            ExpenseItem(
                title: '午餐便當',
                category: '餐飲',
                amount: 120,
                date: now,
                note: '【範例】可左滑刪除'),
            ExpenseItem(
                title: '咖啡',
                category: '餐飲',
                amount: 65,
                date: now,
                note: '【範例】可左滑刪除'),
            ExpenseItem(
                title: '線上課程',
                category: '教育',
                amount: 1800,
                date: now,
                note: '【範例】可左滑刪除'),
            ExpenseItem(
                title: '電影',
                category: '娛樂',
                amount: 420,
                date: now,
                note: '【範例】可左滑刪除'),
            ExpenseItem(
                title: '文具',
                category: '教育',
                amount: 430,
                date: now,
                note: '【範例】可左滑刪除'),
          ];
          for (final e in expenses) {
            _db.insertExpense(e).catchError((_) {});
          }
          AppLogger.info('✓ Using default expenses');
        }
      }
    } catch (e) {
      AppLogger.error('✗ Error loading expenses: $e');
    }

    // Load fixed items from SQLite (primary), fall back to SharedPreferences if empty
    try {
      fixedItems = await _db.getAllFixedItems();
      AppLogger.info('✓ Loaded ${fixedItems.length} fixed items from SQLite');

      if (fixedItems.isEmpty) {
        final fixedRaw = _prefs?.getString('fixed');
        if (fixedRaw != null) {
          final list = jsonDecode(fixedRaw) as List;
          fixedItems = list.map((j) => FixedItem.fromJson(j)).toList();
          AppLogger.info(
              '✓ Fallback: loaded ${fixedItems.length} fixed items from SharedPreferences, syncing to SQLite');
          for (final f in fixedItems) {
            _db.insertFixedItem(f).catchError((_) {});
          }
        } else {
          fixedItems = [
            FixedItem(title: 'YouTube Premium', amount: 100),
            FixedItem(title: 'ChatGPT', amount: 620),
            FixedItem(title: 'Claude', amount: 600),
            FixedItem(title: '魚油', amount: 200),
          ];
          for (final f in fixedItems) {
            _db.insertFixedItem(f).catchError((_) {});
          }
          AppLogger.info('✓ Using default fixed items');
        }
      }
    } catch (e) {
      AppLogger.error('✗ Error loading fixed items: $e');
    }

    loaded = true;
    AppLogger.info('✓ AppState loaded successfully');
    notifyListeners();
    refreshUsdTwdRate();
  }

  /// Save meta fields to SharedPreferences with AES encryption.
  /// expenses and fixedItems are persisted directly to SQLite in each CRUD operation.
  Future<void> _save() async {
    try {
      _prefs?.setInt('streak', streak);
      _prefs?.setString('lastDate', _lastDate);

      _prefs?.setString('budget_enc', _enc.encrypt(budget.toString()));
      _prefs?.setString(
        'fxRates_enc',
        _enc.encryptMap(fxRates.map((k, v) => MapEntry(k, v))),
      );
      _prefs?.setString(
        'holdings_enc',
        _enc.encryptMap({'data': holdings.map((h) => h.toJson()).toList()}),
      );
      _prefs?.setString(
        'accounts_enc',
        _enc.encryptMap({'data': accounts.map((a) => a.toJson()).toList()}),
      );

      // Remove legacy unencrypted keys after first successful encrypted save
      _prefs?.remove('budget');
      _prefs?.remove('fxRates');
      _prefs?.remove('usdTwdRate');
      _prefs?.remove('holdings');
      _prefs?.remove('accounts');

      AppLogger.debug('Meta saved (encrypted)');
    } catch (e) {
      AppLogger.error('Save failed', error: e);
    }
  }

  void clearAll() {
    expenses = [];
    streak = 0;
    _lastDate = '';
    _db.clear().catchError((e) {
      AppLogger.error('DB clear failed', error: e);
    });
    _prefs?.remove('expenses');
    _prefs?.remove('fixed');
    _prefs?.remove('budget_enc');
    _prefs?.remove('holdings_enc');
    _prefs?.remove('accounts_enc');
    _prefs?.remove('fxRates_enc');
    _prefs?.setInt('streak', 0);
    _prefs?.setString('lastDate', '');
    notifyListeners();
    AppLogger.info('All data cleared');
  }

  void restoreFromBackup({
    required List<ExpenseItem> newExpenses,
    required List<FixedItem> newFixedItems,
    int? newBudget,
  }) {
    expenses = newExpenses;
    fixedItems = newFixedItems;
    if (newBudget != null) budget = newBudget;
    _db.clear().then((_) {
      for (final e in newExpenses) {
        _db.insertExpense(e).catchError((_) {});
      }
      for (final f in newFixedItems) {
        _db.insertFixedItem(f).catchError((_) {});
      }
    }).catchError((e) {
      AppLogger.error('DB restore failed', error: e);
    });
    _save();
    notifyListeners();
    AppLogger.info(
        'Restored from backup: ${newExpenses.length} expenses, ${newFixedItems.length} fixed items');
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
