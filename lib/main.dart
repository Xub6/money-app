import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/categories.dart';
import 'core/utils/logger.dart';
import 'data/repositories/app_state.dart';
import 'data/models/expense_item.dart';
import 'data/models/fixed_item.dart';
import 'providers/theme_provider.dart';
import 'screens/search/search_page.dart';
import 'screens/add_edit/add_edit_expense_page.dart';

// ─── 顏色別名（相容現有 widget）───
const kGold = AppColors.gold;
const kGoldLight = AppColors.goldLight;
const kBg = AppColors.background;
const kCard = AppColors.cardLight;
const kGreen = AppColors.success;
const kRed = AppColors.error;
const kGray = AppColors.textSecondary;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('Flutter Error', error: details.exception, stackTrace: details.stack);
  };

  AppLogger.info('App starting...');
  runApp(const MoneyApp());
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
            title: '錢錢管家',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
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
    if (_monthOffset == 0) return '本月';
    if (_monthOffset == -1) return '上月';
    if (_monthOffset == 1) return '下月';
    return DateFormat('M月').format(_displayMonth);
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(
          expenses: s.expenses,
          fixedItems: s.fixedItems,
        ),
      ),
    );
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<ExpenseItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditExpensePage()),
    );
    if (result != null && mounted) {
      s.addExpense(result);
    }
  }

  Future<void> _editExpense(ExpenseItem expense) async {
    final result = await Navigator.push<ExpenseItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditExpensePage(existingItem: expense),
      ),
    );
    if (result != null && mounted) {
      s.updateExpense(expense.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!s.loaded) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kGold)),
      );
    }

    final pages = [
      DashboardPage(
        state: s,
        displayMonth: _displayMonth,
        monthLabel: _monthLabel,
        onPrev: () => setState(() => _monthOffset--),
        onCur: () => setState(() => _monthOffset = 0),
        onNext: () => setState(() => _monthOffset++),
        onGoDetail: () => setState(() => _tab = 1),
      ),
      DetailPage(state: s, displayMonth: _displayMonth, onEdit: _editExpense),
      InvestPage(state: s),
      ManagePage(state: s),
    ];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('錢錢管家', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
        ],
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
          _NavItem(icon: Icons.pie_chart_rounded, label: '記帳', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
          _NavItem(icon: Icons.list_alt_rounded, label: '明細', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
          const SizedBox(width: 56),
          _NavItem(icon: Icons.show_chart_rounded, label: '統計', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
          _NavItem(icon: Icons.settings_rounded, label: '管理', selected: _tab == 3, onTap: () => setState(() => _tab = 3)),
        ]),
      ),
    );
  }
}

// ─── 首頁 ───
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
          const Text('記帳', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // 月份切換
          _AppCard(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF3E7E7), borderRadius: BorderRadius.circular(20)),
                child: Text('🔥 ${state.streak}天連勝',
                    style: const TextStyle(color: Color(0xFF8A5A5A), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _MonthBtn(text: '上月', selected: monthLabel == '上月', onTap: onPrev),
              const SizedBox(width: 10),
              _MonthBtn(text: '本月', selected: monthLabel == '本月', onTap: onCur),
              const SizedBox(width: 10),
              _MonthBtn(text: '下月', selected: monthLabel == '下月', onTap: onNext),
            ]),
          ])),
          const SizedBox(height: 16),

          // 預算進度
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(
                child: Text('預算進度（含固定開銷）',
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
              Expanded(child: _BudgetStat(label: '日均支出', value: 'NT\$ ${_fmt(daily)}')),
              Expanded(child: _BudgetStat(
                  label: '建議日均',
                  value: 'NT\$ ${_fmt(rec.clamp(0, 9999999))}',
                  valueColor: rec < 0 ? kRed : kGreen, alignEnd: true)),
            ]),
            const SizedBox(height: 14),
            const Text('剩餘預算', style: TextStyle(color: kGray, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('NT\$ ${_fmt(remain)}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: over ? kRed : kGreen)),
          ])),
          const SizedBox(height: 16),

          // 圓餅圖
          _AppCard(child: Column(children: [
            Row(children: [
              const Text('本月明細', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(16)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_month, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('年度', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onGoDetail,
                child: const Row(children: [
                  Text('查看更多', style: TextStyle(color: kGray, fontSize: 13)),
                  Icon(Icons.chevron_right, color: kGray, size: 18),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            catMap.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text('新增支出後顯示圖表', style: TextStyle(color: Colors.grey, fontSize: 15)),
                )
              : Column(children: [
                  SizedBox(height: 220, child: _DoughnutChart(catMap: catMap)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 16, runSpacing: 8,
                    children: catMap.entries.map((e) {
                      final cat = categoryOf(e.key);
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

// ─── 明細頁 ───
class DetailPage extends StatefulWidget {
  final AppState state;
  final DateTime displayMonth;
  final Function(ExpenseItem)? onEdit;

  const DetailPage({
    super.key,
    required this.state,
    required this.displayMonth,
    this.onEdit,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String _filterCat = '全部';

  void _deleteWithUndo(ExpenseItem item) {
    widget.state.deleteExpense(item.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已刪除「${item.title}」'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '復原',
          textColor: Colors.amber,
          onPressed: () => widget.state.addExpense(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var items = widget.state.monthExpenses(widget.displayMonth);
    final cats = ['全部', ...items.map((e) => e.category).toSet().toList()];
    if (_filterCat != '全部') items = items.where((e) => e.category == _filterCat).toList();
    final totalShown = items.fold(0, (s, e) => s + e.amount);

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Row(children: [
            const Expanded(child: Text('明細', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
            Text('合計 NT\$ ${_fmt(totalShown)}',
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
            ? const Center(child: Text('沒有記錄', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final cat = categoryOf(item.category);
                  return GestureDetector(
                    onLongPress: () => _showItemMenu(item),
                    child: Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                      ),
                      onDismissed: (_) => _deleteWithUndo(item),
                      child: Card(
                        elevation: 0, color: kCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: cat.color.withOpacity(0.15),
                            child: Icon(cat.icon, color: cat.color, size: 22),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.category}・${item.note.isEmpty ? "無備註" : item.note}'),
                              Text(DateFormat('yyyy/MM/dd').format(item.date)),
                              if (item.isEdited)
                                const Text('已編輯', style: TextStyle(fontSize: 11, color: Colors.orange)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Text('NT\$ ${_fmt(item.amount)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ]),
    );
  }

  void _showItemMenu(ExpenseItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編輯'),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit?.call(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('複製'),
              onTap: () {
                Navigator.pop(context);
                widget.state.addExpense(item.copyWith(title: '${item.title}（副本）'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: kRed),
              title: const Text('刪除', style: TextStyle(color: kRed)),
              onTap: () {
                Navigator.pop(context);
                _deleteWithUndo(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 統計頁 ───
class InvestPage extends StatefulWidget {
  final AppState state;
  const InvestPage({super.key, required this.state});
  @override
  State<InvestPage> createState() => _InvestPageState();
}

class _InvestPageState extends State<InvestPage> {
  DateTime? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));
    final values = months.map((m) => widget.state.usedTotal(m).toDouble()).toList();
    final maxMonth = months.reduce((a, b) => widget.state.usedTotal(a) >= widget.state.usedTotal(b) ? a : b);
    final minMonth = months.reduce((a, b) => widget.state.usedTotal(a) <= widget.state.usedTotal(b) ? a : b);
    final sel = _selectedMonth ?? now;
    final catMap = widget.state.categoryTotals(sel);
    final catTotal = catMap.values.fold(0, (s, v) => s + v);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('統計', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // 趨勢
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('近6個月支出趨勢', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('預算線 NT\$ ${_fmt(widget.state.budget)}',
                style: const TextStyle(color: kGray, fontSize: 12)),
            const SizedBox(height: 18),
            SizedBox(height: 150, child: _BarChart(months: months, values: values, budget: widget.state.budget.toDouble())),
          ])),
          const SizedBox(height: 16),

          // 最高/最低月
          Row(children: [
            Expanded(child: _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('花最多的月', style: TextStyle(color: kGray, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(DateFormat('M月').format(maxMonth),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kRed)),
              Text('NT\$ ${_fmt(widget.state.usedTotal(maxMonth))}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]))),
            const SizedBox(width: 12),
            Expanded(child: _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('花最少的月', style: TextStyle(color: kGray, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(DateFormat('M月').format(minMonth),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGreen)),
              Text('NT\$ ${_fmt(widget.state.usedTotal(minMonth))}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]))),
          ]),
          const SizedBox(height: 16),

          // 分類細項（可切換月份）
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('分類細項', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: months.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final m = months[i];
                    final isSel = m.year == sel.year && m.month == sel.month;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMonth = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? kGold : const Color(0xFFEDEBE7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(DateFormat('M月').format(m),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : Colors.black87)),
                      ),
                    );
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (catMap.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('該月無支出記錄', style: TextStyle(color: Colors.grey))),
              )
            else
              Builder(builder: (context) {
                final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                return Column(
                  children: sorted.map((e) {
                    final cat = categoryOf(e.key);
                    final pct = catTotal > 0 ? e.value / catTotal : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: cat.color.withOpacity(0.15),
                            child: Icon(cat.icon, color: cat.color, size: 13),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                          Text('NT\$ ${_fmt(e.value)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 38,
                            child: Text('${(pct * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: TextStyle(fontSize: 12, color: cat.color, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: pct, minHeight: 5,
                            backgroundColor: const Color(0xFFE8E6E2),
                            valueColor: AlwaysStoppedAnimation(cat.color),
                          ),
                        ),
                      ]),
                    );
                  }).toList(),
                );
              }),
          ])),
          const SizedBox(height: 16),

          // 月份詳細清單
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('各月詳情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...months.reversed.map((m) {
              final used = widget.state.usedTotal(m);
              final pct = (used / widget.state.budget * 100).round().clamp(0, 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(DateFormat('yyyy年M月').format(m),
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

// ─── 管理頁 ───
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
        title: const Text('新增固定開銷'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl,
              decoration: const InputDecoration(labelText: '名稱', hintText: '例如：Netflix')),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '每月金額 (NT\$)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final amt = int.tryParse(amtCtrl.text.trim());
              if (title.isNotEmpty && amt != null && amt > 0) {
                widget.state.addFixed(FixedItem(title: title, amount: amt));
                Navigator.pop(context);
              }
            },
            child: const Text('新增', style: TextStyle(color: kGold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('管理', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // 外觀設定
          _AppCard(child: Row(children: [
            const Icon(Icons.dark_mode_rounded, color: kGold),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('深色模式', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('切換深色/淺色介面', style: TextStyle(color: kGray, fontSize: 12)),
            ])),
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeColor: kGold,
            ),
          ])),
          const SizedBox(height: 16),

          // 月預算
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('月預算', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
                        const SnackBar(content: Text('✓ 預算已更新'), backgroundColor: kGreen, duration: Duration(seconds: 2)));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  elevation: 0,
                ),
                child: const Text('更新', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ])),
          const SizedBox(height: 16),

          // 固定開銷
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('固定開銷', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              Text('每月 NT\$ ${_fmt(widget.state.fixedTotal)}',
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
                  child: Text('點右上角 + 新增固定開銷', style: TextStyle(color: Colors.grey))),
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

          // 危險區
          _AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('危險區', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kRed)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('確定清除？'),
                      content: const Text('所有支出記錄將被永久刪除，無法還原。'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                        TextButton(onPressed: () => Navigator.pop(context, true),
                            child: const Text('清除', style: TextStyle(color: kRed, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    widget.state.clearAll();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('所有記錄已清除')));
                  }
                },
                icon: const Icon(Icons.delete_forever, color: kRed),
                label: const Text('清除所有支出記錄', style: TextStyle(color: kRed)),
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

// ─── 小元件 ───
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

// ─── 環形圖 ───
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
          ..color = categoryOf(e.key).color
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

// ─── 長條圖 ───
class _BarChart extends StatelessWidget {
  final List<DateTime> months; final List<double> values; final double budget;
  const _BarChart({required this.months, required this.values, required this.budget});
  @override
  Widget build(BuildContext context) {
    final maxV = [...values, budget].fold<double>(0, max) * 1.15;
    const barAreaHeight = 100.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(months.length, (i) {
        final v = values[i];
        final pct = (maxV > 0 ? (v / maxV).clamp(0.0, 1.0) : 0.0);
        final over = v > budget;
        final barH = (pct * barAreaHeight).clamp(2.0, barAreaHeight);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              if (v > 0) Text(_fmtK(v.round()),
                  style: TextStyle(fontSize: 9, color: over ? kRed : kGray, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: barH),
                duration: Duration(milliseconds: 350 + i * 80), curve: Curves.easeOut,
                builder: (_, h, __) => SizedBox(
                  height: h,
                  child: Container(
                    decoration: BoxDecoration(
                      color: over ? kRed : kGold,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(DateFormat('M月').format(months[i]),
                  style: const TextStyle(fontSize: 10, color: kGray, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }),
    );
  }
}

// ─── 工具函式 ───
String _fmt(int n) => NumberFormat('#,###').format(n);
String _fmtK(int n) => n >= 10000 ? '${(n / 1000).toStringAsFixed(0)}K' : _fmt(n);
