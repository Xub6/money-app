import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// 新增导入
import 'core/constants/app_colors.dart';
import 'core/utils/logger.dart';
import 'data/repositories/app_state.dart';
import 'providers/theme_provider.dart';
import 'services/backup_service.dart';
import 'services/search_service.dart';
import 'screens/search/search_page.dart';
import 'screens/add_edit/add_edit_expense_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 添加全局错误处理
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
                    backgroundColor: AppColors.background,
                    body: Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
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

  // 新增：打开搜索
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

  // 新增：打开新增支出（改进版）
  Future<void> _openAdd() async {
    final result = await Navigator.push<ExpenseItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditExpensePage()),
    );
    if (result != null) {
      s.addExpense(result);
      AppLogger.info('Expense added: ${result.title}');
    }
  }

  // 新增：打开编辑支出
  Future<void> _editExpense(ExpenseItem expense) async {
    final result = await Navigator.push<ExpenseItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditExpensePage(existingItem: expense),
      ),
    );
    if (result != null) {
      s.updateExpense(expense.id, result);
      AppLogger.info('Expense updated: ${result.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
      DetailPage(
        state: s,
        displayMonth: _displayMonth,
        onEdit: _editExpense, // 新增：编辑回调
      ),
      InvestPage(state: s),
      ManagePage(state: s),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('錢錢管家', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          // 新增：搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppColors.gold,
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
        child: Row(
          children: [
            _NavItem(
              icon: Icons.pie_chart_rounded,
              label: '記帳',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            _NavItem(
              icon: Icons.list_alt_rounded,
              label: '明細',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.show_chart_rounded,
              label: '統計',
              selected: _tab == 2,
              onTap: () => setState(() => _tab = 2),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: '管理',
              selected: _tab == 3,
              onTap: () => setState(() => _tab = 3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Detail Page with edit support
class DetailPage extends StatefulWidget {
  final AppState state;
  final DateTime displayMonth;
  final Function(ExpenseItem)? onEdit; // 新增：编辑回调

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

  @override
  Widget build(BuildContext context) {
    var items = widget.state.monthExpenses(widget.displayMonth);
    final cats = ['全部', ...items.map((e) => e.category).toSet().toList()];
    if (_filterCat != '全部') {
      items = items.where((e) => e.category == _filterCat).toList();
    }
    final totalShown = items.fold(0, (s, e) => s + e.amount);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('明細', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                ),
                Text(
                  'NT\$ ${_fmt(totalShown)}',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
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
                      color: sel ? AppColors.gold : const Color(0xFFEDEBE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cats[i],
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('沒有記錄', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final cat = categoryOf(item.category);
                      return GestureDetector(
                        // 新增：长按编辑
                        onLongPress: () => _showItemMenu(item),
                        child: Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                          ),
                          confirmDismiss: (_) => _confirmDelete(item),
                          onDismissed: (_) => widget.state.deleteExpense(item.id),
                          child: Card(
                            elevation: 0,
                            color: AppColors.cardLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: cat.color.withValues(alpha: 0.15),
                                child: Icon(cat.icon, color: cat.color, size: 22),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.category}・${item.note.isEmpty ? "無備註" : item.note}',
                                  ),
                                  Text(DateFormat('yyyy/MM/dd').format(item.date)),
                                  // 新增：显示编辑状态
                                  if (item.isEdited)
                                    const Text(
                                      '已編輯',
                                      style: TextStyle(fontSize: 11, color: Colors.orange),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                'NT\$ ${_fmt(item.amount)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 新增：显示编辑菜单
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
                final copy = item.copyWith(
                  title: '${item.title}（副本）',
                );
                widget.state.addExpense(copy);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('刪除', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(ExpenseItem item) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除支出'),
        content: Text('確定刪除「${item.title}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF4D8ED8) : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 必需的导入（保留现有的）
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'core/constants/categories.dart';
import 'data/models/expense_item.dart';
import 'data/models/fixed_item.dart';

// ... 保留现有的 DashboardPage, InvestPage, ManagePage 等代码
// (需要将现有代码复制到这里)

String _fmt(int n) => NumberFormat('#,###').format(n);
