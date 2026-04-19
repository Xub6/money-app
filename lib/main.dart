import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// âââ æ°å¢æ¨¡çµåå°å¥ âââ
import 'core/utils/logger.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // æ·»å å¨å±é¯èª¤èç
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('Flutter Error', error: details.exception, stackTrace: details.stack);
  };

  AppLogger.info('App starting...');
  runApp(const MoneyApp());
}

// âââ é¡è²å¸¸æ¸ âââ
const kGold = Color(0xFFC59B63);
const kGoldLight = Color(0xFFF5ECD8);
const kBg = Color(0xFFF6F3F1);
const kCard = Color(0xFFFFFFFD);
const kGreen = Color(0xFF88A89A);
const kRed = Color(0xFFE05C5C);
const kGray = Color(0xFF7A7A7A);

// âââ é¡å¥è¨­å® âââ
class Category {
  final String name;
  final IconData icon;
  final Color color;
  const Category(this.name, this.icon, this.color);
}

const kCategories = [
  Category('é¤é£²', Icons.restaurant, Color(0xFFD7BC74)),
  Category('æè²', Icons.school, Color(0xFF7B9BB5)),
  Category('å¨æ¨', Icons.sports_esports, Color(0xFF98AF82)),
  Category('äº¤é', Icons.directions_bus, Color(0xFFC59B63)),
  Category('è³¼ç©', Icons.shopping_bag, Color(0xFFC48DA0)),
  Category('é«ç', Icons.local_hospital, Color(0xFF88A89A)),
  Category('ä½å±', Icons.home, Color(0xFFB8956A)),
  Category('å¶ä»', Icons.more_horiz, Color(0xFFB4B2A9)),
];

Category catOf(String name) =>
    kCategories.firstWhere((c) => c.name == name, orElse: () => kCategories.last);

// âââ è³ææ¨¡å âââ
class ExpenseItem {
  final String id;
  final String title;
  final String category;
  final int amount;
  final DateTime date;
  final String note;
  final DateTime? editedAt;

  ExpenseItem({
    String? id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    this.editedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'category': category,
        'amount': amount, 'date': date.toIso8601String(), 'note': note,
        'editedAt': editedAt?.toIso8601String(),
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
        id: j['id'] ?? '', title: j['title'] ?? '',
        category: j['category'] ?? 'å¶ä»', amount: j['amount'] ?? 0,
        date: DateTime.parse(j['date']), note: j['note'] ?? '',
        editedAt: j['editedAt'] != null ? DateTime.parse(j['editedAt']) : null,
      );

  ExpenseItem copyWith({
    String? id,
    String? title,
    String? category,
    int? amount,
    DateTime? date,
    String? note,
    DateTime? editedAt,
  }) =>
      ExpenseItem(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        note: note ?? this.note,
        editedAt: editedAt ?? this.editedAt ?? DateTime.now(),
      );

  bool get isEdited => editedAt != null;
}

// æ¶å¥é ç®
class IncomeItem {
  final String id;
  final String title;
  final int amount;
  final DateTime date;
  final String source;

  IncomeItem({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.source,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'source': source,
      };

  factory IncomeItem.fromJson(Map<String, dynamic> j) => IncomeItem(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        amount: j['amount'] ?? 0,
        date: DateTime.parse(j['date']),
        source: j['source'] ?? 'å¶ä»',
      );
}

// æè³é ç®
class InvestmentItem {
  final String id;
  final String symbol;
  final String name;
  final int shares;
  final int costPerShare;
  final DateTime purchaseDate;
  final String notes;

  InvestmentItem({
    String? id,
    required this.symbol,
    required this.name,
    required this.shares,
    required this.costPerShare,
    required this.purchaseDate,
    this.notes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  int get totalCost => shares * costPerShare;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'name': name,
        'shares': shares,
        'costPerShare': costPerShare,
        'purchaseDate': purchaseDate.toIso8601String(),
        'notes': notes,
      };

  factory InvestmentItem.fromJson(Map<String, dynamic> j) => InvestmentItem(
        id: j['id'] ?? '',
        symbol: j['symbol'] ?? '',
        name: j['name'] ?? '',
        shares: j['shares'] ?? 0,
        costPerShare: j['costPerShare'] ?? 0,
        purchaseDate: DateTime.parse(j['purchaseDate']),
        notes: j['notes'] ?? '',
      );
}

class FixedItem {
  final String id;
  final String title;
  final int amount;
  FixedItem({String? id, required this.title, required this.amount})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'amount': amount};
  factory FixedItem.fromJson(Map<String, dynamic> j) =>
      FixedItem(id: j['id'], title: j['title'], amount: j['amount']);
}

// âââ çæç®¡ç âââ
class AppState extends ChangeNotifier {
  List<ExpenseItem> expenses = [];
  List<IncomeItem> incomes = [];
  List<InvestmentItem> investments = [];
  List<FixedItem> fixedItems = [];
  int budget = 30000;
  int streak = 0;
  String _lastDate = '';
  SharedPreferences? _prefs;
  bool loaded = false;

  AppState() { _load(); }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _lastDate = _prefs?.getString('lastDate') ?? '';
    budget = _prefs?.getInt('budget') ?? 30000;
    streak = _prefs?.getInt('streak') ?? 0;

    final expJson = _prefs?.getStringList('expenses') ?? [];
    final incJson = _prefs?.getStringList('incomes') ?? [];
    final invJson = _prefs?.getStringList('investments') ?? [];
    final fixJson = _prefs?.getStringList('fixed') ?? [];

    expenses = expJson.map((e) => ExpenseItem.fromJson(jsonDecode(e))).toList();
    incomes = incJson.map((e) => IncomeItem.fromJson(jsonDecode(e))).toList();
    investments = invJson.map((e) => InvestmentItem.fromJson(jsonDecode(e))).toList();
    fixedItems = fixJson.map((e) => FixedItem.fromJson(jsonDecode(e))).toList();

    _updateStreak();
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (_prefs == null) return;
    _prefs!.setStringList('expenses', expenses.map((e) => jsonEncode(e.toJson())).toList());
    _prefs!.setStringList('incomes', incomes.map((e) => jsonEncode(e.toJson())).toList());
    _prefs!.setStringList('investments', investments.map((e) => jsonEncode(e.toJson())).toList());
    _prefs!.setStringList('fixed', fixedItems.map((e) => jsonEncode(e.toJson())).toList());
    _prefs!.setInt('budget', budget);
    _prefs!.setInt('streak', streak);
    _prefs!.setString('lastDate', _lastDate);
  }

  void addExpense(ExpenseItem e) {
    expenses.add(e);
    _updateStreak();
    _save();
    notifyListeners();
    AppLogger.info('Expense added: ${e.title}');
  }

  void updateExpense(String id, ExpenseItem newItem) {
    final idx = expenses.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      expenses[idx] = newItem;
      _save();
      notifyListeners();
      AppLogger.info('Expense updated: ${newItem.title}');
    }
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    _updateStreak();
    _save();
    notifyListeners();
  }

  void addIncome(IncomeItem i) {
    incomes.add(i);
    _save();
    notifyListeners();
  }

  void deleteIncome(String id) {
    incomes.removeWhere((i) => i.id == id);
    _save();
    notifyListeners();
  }

  void addInvestment(InvestmentItem inv) {
    investments.add(inv);
    _save();
    notifyListeners();
  }

  void deleteInvestment(String id) {
    investments.removeWhere((inv) => inv.id == id);
    _save();
    notifyListeners();
  }

  void addFixed(FixedItem f) {
    fixedItems.add(f);
    _save();
    notifyListeners();
  }

  void updateFixed(String id, FixedItem f) {
    final idx = fixedItems.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      fixedItems[idx] = f;
      _save();
      notifyListeners();
    }
  }

  void deleteFixed(String id) {
    fixedItems.removeWhere((e) => e.id == id);
    _save();
    notifyListeners();
  }

  void setBudget(int b) {
    budget = b;
    _save();
    notifyListeners();
  }

  void clearAll() {
    expenses.clear();
    fixedItems.clear();
    _save();
    notifyListeners();
  }

  ExpenseItem? getExpense(String id) => expenses.cast<ExpenseItem?>().firstWhere((e) => e?.id == id, orElse: () => null);
  FixedItem? getFixed(String id) => fixedItems.cast<FixedItem?>().firstWhere((e) => e?.id == id, orElse: () => null);

  List<ExpenseItem> monthExpenses(DateTime month) =>
      expenses.where((e) => e.date.year == month.year && e.date.month == month.month).toList();

  int usedTotal(DateTime month) {
    final monthExp = monthExpenses(month).fold<int>(0, (s, e) => s + e.amount);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final fixedAmount = fixedItems.fold<int>(0, (s, e) => s + e.amount) * (isCurrentMonth ? now.day : DateTime(month.year, month.month + 1, 0).day);
    return monthExp + fixedAmount;
  }

  double usedRate(DateTime month) => (usedTotal(month) / budget).clamp(0.0, double.infinity);
  int remaining(DateTime month) => budget - usedTotal(month);
  int dailyAvg(DateTime month) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    return (usedTotal(month) / days).round();
  }

  int recommendedDaily(DateTime month) => (remaining(month) / (DateTime(month.year, month.month + 1, 0).day)).round();

  Map<String, int> categoryTotals(DateTime month) {
    final result = <String, int>{};
    for (final e in monthExpenses(month)) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  int get fixedTotal => fixedItems.fold<int>(0, (s, e) => s + e.amount);

  void _updateStreak() {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    if (_lastDate == today) return;
    _lastDate = today;
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    final hasYesterdayExp = expenses.any((e) => DateFormat('yyyy-MM-dd').format(e.date) == yesterdayStr);
    streak = hasYesterdayExp ? (streak + 1) : 1;
  }

  String exportToJson() => jsonEncode({
    'budget': budget,
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'fixedItems': fixedItems.map((e) => e.toJson()).toList(),
  });

  Future<void> importFromJson(String json) async {
    try {
      final data = jsonDecode(json);
      budget = data['budget'] ?? 30000;
      expenses = (data['expenses'] ?? []).map<ExpenseItem>((e) => ExpenseItem.fromJson(e)).toList();
      fixedItems = (data['fixedItems'] ?? []).map<FixedItem>((e) => FixedItem.fromJson(e)).toList();
      await _save();
      notifyListeners();
      AppLogger.info('Data imported successfully');
    } catch (e) {
      AppLogger.error('Import failed', error: e);
      rethrow;
    }
  }
}

/// Main app widget with providers
class MoneyApp extends StatefulWidget {
  const MoneyApp({super.key});

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> {
  final _appState = AppState();
  final _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _appState.dispose();
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ListenableProvider.value(value: _appState),
        ListenableProvider.value(value: _themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'é¢é¢ç®¡å®¶',
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: kBg,
              colorScheme: ColorScheme.fromSeed(seedColor: kGold),
            ),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Consumer<AppState>(
              builder: (context, appState, _) {
                if (!appState.loaded) {
                  return const Scaffold(
                    backgroundColor: kBg,
                    body: Center(
                      child: CircularProgressIndicator(color: kGold),
                    ),
                  );
                }
                return MainShell(state: appState);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Main navigation shell
class MainShell extends StatefulWidget {
  final AppState state;
  const MainShell({super.key, required this.state});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  int _monthOffset = 0;
  AppState get s => widget.state;

  DateTime get _displayMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  String get _monthLabel {
    if (_monthOffset == 0) return 'æ¬æ';
    if (_monthOffset == -1) return 'ä¸æ';
    if (_monthOffset == 1) return 'ä¸æ';
    return DateFormat('Mæ').format(_displayMonth);
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'æ°å¢',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              _AddOptionButton(
                icon: Icons.shopping_cart,
                label: 'æ°å¢æ¯åº',
                color: kRed,
                onTap: () async {
                  Navigator.pop(context);
                  final item = await Navigator.push<ExpenseItem>(
                    context,
                    MaterialPageRoute(builder: (_) => AddExpensePage(state: s)),
                  );
                  if (item != null && mounted) s.addExpense(item);
                },
              ),
              const SizedBox(height: 12),
              _AddOptionButton(
                icon: Icons.trending_up,
                label: 'æ°å¢æ¶å¥',
                color: kGreen,
                onTap: () {
                  Navigator.pop(context);
                  _showAddIncomeDialog();
                },
              ),
              const SizedBox(height: 12),
              _AddOptionButton(
                icon: Icons.receipt,
                label: 'æ°å¢åºå®éé·',
                color: kGold,
                onTap: () {
                  Navigator.pop(context);
                  _showAddFixedDialog();
                },
              ),
              const SizedBox(height: 12),
              _AddOptionButton(
                icon: Icons.show_chart,
                label: 'æ°å¢æè³',
                color: const Color(0xFF4D8ED8),
                onTap: () {
                  Navigator.pop(context);
                  _showAddInvestmentDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String cat = 'é¤é£²';
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('æ°å¢æ¯åº'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'åç¨±')),
              TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'éé¡')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () { titleCtrl.dispose(); amtCtrl.dispose(); noteCtrl.dispose(); Navigator.pop(context); }, child: const Text('åæ¶')),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final amt = int.tryParse(amtCtrl.text.trim());
              if (title.isNotEmpty && amt != null && amt > 0) {
                s.addExpense(ExpenseItem(title: title, category: cat, amount: amt, date: date, note: noteCtrl.text.trim()));
                titleCtrl.dispose(); amtCtrl.dispose(); noteCtrl.dispose(); Navigator.pop(context);
              }
            },
            child: const Text('æ°å¢'),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog() {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String source = 'èªè³';
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('æ°å¢æ¶å¥'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'åç¨±')),
              TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'éé¡')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('åæ¶')),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final amt = int.tryParse(amtCtrl.text.trim());
              if (title.isNotEmpty && amt != null && amt > 0) {
                s.addIncome(IncomeItem(title: title, amount: amt, date: date, source: source));
                Navigator.pop(context);
              }
            },
            child: const Text('æ°å¢'),
          ),
        ],
      ),
    );
  }

  void _showAddFixedDialog() {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('æ°å¢åºå®éé·'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'åç¨±')),
              TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'æ¯æéé¡')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('åæ¶')),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final amt = int.tryParse(amtCtrl.text.trim());
              if (title.isNotEmpty && amt != null && amt > 0) {
                s.addFixed(FixedItem(title: title, amount: amt));
                Navigator.pop(context);
              }
            },
            child: const Text('æ°å¢'),
          ),
        ],
      ),
    );
  }

  void _showAddInvestmentDialog() {
    final symbolCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final sharesCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('æ°å¢æè³'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: symbolCtrl, decoration: const InputDecoration(labelText: 'ä»£è')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'åç¨±')),
              TextField(controller: sharesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'è¡æ¸')),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ææ¬å®å¹')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('åæ¶')),
          TextButton(
            onPressed: () {
              final symbol = symbolCtrl.text.trim();
              final name = nameCtrl.text.trim();
              final shares = int.tryParse(sharesCtrl.text.trim());
              final cost = int.tryParse(costCtrl.text.trim());
              if (symbol.isNotEmpty && name.isNotEmpty && shares != null && cost != null && shares > 0 && cost > 0) {
                s.addInvestment(InvestmentItem(
                  symbol: symbol,
                  name: name,
                  shares: shares,
                  costPerShare: cost,
                  purchaseDate: DateTime.now(),
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('æ°å¢'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!s.loaded) {
      return const Scaffold(backgroundColor: kBg,
          body: Center(child: CircularProgressIndicator(color: kGold)));
    }

    final pages = [
      DashboardPage(state: s, displayMonth: _displayMonth, monthLabel: _monthLabel,
          onPrev: () => setState(() => _monthOffset--),
          onCur: () => setState(() => _monthOffset = 0),
          onNext: () => setState(() => _monthOffset++),
          onGoDetail: () => setState(() => _tab = 1)),
      DetailPage(state: s, displayMonth: _displayMonth),
      InvestPage(state: s),
      ManagePage(state: s),
    ];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('é¢é¢ç®¡å®¶', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: kGold,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 70,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: Row(children: [
          _NavItem(icon: Icons.pie_chart_rounded, label: 'è¨å¸³', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
          _NavItem(icon: Icons.list_alt_rounded, label: 'æç´°', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
          const SizedBox(width: 56),
          _NavItem(icon: Icons.show_chart_rounded, label: 'çµ±è¨', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
          _NavItem(icon: Icons.settings_rounded, label: 'ç®¡ç', selected: _tab == 3, onTap: () => setState(() => _tab = 3)),
        ]),
      ),
    );
  }
}

// âââ é¦é  âââ
class DashboardPage extends StatelessWidget {
  final AppState state;
  final DateTime displayMonth;
  final String monthLabel;
  final VoidCallback onPrev, onCur, onNext, onGoDetail;
  const DashboardPage({super.key, required this.state, required this.displayMonth,
    required this.monthLabel, required this.onPrev, required this.onCur,
    required this.onNext, required this.onGoDetail});

  @override
  Widget build(BuildContext context) {
    final used = state.usedTotal(displayMonth);
    final pct = (state.usedRate(displayMonth) * 100).round();
    final remain = state.remaining(displayMonth);
    final daily = state.dailyAvg(displayMonth);
    final rec = state.recommendedDaily(displayMonth);
    final catMap = state.categoryTotals(displayMonth);
    final over = remain < 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('è¨å¸³', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // æä»½åæ
          _AppCard(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF3E7E7), borderRadius: BorderRadius.circular(20)),
                child: Text('ð¥ ${state.streak}å¤©é£å',
                    style: const TextStyle(color: Color(0xFF8A5A5A), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _MonthBtn(text: 'ä¸æ', selected: monthLabel == 'ä¸æ', onTap: onPrev),
              const SizedBox(width: 10),
              _MonthBtn(text: 'æ¬æ', selected: monthLabel == 'æ¬æ', onTap: onCur),
              const SizedBox(width: 10),
              _MonthBtn(text: 'ä¸æ', selected: monthLabel == 'ä¸æ', onTap: onNext),
            ]),
          ])),
          const SizedBox(height: 16),

          // é ç®é²åº¦
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(
                child: Text('é ç®é²åº¦ï¼å«åºå®éé·ï¼',
                    style: TextStyle(color: kGray, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text('NT\$ ${_fmt(used)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text(' / ${_fmt(state.budget)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ]),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: state.usedRate(displayMonth)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v, minHeight: 10,
                  backgroundColor: const Color(0xFFE8E6E2),
                  valueColor: AlwaysStoppedAnimation(over ? kRed : kGreen),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text('$pct%', style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: over ? kRed : kGreen)),
            ),
            const Divider(height: 20),
            Row(children: [
              Expanded(child: _BudgetStat(label: 'æ¥åæ¯åº', value: 'NT\$ ${_fmt(daily)}')),
              Expanded(child: _BudgetStat(
                  label: 'å»ºè­°æ¥å',
                  value: 'NT\$ ${_fmt(rec.clamp(0, 9999999))}',
                  valueColor: rec < 0 ? kRed : kGreen, alignEnd: true)),
            ]),
            const SizedBox(height: 14),
            const Text('å©é¤é ç®', style: TextStyle(color: kGray, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('NT\$ ${_fmt(remain)}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: over ? kRed : kGreen)),
          ])),
          const SizedBox(height: 16),

          // åé¤å
          _AppCard(child: Column(children: [
            Row(children: [
              const Text('æ¬ææç´°', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(16)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_month, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('å¹´åº¦', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onGoDetail,
                child: const Row(children: [
                  Text('æ¥çæ´å¤', style: TextStyle(color: kGray, fontSize: 13)),
                  Icon(Icons.chevron_right, color: kGray, size: 18),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            catMap.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text('æ°å¢æ¯åºå¾é¡¯ç¤ºåè¡¨', style: TextStyle(color: Colors.grey, fontSize: 15)),
                )
              : Column(children: [
                  SizedBox(height: 220, child: _DoughnutChart(catMap: catMap)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 16, runSpacing: 8,
                    children: catMap.entries.map((e) {
                      final cat = catOf(e.key);
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(e.key, style: const TextStyle(color: kGray, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 3),
                        Text('NT\$ ${_fmt(e.value)}',
                            style: const TextStyle(color: kGray, fontSize: 11)),
                      ]);
                    }).toList(),
                  ),
                ]),
          ])),
        ]),
      ),
    );
  }
}

// âââ æç´°é  âââ
class DetailPage extends StatefulWidget {
  final AppState state;
  final DateTime displayMonth;
  const DetailPage({super.key, required this.state, required this.displayMonth});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String _filterCat = 'å¨é¨';

  @override
  Widget build(BuildContext context) {
    var items = widget.state.monthExpenses(widget.displayMonth);
    final cats = ['å¨é¨', ...items.map((e) => e.category).toSet().toList()];
    if (_filterCat != 'å¨é¨') items = items.where((e) => e.category == _filterCat).toList();
    final totalShown = items.fold(0, (s, e) => s + e.amount);

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Row(children: [
            const Expanded(child: Text('æç´°', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
            Text('åè¨ NT\$ ${_fmt(totalShown)}',
                style: const TextStyle(color: kGold, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = cats[i] == _filterCat;
              return GestureDetector(
                onTap: () => setState(() => _filterCat = cats[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? kGold : const Color(0xFFEDEBE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cats[i], style: TextStyle(
                      color: sel ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: items.isEmpty
            ? const Center(child: Text('æ²æè¨é', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final cat = catOf(item.category);
                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('åªé¤æ¯åº'),
                          content: Text('ç¢ºå®åªé¤ã${item.title}ãï¼'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('åæ¶')),
                            TextButton(onPressed: () => Navigator.pop(context, true),
                                child: const Text('åªé¤', style: TextStyle(color: kRed))),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) => widget.state.deleteExpense(item.id),
                    child: Card(
                      elevation: 0, color: kCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withValues(alpha: 0.15),
                          child: Icon(cat.icon, color: cat.color, size: 22),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: Text('${item.category}ã»${item.note.isEmpty ? "ç¡åè¨»" : item.note}\n${DateFormat('yyyy/MM/dd').format(item.date)}'),
                        isThreeLine: true,
                        trailing: Text('NT\$ ${_fmt(item.amount)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                },
              ),
        ),
      ]),
    );
  }
}

// âââ æ°å¢æ¯åºé  âââ
class AddExpensePage extends StatefulWidget {
  final AppState state;
  const AddExpensePage({super.key, required this.state});
  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _titleCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _cat = 'é¤é£²';
  DateTime _date = DateTime.now();

  @override
  void dispose() { _titleCtrl.dispose(); _amtCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amt = int.tryParse(_amtCtrl.text.trim());
    if (title.isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('è«å¡«å¯«æ­£ç¢ºçåç¨±èéé¡'), backgroundColor: kRed));
      return;
    }
    Navigator.pop(context, ExpenseItem(
        title: title, category: _cat, amount: amt, date: _date, note: _noteCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('æ°å¢æ¯åº', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FormLabel('é ç®åç¨±'),
          _FormField(ctrl: _titleCtrl, hint: 'ä¾å¦ï¼åé¤ãåå¡ãèª²ç¨'),
          const SizedBox(height: 18),
          _FormLabel('éé¡ (NT\$)'),
          _FormField(ctrl: _amtCtrl, hint: 'è«è¼¸å¥éé¡', type: TextInputType.number),
          const SizedBox(height: 18),
          _FormLabel('æ¥æ'),
          GestureDetector(
            onTap: () async {
              final p = await showDatePicker(context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
              if (p != null) setState(() => _date = p);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: kGold, size: 18),
                const SizedBox(width: 10),
                Text(DateFormat('yyyy / MM / dd').format(_date), style: const TextStyle(fontSize: 15)),
                const Spacer(),
                const Icon(Icons.edit_outlined, color: kGray, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          _FormLabel('é¡å¥'),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: kCategories.map((c) {
              final sel = _cat == c.name;
              return GestureDetector(
                onTap: () => setState(() => _cat = c.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? c.color.withValues(alpha: 0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? c.color : Colors.grey.shade300, width: sel ? 1.5 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(c.icon, color: sel ? c.color : Colors.grey, size: 18),
                    const SizedBox(width: 6),
                    Text(c.name, style: TextStyle(
                        color: sel ? c.color : Colors.black87,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _FormLabel('åè¨»ï¼é¸å¡«ï¼'),
          TextField(
            controller: _noteCtrl, maxLines: 3,
            decoration: InputDecoration(
              hintText: 'å¯å¡«å¯ä¸å¡«', filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: const Text('å²å­', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}

// âââ çµ±è¨é  âââ
class InvestPage extends StatelessWidget {
  final AppState state;
  const InvestPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));
    final values = months.map((m) => state.usedTotal(m).toDouble()).toList();
    final maxMonth = months.reduce((a, b) => state.usedTotal(a) >= state.usedTotal(b) ? a : b);
    final minMonth = months.reduce((a, b) => state.usedTotal(a) <= state.usedTotal(b) ? a : b);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('çµ±è¨', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // è¶¨å¢
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('è¿6åææ¯åºè¶¨å¢', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('é ç®ç· NT\$ ${_fmt(state.budget)}',
                style: const TextStyle(color: kGray, fontSize: 12)),
            const SizedBox(height: 18),
            SizedBox(height: 150, child: _BarChart(months: months, values: values, budget: state.budget.toDouble())),
          ])),
          const SizedBox(height: 16),

          // æé«/æä½æ
          Row(children: [
            Expanded(child: _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('è±æå¤çæ', style: TextStyle(color: kGray, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(DateFormat('Mæ').format(maxMonth),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kRed)),
              Text('NT\$ ${_fmt(state.usedTotal(maxMonth))}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]))),
            const SizedBox(width: 12),
            Expanded(child: _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('è±æå°çæ', style: TextStyle(color: kGray, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(DateFormat('Mæ').format(minMonth),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGreen)),
              Text('NT\$ ${_fmt(state.usedTotal(minMonth))}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]))),
          ]),
          const SizedBox(height: 16),

          // æä»½è©³ç´°æ¸å®
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('åæè©³æ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...months.reversed.map((m) {
              final used = state.usedTotal(m);
              final pct = (used / state.budget * 100).round().clamp(0, 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(DateFormat('yyyyå¹´Mæ').format(m),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text('NT\$ ${_fmt(used)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text('$pct%', style: TextStyle(
                        color: pct > 90 ? kRed : kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct / 100, minHeight: 6,
                      backgroundColor: const Color(0xFFE8E6E2),
                      valueColor: AlwaysStoppedAnimation(pct > 90 ? kRed : kGreen),
                    ),
                  ),
                ]),
              );
            }),
          ])),
        ]),
      ),
    );
  }
}

// âââ ç®¡çé  âââ
class ManagePage extends StatefulWidget {
  final AppState state;
  const ManagePage({super.key, required this.state});
  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  late final TextEditingController _budgetCtrl;

  @override
  void initState() {
    super.initState();
    _budgetCtrl = TextEditingController(text: widget.state.budget.toString());
  }

  @override
  void dispose() { _budgetCtrl.dispose(); super.dispose(); }

  void _addFixed() {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('æ°å¢åºå®éé·'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'åç¨±', hintText: 'ä¾å¦ï¼Netflix')),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'æ¯æéé¡ (NT\$)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('åæ¶')),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final amt = int.tryParse(amtCtrl.text.trim());
              if (title.isNotEmpty && amt != null && amt > 0) {
                widget.state.addFixed(FixedItem(title: title, amount: amt));
                Navigator.pop(context);
              }
            },
            child: const Text('æ°å¢', style: TextStyle(color: kGold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ç®¡ç', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // æé ç®
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('æé ç®', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    prefixText: 'NT\$ ',
                    filled: true, fillColor: kGoldLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGold, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final val = int.tryParse(_budgetCtrl.text.trim());
                  if (val != null && val > 0) {
                    widget.state.setBudget(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('â é ç®å·²æ´æ°'), backgroundColor: kGreen, duration: Duration(seconds: 2)));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  elevation: 0,
                ),
                child: const Text('æ´æ°', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ])),
          const SizedBox(height: 16),

          // åºå®éé·
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('åºå®éé·', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              Text('æ¯æ NT\$ ${_fmt(widget.state.fixedTotal)}',
                  style: const TextStyle(color: kGold, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addFixed,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: kGoldLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add, color: kGold, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            if (widget.state.fixedItems.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('é»å³ä¸è§ + æ°å¢åºå®éé·', style: TextStyle(color: Colors.grey))),
            ...widget.state.fixedItems.map((f) => Dismissible(
              key: Key(f.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => widget.state.deleteFixed(f.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFF8F6F3), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.receipt_long, color: kGold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('NT\$ ${_fmt(f.amount)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  const Icon(Icons.drag_indicator, color: Colors.grey, size: 18),
                ]),
              ),
            )),
          ])),
          const SizedBox(height: 16),

          // å±éªå
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('å±éªå', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kRed)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('ç¢ºå®æ¸é¤ï¼'),
                      content: const Text('æææ¯åºè¨éå°è¢«æ°¸ä¹åªé¤ï¼ç¡æ³éåã'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('åæ¶')),
                        TextButton(onPressed: () => Navigator.pop(context, true),
                            child: const Text('æ¸é¤', style: TextStyle(color: kRed, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    widget.state.clearAll();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ææè¨éå·²æ¸é¤')));
                  }
                },
                icon: const Icon(Icons.delete_forever, color: kRed),
                label: const Text('æ¸é¤æææ¯åºè¨é', style: TextStyle(color: kRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

// âââ å°åä»¶ âââ
class _AppCard extends StatelessWidget {
  final Widget child;
  const _AppCard({required this.child});
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, color: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class _MonthBtn extends StatelessWidget {
  final String text; final bool selected; final VoidCallback onTap;
  const _MonthBtn({required this.text, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? kGold : const Color(0xFFEDEBE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w700, fontSize: 14)),
    ),
  );
}

class _BudgetStat extends StatelessWidget {
  final String label, value; final Color? valueColor; final bool alignEnd;
  const _BudgetStat({required this.label, required this.value, this.valueColor, this.alignEnd = false});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: kGray, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: valueColor ?? Colors.black87)),
    ],
  );
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl; final String hint; final TextInputType type;
  const _FormField({required this.ctrl, required this.hint, this.type = TextInputType.text});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: type,
    decoration: InputDecoration(
      hintText: hint, filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGold, width: 1.5)),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF4D8ED8) : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }
}

// âââ ç°å½¢å âââ
class _DoughnutChart extends StatelessWidget {
  final Map<String, int> catMap;
  const _DoughnutChart({required this.catMap});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DoughnutPainter(catMap: catMap), child: const Center());
}

class _DoughnutPainter extends CustomPainter {
  final Map<String, int> catMap;
  _DoughnutPainter({required this.catMap});
  @override
  void paint(Canvas canvas, Size size) {
    final total = catMap.values.fold<int>(0, (s, v) => s + v).toDouble();
    if (total == 0) return;
    const sw = 40.0;
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) - sw;
    // åºå
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = const Color(0xFFE6E3DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw);
    double start = -pi / 2;
    const gap = 0.07;
    for (final e in catMap.entries) {
      final sweep = (e.value / total) * 2 * pi - gap;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, sweep, false,
        Paint()
          ..color = catOf(e.key).color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
      start += sweep + gap;
    }
  }
  @override
  bool shouldRepaint(_DoughnutPainter o) => o.catMap != catMap;
}

// âââ é·æ¢å âââ
class _BarChart extends StatelessWidget {
  final List<DateTime> months; final List<double> values; final double budget;
  const _BarChart({required this.months, required this.values, required this.budget});
  @override
  Widget build(BuildContext context) {
    final maxV = [...values, budget].fold<double>(0, max) * 1.15;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(months.length, (i) {
        final v = values[i];
        final pct = maxV > 0 ? (v / maxV).clamp(0.0, 1.0) : 0.0;
        final over = v > budget;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (v > 0) Text(_fmtK(v.round()),
                  style: TextStyle(fontSize: 9, color: over ? kRed : kGray, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: Duration(milliseconds: 350 + i * 80), curve: Curves.easeOut,
                builder: (_, p, __) => FractionallySizedBox(
                  heightFactor: p,
                  child: Container(
                    decoration: BoxDecoration(
                      color: over ? kRed : kGold,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(DateFormat('Mæ').format(months[i]),
                  style: const TextStyle(fontSize: 10, color: kGray, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }),
    );
  }
}

// âââ å·¥å·å½å¼ âââ
String _fmt(int n) => NumberFormat('#,###').format(n);
String _fmtK(int n) => n >= 10000 ? '${(n / 1000).toStringAsFixed(0)}K' : _fmt(n);
