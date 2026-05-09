import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';
import '../models/fixed_item.dart';
import '../models/stock_holding.dart';
import '../models/account.dart';
import '../models/loan_record.dart';
import '../models/loan_payment.dart';
import '../../core/utils/logger.dart';
import '../databases/migration_helper.dart';
import '../databases/app_database.dart';
import '../../services/encryption_service.dart';
import '../../services/stock_service.dart';
import '../../core/tour/tour_demo_data.dart';
import '../../core/constants/categories.dart';

class AppState extends ChangeNotifier {
  List<ExpenseItem> expenses = [];
  List<FixedItem> fixedItems = [];
  List<StockHolding> holdings = [];
  List<Account> accounts = [];
  List<LoanRecord> loans = [];
  List<LoanPayment> loanPayments = [];
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
  bool hapticEnabled = true;
  List<Map<String, dynamic>> _customCategories = [];
  List<String> _predefinedExpenseOrder = [];
  List<String> _predefinedIncomeOrder = [];
  // 預設類別覆寫設定: {name: {iconCode, color, isHidden}}
  Map<String, Map<String, dynamic>> _predefinedCategorySettings = {};

  final _db = AppDatabase();
  final _enc = EncryptionService();
  final _demoIds = <String>{};

  AppState() {
    _load();
  }

  // ─── Category Management ───

  // 套用覆寫設定（icon/color）到單一 Category
  Category _applyOverride(Category c) {
    final settings = _predefinedCategorySettings[c.name];
    if (settings == null) return c;
    final iconCode = settings['iconCode'] as int?;
    final colorValue = settings['color'] as int?;
    return Category(
      c.name,
      iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : c.icon,
      colorValue != null ? Color(colorValue) : c.color,
    );
  }

  bool _isPredefinedHidden(String name) =>
      _predefinedCategorySettings[name]?['isHidden'] == true;

  bool isPredefinedHidden(String name) => _isPredefinedHidden(name);

  // 全部（含隱藏），供類別管理頁使用
  List<Category> get orderedExpenseCategories {
    List<String> order = _predefinedExpenseOrder;
    if (order.isEmpty) order = kCategories.map((c) => c.name).toList();
    final result = order
        .map((n) => kCategories.firstWhere((c) => c.name == n, orElse: () => kCategories.last))
        .map(_applyOverride)
        .toList();
    for (final c in kCategories) {
      if (!result.any((r) => r.name == c.name)) result.add(_applyOverride(c));
    }
    return result;
  }

  // 不含隱藏，供新增支出頁使用
  List<Category> get filteredExpenseCategories =>
      orderedExpenseCategories.where((c) => !_isPredefinedHidden(c.name)).toList();

  List<Category> get orderedIncomeCategories {
    List<String> order = _predefinedIncomeOrder;
    if (order.isEmpty) order = kIncomeCategories.map((c) => c.name).toList();
    final result = order
        .map((n) => kIncomeCategories.firstWhere((c) => c.name == n, orElse: () => kIncomeCategories.last))
        .map(_applyOverride)
        .toList();
    for (final c in kIncomeCategories) {
      if (!result.any((r) => r.name == c.name)) result.add(_applyOverride(c));
    }
    return result;
  }

  // 不含隱藏，供新增收入頁使用
  List<Category> get filteredIncomeCategories =>
      orderedIncomeCategories.where((c) => !_isPredefinedHidden(c.name)).toList();

  void reorderPredefinedCategory(String type, int oldIndex, int newIndex) {
    final isExpense = type == 'expense';
    if (isExpense && _predefinedExpenseOrder.isEmpty) {
      _predefinedExpenseOrder = kCategories.map((c) => c.name).toList();
    } else if (!isExpense && _predefinedIncomeOrder.isEmpty) {
      _predefinedIncomeOrder = kIncomeCategories.map((c) => c.name).toList();
    }
    final list = isExpense ? _predefinedExpenseOrder : _predefinedIncomeOrder;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _prefs?.setStringList(isExpense ? 'predefinedExpenseOrder' : 'predefinedIncomeOrder', list);
    hapticLight();
    notifyListeners();
  }

  List<Map<String, dynamic>> get customExpenseCategories =>
      _customCategories.where((c) => c['type'] == 'expense').toList();

  List<Map<String, dynamic>> get customIncomeCategories =>
      _customCategories.where((c) => c['type'] == 'income').toList();

  List<Map<String, dynamic>> get visibleCustomExpenseCategories =>
      _customCategories.where((c) => c['type'] == 'expense' && c['hidden'] != true).toList();

  List<Map<String, dynamic>> get visibleCustomIncomeCategories =>
      _customCategories.where((c) => c['type'] == 'income' && c['hidden'] != true).toList();

  void addCustomCategory(Map<String, dynamic> cat) {
    _customCategories.add(cat);
    _saveCustomCategories();
    notifyListeners();
  }

  void updateCustomCategory(String name, String type, Map<String, dynamic> updated) {
    final idx = _customCategories.indexWhere(
        (c) => c['name'] == name && c['type'] == type);
    if (idx >= 0) {
      _customCategories[idx] = updated;
      _saveCustomCategories();
      notifyListeners();
    }
  }

  void deleteCustomCategory(String name, String type) {
    _customCategories.removeWhere(
        (c) => c['name'] == name && c['type'] == type);
    _saveCustomCategories();
    notifyListeners();
  }

  void reorderCustomCategory(String type, int oldIndex, int newIndex) {
    final filtered = _customCategories
        .where((c) => c['type'] == type)
        .toList();
    final item = filtered.removeAt(oldIndex);
    filtered.insert(newIndex, item);
    _customCategories.removeWhere((c) => c['type'] == type);
    _customCategories.addAll(filtered);
    _saveCustomCategories();
    notifyListeners();
  }

  void toggleCustomCategoryHidden(String name, String type) {
    final idx = _customCategories.indexWhere(
        (c) => c['name'] == name && c['type'] == type);
    if (idx >= 0) {
      _customCategories[idx] = {
        ..._customCategories[idx],
        'hidden': !(_customCategories[idx]['hidden'] == true),
      };
      _saveCustomCategories();
      notifyListeners();
    }
  }

  void setUnifiedCategoryOrder(String type, List<String> predefinedNames, List<Map<String, dynamic>> orderedCustom) {
    final isExpense = type == 'expense';
    if (isExpense) {
      _predefinedExpenseOrder = predefinedNames;
    } else {
      _predefinedIncomeOrder = predefinedNames;
    }
    _prefs?.setStringList(isExpense ? 'predefinedExpenseOrder' : 'predefinedIncomeOrder', predefinedNames);
    _customCategories.removeWhere((c) => c['type'] == type);
    _customCategories.addAll(orderedCustom);
    _saveCustomCategories();
    hapticLight();
    notifyListeners();
  }

  Future<void> _saveCustomCategories() async {
    _prefs?.setString('customCategories', jsonEncode(_customCategories));
  }

  // 預設類別：隱藏/顯示
  void togglePredefinedCategoryHidden(String name) {
    final current = _predefinedCategorySettings[name] ?? {};
    final isHidden = current['isHidden'] == true;
    _predefinedCategorySettings[name] = {...current, 'isHidden': !isHidden};
    _savePredefinedCategorySettings();
    notifyListeners();
  }

  // 預設類別：修改 icon/color
  void updatePredefinedCategoryStyle(String name, {int? iconCode, int? color}) {
    final current = _predefinedCategorySettings[name] ?? {};
    if (iconCode != null) current['iconCode'] = iconCode;
    if (color != null) current['color'] = color;
    _predefinedCategorySettings[name] = current;
    _savePredefinedCategorySettings();
    notifyListeners();
  }

  Future<void> _savePredefinedCategorySettings() async {
    _prefs?.setString('predefinedCategorySettings', jsonEncode(_predefinedCategorySettings));
  }

  // ─── Haptic Feedback ───

  void setHapticEnabled(bool v) {
    hapticEnabled = v;
    _prefs?.setBool('hapticEnabled', v);
    notifyListeners();
  }

  void hapticLight() {
    if (hapticEnabled) Vibration.vibrate(duration: 40, amplitude: 80);
  }

  void hapticMedium() {
    if (hapticEnabled) Vibration.vibrate(duration: 70, amplitude: 160);
  }

  void hapticHeavy() {
    if (hapticEnabled) Vibration.vibrate(duration: 100, amplitude: 255);
  }

  // ─── Budget / Statistics ───

  int get fixedTotal {
    final now = DateTime.now();
    return fixedItems
        .where((i) => i.isActiveAt(now))
        .fold(0, (s, i) => s + _toTwd(i.amount, i.currency));
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

  /// Completed (non-pending) expenses for the month, excluding transfers.
  List<ExpenseItem> completedMonthExpenses(DateTime m) => monthExpenses(m)
      .where((e) =>
          e.status == TransactionStatus.completed &&
          e.type != TransactionType.transfer)
      .toList();

  int dynamicTotal(DateTime m) => completedMonthExpenses(m)
      .where((e) => e.type == TransactionType.expense)
      .fold(0, (s, e) => s + _toTwd(e.amount, e.currency));

  int monthIncome(DateTime m) => completedMonthExpenses(m)
      .where((e) => e.type == TransactionType.income)
      .fold(0, (s, e) => s + _toTwd(e.amount, e.currency));

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
    for (final e in completedMonthExpenses(m)) {
      if (e.type != TransactionType.expense) continue;
      map[e.category] = (map[e.category] ?? 0) + _toTwd(e.amount, e.currency);
    }
    return map;
  }

  /// Convert an amount in [currency] to TWD integer.
  int _toTwd(int amount, String currency) {
    if (currency == 'TWD') return amount;
    final rate = fxRates[currency] ?? 1.0;
    return (amount * rate).round();
  }

  // ─── Account Balance Helpers ───

  void _applyBalance(ExpenseItem item, {bool reverse = false}) {
    // Pending transactions do NOT affect balances until they complete.
    if (item.status == TransactionStatus.pending) return;

    if (item.type == TransactionType.transfer) {
      _applyTransferBalance(item, reverse: reverse);
      return;
    }

    if (item.accountId == null) return;
    final idx = accounts.indexWhere((a) => a.id == item.accountId);
    if (idx < 0) return;

    final delta = item.type == TransactionType.income
        ? item.amount.toDouble()
        : -item.amount.toDouble();
    final actual = reverse ? -delta : delta;
    accounts[idx] = accounts[idx].copyWith(
      balance: accounts[idx].balance + actual,
    );
  }

  void _applyTransferBalance(ExpenseItem item, {bool reverse = false}) {
    // Deduct from source account
    if (item.accountId != null) {
      final fromIdx = accounts.indexWhere((a) => a.id == item.accountId);
      if (fromIdx >= 0) {
        final delta = reverse ? item.amount.toDouble() : -item.amount.toDouble();
        accounts[fromIdx] = accounts[fromIdx].copyWith(
          balance: accounts[fromIdx].balance + delta,
        );
      }
    }
    // Credit to target account
    if (item.transferAccountId != null) {
      final toIdx =
          accounts.indexWhere((a) => a.id == item.transferAccountId);
      if (toIdx >= 0) {
        final delta =
            reverse ? -item.amount.toDouble() : item.amount.toDouble();
        accounts[toIdx] = accounts[toIdx].copyWith(
          balance: accounts[toIdx].balance + delta,
        );
      }
    }
  }

  // ─── CRUD Operations ───

  void addExpense(ExpenseItem item) {
    expenses.insert(0, item);
    _applyBalance(item);
    _updateStreak();
    _db.insertExpense(item).catchError((Object e) {
      AppLogger.error('DB insertExpense failed', error: e);
      return '';
    });
    _save();
    notifyListeners();
    hapticMedium();
    AppLogger.info('Expense added: ${item.title}');
  }

  void updateExpense(String id, ExpenseItem newItem) {
    final index = expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _applyBalance(expenses[index], reverse: true);
      final updated = newItem.copyWith(editedAt: DateTime.now());
      expenses[index] = updated;
      _applyBalance(updated);
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

  int deleteExpense(String id) {
    final index = expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _applyBalance(expenses[index], reverse: true);
      expenses.removeAt(index);
    }
    _db.deleteExpense(id).catchError((e) {
      AppLogger.error('DB deleteExpense failed', error: e);
    });
    _save();
    notifyListeners();
    hapticHeavy();
    AppLogger.info('Expense deleted: $id');
    return index;
  }

  void insertExpenseAt(int index, ExpenseItem item) {
    final safeIndex = index.clamp(0, expenses.length);
    expenses.insert(safeIndex, item);
    _applyBalance(item);
    _db.insertExpense(item).catchError((Object e) {
      AppLogger.error('DB insertExpense (undo) failed', error: e);
      return '';
    });
    _save();
    notifyListeners();
  }

  // ─── Transfer ───

  void addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    required DateTime date,
    String note = '',
    String currency = 'TWD',
  }) {
    final item = ExpenseItem(
      title: '帳戶轉帳',
      category: '轉帳',
      amount: amount,
      date: date,
      note: note,
      type: TransactionType.transfer,
      accountId: fromAccountId,
      transferAccountId: toAccountId,
      status: TransactionStatus.completed,
      currency: currency,
    );
    expenses.insert(0, item);
    _applyBalance(item);
    _db.insertExpense(item).catchError((Object e) {
      AppLogger.error('DB insertExpense (transfer) failed', error: e);
      return '';
    });
    _save();
    notifyListeners();
    hapticMedium();
    AppLogger.info('Transfer: $fromAccountId → $toAccountId, $amount $currency');
  }

  // ─── Fixed Items ───

  void addFixed(FixedItem item) {
    fixedItems.add(item);
    _db.insertFixedItem(item).catchError((Object e) {
      AppLogger.error('DB insertFixedItem failed', error: e);
      return '';
    });
    _save();
    notifyListeners();
    hapticMedium();
    AppLogger.info('Fixed item added: ${item.title}');
  }

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
      hapticMedium();
      AppLogger.info('Fixed item updated: ${newItem.title}');
    }
  }

  void deleteFixed(String id) {
    fixedItems.removeWhere((f) => f.id == id);
    _db.deleteFixedItem(id).catchError((e) {
      AppLogger.error('DB deleteFixedItem failed', error: e);
    });
    _save();
    notifyListeners();
    AppLogger.info('Fixed item deleted: $id');
  }

  /// Execute a fixed expense: creates an expense record and adjusts balances.
  /// If the item has a [linkedDebtAccountId], that debt is reduced by the amount.
  void executeFixed(FixedItem item, {DateTime? date}) {
    final now = date ?? DateTime.now();
    final expense = ExpenseItem(
      title: item.title,
      category: item.category,
      amount: item.amount,
      date: now,
      note: '固定開銷',
      type: TransactionType.expense,
      accountId: item.accountId,
      status: TransactionStatus.completed,
      currency: item.currency,
    );
    expenses.insert(0, expense);
    _applyBalance(expense);

    // Reduce linked debt account balance (payment reduces what is owed)
    if (item.linkedDebtAccountId != null) {
      final debtIdx =
          accounts.indexWhere((a) => a.id == item.linkedDebtAccountId);
      if (debtIdx >= 0) {
        // Debt balances are negative; adding the payment makes them less negative
        accounts[debtIdx] = accounts[debtIdx].copyWith(
          balance: accounts[debtIdx].balance + item.amount.toDouble(),
        );
      }
    }

    _db.insertExpense(expense).catchError((Object e) {
      AppLogger.error('DB insertExpense (executeFixed) failed', error: e);
      return '';
    });
    _save();
    notifyListeners();
    hapticMedium();
    AppLogger.info('Fixed executed: ${item.title}');
  }

  // ─── Pending Transaction Auto-Apply ───

  /// Checks for pending (future-dated) transactions that are now due and
  /// applies their balance effects. Called on app load and when date changes.
  void checkPendingTransactions() {
    final now = DateTime.now();
    bool changed = false;
    for (int i = 0; i < expenses.length; i++) {
      final e = expenses[i];
      if (e.status == TransactionStatus.pending && !e.date.isAfter(now)) {
        expenses[i] = e.copyWith(status: TransactionStatus.completed);
        _applyBalance(expenses[i]);
        _db.updateExpense(expenses[i]).catchError((_) => null);
        changed = true;
        AppLogger.info('Pending transaction auto-completed: ${e.title}');
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  // ─── Stock Holdings ───

  // ─── Auto Fixed Execution ───

  /// Checks whether any fixed items with a debitDay should be auto-executed today.
  /// Called on app load. Skips if already executed this month.
  void checkAutoFixedExecution() {
    final now = DateTime.now();
    final thisYM =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    bool changed = false;

    for (int i = 0; i < fixedItems.length; i++) {
      final f = fixedItems[i];
      if (!f.isActiveAt(now)) continue;
      if (f.debitDay <= 0) continue;
      if (f.lastExecutedYearMonth == thisYM) continue;
      final safeDay = f.debitDay.clamp(1, 28);
      if (now.day < safeDay) continue;

      final execDate = DateTime(now.year, now.month, safeDay);
      final expense = ExpenseItem(
        title: f.title,
        category: f.category,
        amount: f.amount,
        date: execDate,
        note: '自動扣款',
        type: TransactionType.expense,
        accountId: f.accountId,
        status: TransactionStatus.completed,
        currency: f.currency,
      );
      expenses.insert(0, expense);
      _applyBalance(expense);

      if (f.linkedDebtAccountId != null) {
        final debtIdx =
            accounts.indexWhere((a) => a.id == f.linkedDebtAccountId);
        if (debtIdx >= 0) {
          accounts[debtIdx] = accounts[debtIdx].copyWith(
            balance: accounts[debtIdx].balance + f.amount.toDouble(),
          );
        }
      }

      _db.insertExpense(expense).catchError((Object e) {
        AppLogger.error('DB insertExpense (autoFixed) failed', error: e);
        return '';
      });

      fixedItems[i] = f.copyWith(lastExecutedYearMonth: thisYM);
      _db.updateFixedItem(fixedItems[i]).catchError((_) {});
      changed = true;
      AppLogger.info('Auto-executed fixed: ${f.title} for $thisYM');
    }

    if (changed) {
      _save();
      notifyListeners();
    }
  }

  // ─── Broker Account Helpers ───

  /// Returns the ID of the broker stock account, creating one if needed.
  String? _getOrCreateBrokerAccount(String broker, StockCurrency currency) {
    if (broker.isEmpty) return null;
    final acctName = '$broker 股票帳戶';
    final acctCurrency = currency == StockCurrency.usd ? 'USD' : 'TWD';
    var idx = accounts.indexWhere((a) => a.customName == acctName);
    if (idx < 0) {
      final newAcct = Account(
        typeName: '股票帳戶',
        customName: acctName,
        category: AccountCategory.savings,
        balance: 0,
        currency: acctCurrency,
        countInTotal: false, // excluded from totalAssets to avoid double-counting
      );
      accounts.add(newAcct);
      return newAcct.id;
    }
    return accounts[idx].id;
  }

  /// Recomputes all broker stock account balances from current holding prices.
  void _syncBrokerAccounts() {
    final brokerAccts = accounts.where((a) => a.typeName == '股票帳戶').toList();
    for (final acct in brokerAccts) {
      final related = holdings.where((h) => h.accountId == acct.id).toList();
      final total = related.fold(0.0, (s, h) => s + h.currentValueTwd(usdTwdRate));
      final idx = accounts.indexWhere((a) => a.id == acct.id);
      if (idx >= 0) {
        accounts[idx] = accounts[idx].copyWith(balance: total);
      }
    }
  }

  void _applyHoldingBalance(StockHolding h, {bool reverse = false}) {
    if (h.accountId == null) return;
    final idx = accounts.indexWhere((a) => a.id == h.accountId);
    if (idx < 0) return;
    // Broker/stock accounts are managed by _syncBrokerAccounts — skip deduction
    if (accounts[idx].typeName == '股票帳戶') return;
    final delta = -h.totalCost;
    final actual = reverse ? -delta : delta;
    accounts[idx] = accounts[idx].copyWith(
      balance: accounts[idx].balance + actual,
    );
  }

  /// 扣款帳戶餘額處理（非股票帳戶，購買股票時扣錢）
  void _applyDeductBalance(StockHolding h, {bool reverse = false}) {
    if (h.deductAccountId == null) return;
    final idx = accounts.indexWhere((a) => a.id == h.deductAccountId);
    if (idx < 0) return;
    // 計算扣款金額（以帳戶幣別為準）
    double deductAmount;
    if (h.currency == StockCurrency.usd) {
      // 美股：totalCost 為 TWD 等值，換算成 USD
      deductAmount = usdTwdRate > 0 ? h.totalCost / usdTwdRate : 0;
    } else {
      deductAmount = h.totalCost; // 台股：直接扣 TWD
    }
    final delta = reverse ? deductAmount : -deductAmount;
    accounts[idx] = accounts[idx].copyWith(
      balance: accounts[idx].balance + delta,
    );
  }

  void addHolding(StockHolding h) {
    // Auto-link to broker account
    final brokerAcctId = _getOrCreateBrokerAccount(h.broker, h.currency);
    final linked = brokerAcctId != null ? h.copyWith(accountId: brokerAcctId) : h;
    holdings.insert(0, linked);
    // 扣除購買成本
    _applyDeductBalance(linked);
    _syncBrokerAccounts();
    _save();
    notifyListeners();
    hapticMedium();
  }

  void updateHolding(String id, StockHolding updated) {
    final i = holdings.indexWhere((h) => h.id == id);
    if (i >= 0) {
      _applyHoldingBalance(holdings[i], reverse: true);
      // 還原舊扣款
      _applyDeductBalance(holdings[i], reverse: true);
      // Re-link broker account if broker changed
      final brokerAcctId = _getOrCreateBrokerAccount(updated.broker, updated.currency);
      final linked = brokerAcctId != null ? updated.copyWith(accountId: brokerAcctId) : updated;
      holdings[i] = linked;
      // 套用新扣款
      _applyDeductBalance(linked);
      _syncBrokerAccounts();
      _save();
      notifyListeners();
    }
  }

  void deleteHolding(String id) {
    final i = holdings.indexWhere((h) => h.id == id);
    if (i >= 0) {
      _applyHoldingBalance(holdings[i], reverse: true);
      // 還原扣款帳戶餘額
      _applyDeductBalance(holdings[i], reverse: true);
      holdings.removeAt(i);
    }
    _syncBrokerAccounts();
    _save();
    notifyListeners();
  }

  void updateHoldingPrice(String id, double price, {String? name}) {
    final i = holdings.indexWhere((h) => h.id == id);
    if (i >= 0) {
      holdings[i] = holdings[i].copyWith(currentPrice: price, name: name);
      _syncBrokerAccounts();
      _save();
      notifyListeners();
    }
  }

  // ─── Accounts ───

  void addAccount(Account a) {
    accounts.add(a);
    _save();
    notifyListeners();
    hapticMedium();
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
    final updatedExpenses = <ExpenseItem>[];
    for (final e in expenses) {
      if (e.accountId == id) {
        final cleared = e.copyWith(accountId: null);
        updatedExpenses.add(cleared);
        _db.updateExpense(cleared).catchError((Object err) {
          AppLogger.error('DB updateExpense (deleteAccount) failed', error: err);
        });
      } else {
        updatedExpenses.add(e);
      }
    }
    expenses = updatedExpenses;
    holdings = holdings.map((h) {
      if (h.accountId != id) return h;
      return StockHolding(
        id: h.id,
        code: h.code,
        name: h.name,
        shares: h.shares,
        totalCost: h.totalCost,
        currency: h.currency,
        purchaseDate: h.purchaseDate,
        currentPrice: h.currentPrice,
        buyReason: h.buyReason,
        sellStrategy: h.sellStrategy,
        createdAt: h.createdAt,
        feeRate: h.feeRate,
        accountId: null,
      );
    }).toList();
    // Clear fixed items linked to deleted account
    fixedItems = fixedItems.map((f) {
      if (f.accountId == id || f.linkedDebtAccountId == id) {
        return f.copyWith(
          accountId: f.accountId == id ? null : f.accountId,
          linkedDebtAccountId:
              f.linkedDebtAccountId == id ? null : f.linkedDebtAccountId,
        );
      }
      return f;
    }).toList();
    _save();
    notifyListeners();
  }

  // ─── Loans ───

  void addLoan(LoanRecord loan) {
    loans.add(loan);
    if (loan.accountId != null) {
      final idx = accounts.indexWhere((a) => a.id == loan.accountId);
      if (idx >= 0) {
        accounts[idx] = accounts[idx].copyWith(
            balance: accounts[idx].balance - loan.amount);
      }
    }
    _saveLoans();
    _save();
    notifyListeners();
    hapticMedium();
  }

  void deleteLoan(String id) {
    final loan = loans.firstWhere((l) => l.id == id, orElse: () => throw StateError('not found'));
    if (loan.accountId != null) {
      final idx = accounts.indexWhere((a) => a.id == loan.accountId);
      if (idx >= 0) {
        accounts[idx] = accounts[idx].copyWith(
            balance: accounts[idx].balance + loan.amount);
      }
    }
    loans.removeWhere((l) => l.id == id);
    loanPayments.removeWhere((p) => p.loanId == id);
    _saveLoans();
    _save();
    notifyListeners();
  }

  void addLoanPayment(LoanPayment payment) {
    loanPayments.add(payment);
    final lIdx = loans.indexWhere((l) => l.id == payment.loanId);
    if (lIdx >= 0) {
      final loan = loans[lIdx];
      final newRemaining = (loan.remaining - payment.principal).clamp(0.0, loan.amount);
      final newPaid = loan.paid + payment.principal;
      loans[lIdx] = loan.copyWith(
        remaining: newRemaining,
        paid: newPaid,
        status: newRemaining <= 0 ? LoanStatus.completed : LoanStatus.active,
      );
    }
    if (payment.accountId != null) {
      final aIdx = accounts.indexWhere((a) => a.id == payment.accountId);
      if (aIdx >= 0) {
        accounts[aIdx] = accounts[aIdx].copyWith(
            balance: accounts[aIdx].balance + payment.total);
      }
    }
    _saveLoans();
    _save();
    notifyListeners();
    hapticMedium();
  }

  void deleteLoanPayment(String id) {
    final payment = loanPayments.firstWhere((p) => p.id == id, orElse: () => throw StateError('not found'));
    loanPayments.removeWhere((p) => p.id == id);
    final lIdx = loans.indexWhere((l) => l.id == payment.loanId);
    if (lIdx >= 0) {
      final loan = loans[lIdx];
      final newRemaining = (loan.remaining + payment.principal).clamp(0.0, loan.amount);
      final newPaid = (loan.paid - payment.principal).clamp(0.0, loan.amount);
      loans[lIdx] = loan.copyWith(
        remaining: newRemaining,
        paid: newPaid,
        status: LoanStatus.active,
      );
    }
    if (payment.accountId != null) {
      final aIdx = accounts.indexWhere((a) => a.id == payment.accountId);
      if (aIdx >= 0) {
        accounts[aIdx] = accounts[aIdx].copyWith(
            balance: accounts[aIdx].balance - payment.total);
      }
    }
    _saveLoans();
    _save();
    notifyListeners();
  }

  Future<void> _saveLoans() async {
    _prefs?.setString('loans', jsonEncode(loans.map((l) => l.toJson()).toList()));
    _prefs?.setString('loanPayments', jsonEncode(loanPayments.map((p) => p.toJson()).toList()));
  }

  // ─── Asset Calculations ───

  double get totalAssets => accounts
      .where((a) => a.category == AccountCategory.savings && a.countInTotal)
      .fold(0.0, (s, a) => s + a.balanceTwd(fxRates));

  double get totalLiabilities => accounts
      .where((a) => a.category == AccountCategory.credit && a.countInTotal)
      .fold(0.0, (s, a) => s + a.balanceTwd(fxRates).abs());

  /// Total assets including stock portfolio value for display purposes.
  double get totalAssetsDisplay => totalAssets + totalPortfolioValue;

  /// Net assets = savings accounts - credit accounts + stock portfolio value.
  double get netAssets => totalAssets - totalLiabilities + totalPortfolioValue;

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
      holdings.fold(0.0, (s, h) => s + h.currentValueTwd(usdTwdRate));
  double get totalPortfolioCost =>
      holdings.fold(0.0, (s, h) => s + h.totalCost);
  double get totalPortfolioProfit => totalPortfolioValue - totalPortfolioCost;
  double get totalPortfolioProfitPct => totalPortfolioCost == 0
      ? 0
      : totalPortfolioProfit / totalPortfolioCost * 100;

  void setBudget(int v) {
    budget = v;
    _save();
    notifyListeners();
    hapticMedium();
    AppLogger.info('Budget updated to: $v');
  }

  ExpenseItem? getExpense(String id) {
    try {
      return expenses.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  FixedItem? getFixed(String id) {
    try {
      return fixedItems.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // ─── Tour Demo Data ───

  void loadDemoData() {
    if (_demoIds.isNotEmpty) return;
    final demoExp = buildDemoExpenses();
    final demoHold = buildDemoHoldings();
    final demoFixed = buildDemoFixed();
    final demoAcc = buildDemoAccounts();
    for (final e in demoExp) _demoIds.add(e.id);
    for (final h in demoHold) _demoIds.add(h.id);
    for (final f in demoFixed) _demoIds.add(f.id);
    for (final a in demoAcc) _demoIds.add(a.id);
    expenses.insertAll(0, demoExp);
    holdings.insertAll(0, demoHold);
    fixedItems.insertAll(0, demoFixed);
    accounts.insertAll(0, demoAcc);
    notifyListeners();
  }

  void clearDemoData() {
    if (_demoIds.isEmpty) return;
    expenses.removeWhere((e) => _demoIds.contains(e.id));
    holdings.removeWhere((h) => _demoIds.contains(h.id));
    fixedItems.removeWhere((f) => _demoIds.contains(f.id));
    accounts.removeWhere((a) => _demoIds.contains(a.id));
    _demoIds.clear();
    _save();
    notifyListeners();
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
      streak = _prefs?.getInt('streak') ?? 0;
      _lastDate = _prefs?.getString('lastDate') ?? '';
      hapticEnabled = _prefs?.getBool('hapticEnabled') ?? true;

      final budgetEnc = _prefs?.getString('budget_enc');
      if (budgetEnc != null) {
        budget = int.tryParse(_enc.decrypt(budgetEnc)) ?? 30000;
      } else {
        budget = _prefs?.getInt('budget') ?? 30000;
      }

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

      // Loans
      final loansRaw = _prefs?.getString('loans');
      if (loansRaw != null) {
        final list = jsonDecode(loansRaw) as List;
        loans = list.map((j) => LoanRecord.fromJson(j as Map<String, dynamic>)).toList();
      }
      final paymentsRaw = _prefs?.getString('loanPayments');
      if (paymentsRaw != null) {
        final list = jsonDecode(paymentsRaw) as List;
        loanPayments = list.map((j) => LoanPayment.fromJson(j as Map<String, dynamic>)).toList();
      }

      // Custom categories
      final catRaw = _prefs?.getString('customCategories');
      if (catRaw != null) {
        final list = jsonDecode(catRaw) as List;
        _customCategories =
            list.map((e) => e as Map<String, dynamic>).toList();
        AppLogger.info(
            '✓ Loaded ${_customCategories.length} custom categories');
      }

      // Predefined category order
      final expOrder = _prefs?.getStringList('predefinedExpenseOrder');
      if (expOrder != null) _predefinedExpenseOrder = expOrder;
      final incOrder = _prefs?.getStringList('predefinedIncomeOrder');
      if (incOrder != null) _predefinedIncomeOrder = incOrder;

      // Predefined category settings (hidden/icon/color overrides)
      final catSettingsRaw = _prefs?.getString('predefinedCategorySettings');
      if (catSettingsRaw != null) {
        final raw = jsonDecode(catSettingsRaw) as Map<String, dynamic>;
        _predefinedCategorySettings = raw.map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
        );
      }
    } catch (e) {
      AppLogger.error('✗ Error loading meta from SharedPreferences: $e');
    }

    try {
      expenses = await _db.getAllExpenses();
      AppLogger.info('✓ Loaded ${expenses.length} expenses from SQLite');

      if (expenses.isEmpty) {
        final raw = _prefs?.getString('expenses');
        if (raw != null) {
          final list = jsonDecode(raw) as List;
          expenses = list.map((j) => ExpenseItem.fromJson(j)).toList();
          AppLogger.info(
              '✓ Fallback: loaded ${expenses.length} expenses from SharedPreferences');
          for (final e in expenses) {
            _db.insertExpense(e).catchError((_) => '');
          }
        }
      }
    } catch (e) {
      AppLogger.error('✗ Error loading expenses: $e');
    }

    try {
      fixedItems = await _db.getAllFixedItems();
      AppLogger.info('✓ Loaded ${fixedItems.length} fixed items from SQLite');

      if (fixedItems.isEmpty) {
        final fixedRaw = _prefs?.getString('fixed');
        if (fixedRaw != null) {
          final list = jsonDecode(fixedRaw) as List;
          fixedItems = list.map((j) => FixedItem.fromJson(j)).toList();
          AppLogger.info(
              '✓ Fallback: loaded ${fixedItems.length} fixed items from SharedPreferences');
          for (final f in fixedItems) {
            _db.insertFixedItem(f).catchError((_) => '');
          }
        }
      }
    } catch (e) {
      AppLogger.error('✗ Error loading fixed items: $e');
    }

    loaded = true;
    AppLogger.info('✓ AppState loaded successfully');
    notifyListeners();

    // Auto-apply any pending transactions that are now due
    checkPendingTransactions();
    // Auto-execute fixed items whose debit day has arrived this month
    checkAutoFixedExecution();
    // Sync broker account balances from current holdings
    _syncBrokerAccounts();
    refreshUsdTwdRate();
  }

  Future<void> _save() async {
    try {
      _prefs?.setInt('streak', streak);
      _prefs?.setString('lastDate', _lastDate);
      _prefs?.setBool('hapticEnabled', hapticEnabled);
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
    for (final e in expenses) {
      _applyBalance(e, reverse: true);
    }
    expenses = [];
    fixedItems = [];
    streak = 0;
    _lastDate = '';
    _db.clear().catchError((e) {
      AppLogger.error('DB clear failed', error: e);
    });
    _prefs?.remove('expenses');
    _prefs?.remove('fixed');
    _prefs?.setInt('streak', 0);
    _prefs?.setString('lastDate', '');
    _save();
    notifyListeners();
    AppLogger.info('All expense/fixed data cleared; account balances restored');
  }

  void restoreFromBackup({
    required List<ExpenseItem> newExpenses,
    required List<FixedItem> newFixedItems,
    required List<Account> newAccounts,
    required List<StockHolding> newHoldings,
    int? newBudget,
  }) {
    expenses = newExpenses;
    fixedItems = newFixedItems;
    accounts = newAccounts;
    holdings = newHoldings;
    if (newBudget != null) budget = newBudget;
    _db.clear().then((_) {
      for (final e in newExpenses) {
        _db.insertExpense(e).catchError((_) => '');
      }
      for (final f in newFixedItems) {
        _db.insertFixedItem(f).catchError((_) => '');
      }
    }).catchError((e) {
      AppLogger.error('DB restore failed', error: e);
    });
    _save();
    notifyListeners();
    AppLogger.info(
        'Restored from backup: ${newExpenses.length} expenses, '
        '${newFixedItems.length} fixed items, '
        '${newAccounts.length} accounts, '
        '${newHoldings.length} holdings');
  }

  String exportToJson() {
    return jsonEncode({
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'fixedItems': fixedItems.map((f) => f.toJson()).toList(),
      'budget': budget,
    });
  }

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
