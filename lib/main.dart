import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'config/localization.dart';
import 'screens/auth/welcome_page.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/categories.dart';
import 'core/utils/error_handler.dart';
import 'core/utils/logger.dart';
import 'data/repositories/app_state.dart';
import 'data/models/expense_item.dart';
import 'data/models/fixed_item.dart';
import 'providers/theme_provider.dart';
import 'screens/search/search_page.dart';
import 'screens/add_edit/add_edit_expense_page.dart';
import 'screens/invest/invest_page.dart';
import 'screens/invest/add_edit_investment_page.dart';
import 'screens/manage/add_edit_fixed_page.dart';
import 'data/models/stock_holding.dart';
import 'services/backup_service.dart';
import 'services/export_service.dart';
import 'data/models/backup_metadata.dart';
import 'screens/account/account_page.dart';
import 'screens/feedback/feedback_page.dart';
import 'screens/onboarding/onboarding_service.dart';
import 'core/tour/tour_controller.dart';
import 'core/tour/tour_keys.dart';
import 'core/tour/tour_overlay.dart';
import 'config/firebase_config.dart';
import 'screens/auth/login_card.dart';
import 'package:firebase_core/firebase_core.dart';

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
    AppLogger.error('Flutter Error',
        error: details.exception, stackTrace: details.stack);
  };

  if (kFirebaseConfigured) {
    await Firebase.initializeApp(options: kFirebaseOptions);
  }

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
  final _tourController = TourController();

  @override
  void dispose() {
    _appState.dispose();
    _themeProvider.dispose();
    _tourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ListenableProvider.value(value: _appState),
        ListenableProvider.value(value: _themeProvider),
        ListenableProvider.value(value: _tourController),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '錢錢管家',
            locale: themeProvider.locale,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Consumer<AppState>(
              builder: (context, appState, _) {
                if (!appState.loaded) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: kGold),
                    ),
                  );
                }
                return _RootRouter(appState: appState);
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Root router (welcome → main) ───
class _RootRouter extends StatefulWidget {
  final AppState appState;
  const _RootRouter({required this.appState});
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool? _welcomeSeen;

  @override
  void initState() {
    super.initState();
    WelcomePage.isSeen().then((seen) {
      if (mounted) setState(() => _welcomeSeen = seen);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_welcomeSeen == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: kGold)));
    }
    if (!_welcomeSeen!) {
      return WelcomePage(
        onComplete: () => setState(() => _welcomeSeen = true),
      );
    }
    return MainShell(state: widget.appState);
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
  late final PageController _pageController = PageController();
  AppState get s => widget.state;

  final _manageScrollCtrl = ScrollController();
  OverlayEntry? _tourEntry;
  String? _pendingDetailFilter;

  void _goToDetailWithFilter(String category) {
    setState(() => _pendingDetailFilter = category);
    _goToTab(1);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTour();
      _checkOnboarding();
    });
  }

  void _initTour() {
    final ctrl = context.read<TourController>();
    final appState = context.read<AppState>();
    ctrl.init(
      goToTab: _goToTab,
      onTourStart: appState.loadDemoData,
      onTourEnd: appState.clearDemoData,
      onTourSkip: _onTourSkipped,
    );
    _tourEntry = OverlayEntry(
      builder: (_) => Consumer<TourController>(
        builder: (_, c, __) =>
            c.isActive ? const TourOverlay() : const SizedBox.shrink(),
      ),
    );
    Overlay.of(context).insert(_tourEntry!);
  }

  Future<void> _checkOnboarding() async {
    final seen = await OnboardingService.isOnboardingSeen();
    if (!seen && mounted) {
      context.read<TourController>().start();
    }
  }

  void _onRewatchOnboarding() {
    if (!mounted) return;
    context.read<TourController>().start();
  }

  Future<void> _onTourSkipped() async {
    if (!mounted) return;
    _goToTab(3);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (_manageScrollCtrl.hasClients) {
      await _manageScrollCtrl.animateTo(
        _manageScrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('可隨時在「說明與支援」重新觀看導覽'),
          backgroundColor: kGold,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tourEntry?.remove();
    _tourEntry = null;
    _pageController.dispose();
    _manageScrollCtrl.dispose();
    super.dispose();
  }

  void _goToTab(int tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    _pageController.animateToPage(
      tab,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  DateTime get _displayMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  IconData get _fabIcon => switch (_tab) {
        2 => Icons.trending_up_rounded,
        3 => Icons.playlist_add_rounded,
        _ => Icons.add,
      };

  String get _fabTooltip => switch (_tab) {
        2 => '新增投資',
        3 => '新增固定開銷',
        _ => '新增支出',
      };

  String get _monthLabel => DateFormat('M月').format(_displayMonth);

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
      MaterialPageRoute(
        builder: (_) => AddEditExpensePage(allExpenses: s.expenses),
      ),
    );
    if (result != null && mounted) {
      s.addExpense(result);
    }
  }

  Future<void> _openAddInvestment() async {
    final result = await Navigator.push<StockHolding>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditInvestmentPage()),
    );
    if (result != null && mounted) s.addHolding(result);
  }

  void _openAddFixed() => _showFixedItemDialog(context, s);

  void _fabTap() {
    final ctrl = context.read<TourController>();
    final isInteractiveFab = ctrl.isActive &&
        ctrl.isWaitingForInteraction &&
        ctrl.currentStep?.targetKey == TourKeys.fab;

    switch (_tab) {
      case 2:
        if (isInteractiveFab) {
          ctrl.hide();
          _openAddInvestment().then((_) {
            if (mounted) ctrl.onInteractionComplete();
          });
        } else {
          _openAddInvestment();
        }
      case 3:
        _openAddFixed();
      default:
        if (isInteractiveFab) {
          ctrl.hide();
          _openAdd().then((_) {
            if (mounted) ctrl.onInteractionComplete();
          });
        } else {
          _openAdd();
        }
    }
  }

  Future<void> _editExpense(ExpenseItem expense) async {
    final result = await Navigator.push<ExpenseItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditExpensePage(
          existingItem: expense,
          allExpenses: s.expenses,
        ),
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
        onGoDetail: () => _goToTab(1),
        onGoCategory: _goToDetailWithFilter,
      ),
      DetailPage(
        state: s,
        displayMonth: _displayMonth,
        onEdit: _editExpense,
        initialFilter: _pendingDetailFilter,
        onFilterApplied: () => setState(() => _pendingDetailFilter = null),
      ),
      InvestPage(state: s),
      ManagePage(
        state: s,
        scrollController: _manageScrollCtrl,
        onRewatchOnboarding: _onRewatchOnboarding,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('錢錢管家',
            key: TourKeys.appBarTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _tab = i),
        children: pages.map((p) => _KeepAlivePage(child: p)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        key: TourKeys.fab,
        onPressed: _fabTap,
        backgroundColor: kGold,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        tooltip: _fabTooltip,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(_fabIcon, key: ValueKey(_tab), size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 70,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: Row(children: [
          _NavItem(
              icon: Icons.pie_chart_rounded,
              label: '記帳',
              selected: _tab == 0,
              onTap: () => _goToTab(0)),
          _NavItem(
              icon: Icons.list_alt_rounded,
              label: '明細',
              selected: _tab == 1,
              onTap: () => _goToTab(1)),
          const SizedBox(width: 56),
          _NavItem(
              icon: Icons.candlestick_chart_rounded,
              label: '投資',
              selected: _tab == 2,
              onTap: () => _goToTab(2)),
          _NavItem(
              key: TourKeys.navManage,
              icon: Icons.settings_rounded,
              label: '管理',
              selected: _tab == 3,
              onTap: () => _goToTab(3)),
        ]),
      ),
    );
  }
}

// ─── 首頁 ───
enum _ChartPeriod { month, bimonth, halfYear }

class DashboardPage extends StatefulWidget {
  final AppState state;
  final DateTime displayMonth;
  final String monthLabel;
  final VoidCallback onPrev, onCur, onNext, onGoDetail;
  final void Function(String category)? onGoCategory;
  const DashboardPage(
      {super.key,
      required this.state,
      required this.displayMonth,
      required this.monthLabel,
      required this.onPrev,
      required this.onCur,
      required this.onNext,
      required this.onGoDetail,
      this.onGoCategory});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _includeFixed = true;
  _ChartPeriod _chartPeriod = _ChartPeriod.month;

  AppState get state => widget.state;
  DateTime get displayMonth => widget.displayMonth;
  String get monthLabel => widget.monthLabel;
  VoidCallback get onPrev => widget.onPrev;
  VoidCallback get onCur => widget.onCur;
  VoidCallback get onNext => widget.onNext;
  VoidCallback get onGoDetail => widget.onGoDetail;

  List<DateTime> _chartMonths() {
    final count = switch (_chartPeriod) {
      _ChartPeriod.month => 1,
      _ChartPeriod.bimonth => 2,
      _ChartPeriod.halfYear => 6,
    };
    return List.generate(count,
        (i) => DateTime(displayMonth.year, displayMonth.month - i, 1));
  }

  List<DateTime> _prevChartMonths() {
    final months = _chartMonths();
    final oldest = months.last;
    return List.generate(months.length,
        (i) => DateTime(oldest.year, oldest.month - 1 - i, 1));
  }

  String get _periodLabel => switch (_chartPeriod) {
        _ChartPeriod.month => '本月',
        _ChartPeriod.bimonth => '本雙月',
        _ChartPeriod.halfYear => '本半年',
      };

  Widget _buildSummaryText(
      BuildContext context, int total, int prevTotal) {
    final diff = total - prevTotal;
    final cs = Theme.of(context).colorScheme;
    final baseStyle = TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5);
    return RichText(
      text: TextSpan(style: baseStyle, children: [
        TextSpan(text: '$_periodLabel的總消費為 '),
        TextSpan(
            text: 'NT\$ ${_fmt(total)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: kGold)),
        if (prevTotal > 0) ...[
          TextSpan(text: '，較上期'),
          TextSpan(
            text: diff >= 0 ? '增加' : '減少',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: diff >= 0 ? kRed : kGreen),
          ),
          TextSpan(
            text: ' NT\$ ${_fmt(diff.abs())}',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: diff >= 0 ? kRed : kGreen),
          ),
        ],
      ]),
    );
  }

  void _showAnnualSummary(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, i + 1, 1));
    final monthlyTotals = months.map((m) => state.usedTotal(m)).toList();
    final annualTotal = monthlyTotals.fold(0, (s, v) => s + v);
    final annualBudget = state.budget * 12;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${now.year} 年度總覽',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _AnnualStat(
                        label: '年度支出',
                        value: 'NT\$ ${_fmt(annualTotal)}',
                        color: annualTotal > annualBudget ? kRed : kGreen)),
                Expanded(
                    child: _AnnualStat(
                        label: '年度預算',
                        value: 'NT\$ ${_fmt(annualBudget)}',
                        color: kGold)),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (annualTotal / annualBudget).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                      annualTotal > annualBudget ? kRed : kGreen),
                ),
              ),
              const SizedBox(height: 20),
              const Text('各月支出',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              ...List.generate(12, (i) {
                final v = monthlyTotals[i];
                if (v == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    SizedBox(
                        width: 36,
                        child: Text('${i + 1}月',
                            style: const TextStyle(
                                color: kGray, fontWeight: FontWeight.w600))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (v / (state.budget > 0 ? state.budget : 1))
                              .clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                              v > state.budget ? kRed : kGold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('NT\$ ${_fmt(v)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                );
              }),
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic_ = state.dynamicTotal(displayMonth);
    final used = _includeFixed ? state.usedTotal(displayMonth) : dynamic_;
    final remain = state.budget - used;
    final rate = (used / (state.budget > 0 ? state.budget : 1)).clamp(0.0, 1.0);
    final pct = (rate * 100).round();
    final now = DateTime.now();
    final days =
        (now.year == displayMonth.year && now.month == displayMonth.month)
            ? max(1, now.day)
            : 30;
    final lastDay = DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final daysLeft =
        (now.year == displayMonth.year && now.month == displayMonth.month)
            ? max(1, lastDay - now.day + 1)
            : lastDay;
    final daily = (dynamic_ / days).round();
    final rec = (remain / daysLeft).round();
    final over = remain < 0;

    // Chart section — computed from _chartPeriod, independent of displayMonth budget
    final chartCatMap = <String, int>{};
    for (final m in _chartMonths()) {
      for (final e in state.categoryTotals(m).entries) {
        chartCatMap[e.key] = (chartCatMap[e.key] ?? 0) + e.value;
      }
    }
    final chartTotal =
        chartCatMap.values.fold(0, (s, v) => s + v);
    int prevTotal = 0;
    for (final m in _prevChartMonths()) {
      prevTotal +=
          state.categoryTotals(m).values.fold(0, (s, v) => s + v);
    }
    int chartCount = 0;
    for (final m in _chartMonths()) {
      chartCount += state
          .monthExpenses(m)
          .where((e) => e.type == TransactionType.expense)
          .length;
    }
    final sortedCatEntries = chartCatMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('記帳',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // 月份切換
          _AppCard(
              key: TourKeys.monthCard,
              child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Tooltip(
                message: '每天記帳可維持連續天數',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.recordedToday
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(state.recordedToday ? '🔥' : '⚠️',
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      state.recordedToday
                          ? '連續記帳 ${state.streak} 天'
                          : '今天還沒記帳（${state.streak} 天）',
                      style: TextStyle(
                        color: state.recordedToday
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Builder(builder: (_) {
              final n = DateTime.now();
              final prevM = DateTime(n.year, n.month - 1, 1);
              final thisM = DateTime(n.year, n.month, 1);
              final nextM = DateTime(n.year, n.month + 1, 1);
              bool sameM(DateTime a, DateTime b) =>
                  a.year == b.year && a.month == b.month;
              return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _MonthBtn(
                    label: '上月',
                    subText: DateFormat('M月').format(prevM),
                    selected: sameM(displayMonth, prevM),
                    onTap: onPrev),
                const SizedBox(width: 10),
                _MonthBtn(
                    label: '本月',
                    subText: DateFormat('M月').format(thisM),
                    selected: sameM(displayMonth, thisM),
                    onTap: onCur),
                const SizedBox(width: 10),
                _MonthBtn(
                    label: '下月',
                    subText: DateFormat('M月').format(nextM),
                    selected: sameM(displayMonth, nextM),
                    onTap: onNext),
              ]);
            }),
          ])),
          const SizedBox(height: 16),

          // 預算進度
          _AppCard(
              key: TourKeys.budgetCard,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${DateFormat('yyyy/MM').format(displayMonth)} 預算進度',
                              style: const TextStyle(
                                  color: kGray,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _includeFixed = !_includeFixed),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _includeFixed
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _includeFixed
                                          ? Icons.toggle_on_rounded
                                          : Icons.toggle_off_rounded,
                                      size: 16,
                                      color: _includeFixed
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '含固定開銷',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _includeFixed
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        ]),
                  ),
                  Text('NT\$ ${_fmt(used)}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  Text(' / ${_fmt(state.budget)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ]),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: rate),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(over ? kRed : kGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('$pct%',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: over ? kRed : kGreen)),
                ),
                const Divider(height: 20),
                Row(children: [
                  Expanded(
                      child: _BudgetStat(
                          label: '日均支出', value: 'NT\$ ${_fmt(daily)}')),
                  Expanded(
                      child: _BudgetStat(
                          label: '建議日均',
                          value: 'NT\$ ${_fmt(rec.clamp(0, 9999999))}',
                          valueColor: rec < 0 ? kRed : kGreen,
                          alignEnd: true)),
                ]),
                const SizedBox(height: 14),
                const Text('剩餘預算',
                    style: TextStyle(
                        color: kGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('NT\$ ${_fmt(remain)}',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: over ? kRed : kGreen)),
              ])),
          const SizedBox(height: 16),

          // 支出分析
          _AppCard(
              key: TourKeys.categoryCard,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // ── Header ──────────────────────────────────────────
                Row(children: [
                  const Text('支出分析',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showAnnualSummary(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: kGold,
                          borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('年度',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ]),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onGoDetail,
                    child: const Row(children: [
                      Text('查看更多',
                          style: TextStyle(color: kGray, fontSize: 13)),
                      Icon(Icons.chevron_right, color: kGray, size: 18),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── Period selector ─────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _PeriodChip(
                      label: '本月',
                      selected: _chartPeriod == _ChartPeriod.month,
                      onTap: () => setState(
                          () => _chartPeriod = _ChartPeriod.month)),
                  const SizedBox(width: 8),
                  _PeriodChip(
                      label: '雙月',
                      selected: _chartPeriod == _ChartPeriod.bimonth,
                      onTap: () => setState(
                          () => _chartPeriod = _ChartPeriod.bimonth)),
                  const SizedBox(width: 8),
                  _PeriodChip(
                      label: '半年',
                      selected: _chartPeriod == _ChartPeriod.halfYear,
                      onTap: () => setState(
                          () => _chartPeriod = _ChartPeriod.halfYear)),
                ]),
                const SizedBox(height: 14),

                // ── Summary text ────────────────────────────────────
                if (chartTotal > 0)
                  _buildSummaryText(context, chartTotal, prevTotal),
                if (chartTotal > 0) const SizedBox(height: 16),

                // ── Empty state ─────────────────────────────────────
                if (chartTotal == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text('新增支出後顯示圖表',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 15)),
                    ),
                  )
                else ...[
                  // ── Centered Donut ───────────────────────────────
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox.expand(
                          child: _DoughnutChart(catMap: chartCatMap),
                        ),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('$chartCount',
                              style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: kGold)),
                          Text('筆消費',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Category list ────────────────────────────────
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  ...sortedCatEntries.map((e) {
                    final cat = categoryOf(e.key);
                    final pct = chartTotal > 0
                        ? e.value / chartTotal * 100
                        : 0.0;
                    return _CategoryRow(
                      cat: cat,
                      name: e.key,
                      pct: pct,
                      amount: e.value,
                      onTap: () =>
                          widget.onGoCategory?.call(e.key),
                    );
                  }),
                ],
              ])),
        ]),
      ),
    );
  }
}

// ─── 明細頁 ───
enum _DetailTypeFilter { all, expense, income }

class DetailPage extends StatefulWidget {
  final AppState state;
  final DateTime displayMonth;
  final Function(ExpenseItem)? onEdit;
  final String? initialFilter;
  final VoidCallback? onFilterApplied;

  const DetailPage({
    super.key,
    required this.state,
    required this.displayMonth,
    this.onEdit,
    this.initialFilter,
    this.onFilterApplied,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String _filterCat = '全部';
  _DetailTypeFilter _typeFilter = _DetailTypeFilter.all;

  @override
  void didUpdateWidget(DetailPage old) {
    super.didUpdateWidget(old);
    final f = widget.initialFilter;
    if (f != null && f != old.initialFilter) {
      setState(() {
        _filterCat = f;
        _typeFilter = _DetailTypeFilter.expense;
      });
      widget.onFilterApplied?.call();
    }
  }

  void _deleteWithUndo(ExpenseItem item) {
    final originalIndex = widget.state.deleteExpense(item.id);
    ErrorHandler.showUndoSnack(
      context,
      '已刪除「${item.title}」',
      () => widget.state.insertExpenseAt(originalIndex, item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMonthItems = widget.state.monthExpenses(widget.displayMonth);
    // Apply type filter
    final typeFiltered = switch (_typeFilter) {
      _DetailTypeFilter.income => allMonthItems.where((e) => e.type == TransactionType.income).toList(),
      _DetailTypeFilter.expense => allMonthItems.where((e) => e.type == TransactionType.expense).toList(),
      _DetailTypeFilter.all => allMonthItems,
    };
    final cats = ['全部', ...typeFiltered.map((e) => e.category).toSet().toList()];
    final effectiveCat = cats.contains(_filterCat) ? _filterCat : '全部';
    var items = effectiveCat != '全部'
        ? typeFiltered.where((e) => e.category == effectiveCat).toList()
        : typeFiltered;
    final incomeShown = items
        .where((e) => e.type == TransactionType.income)
        .fold(0, (s, e) => s + e.amount);
    final expenseShown = items
        .where((e) => e.type == TransactionType.expense)
        .fold(0, (s, e) => s + e.amount);
    final netShown = incomeShown - expenseShown;

    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Row(children: [
            const Text('明細',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
                '${netShown >= 0 ? "+" : "-"}NT\$ ${_fmt(netShown.abs())}',
                style: TextStyle(
                    color: netShown >= 0 ? kGreen : kRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 10),
        // 月份 + 類型篩選
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('yyyy/MM').format(widget.displayMonth),
                style: const TextStyle(
                    color: kGold, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            _DetailTypeChip(
              label: '全部',
              selected: _typeFilter == _DetailTypeFilter.all,
              onTap: () => setState(() { _typeFilter = _DetailTypeFilter.all; _filterCat = '全部'; }),
            ),
            const SizedBox(width: 6),
            _DetailTypeChip(
              label: '支出',
              selected: _typeFilter == _DetailTypeFilter.expense,
              color: kRed,
              onTap: () => setState(() { _typeFilter = _DetailTypeFilter.expense; _filterCat = '全部'; }),
            ),
            const SizedBox(width: 6),
            _DetailTypeChip(
              label: '收入',
              selected: _typeFilter == _DetailTypeFilter.income,
              color: kGreen,
              onTap: () => setState(() { _typeFilter = _DetailTypeFilter.income; _filterCat = '全部'; }),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // 分類篩選
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = cats[i] == effectiveCat;
              return GestureDetector(
                onTap: () => setState(() => _filterCat = cats[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? kGold
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cats[i],
                      style: TextStyle(
                          color: sel ? Colors.white : cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            key: TourKeys.detailList,
            child: items.isEmpty
              ? const Center(
                  child: Text('沒有記錄', style: TextStyle(color: Colors.grey)))
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
                          decoration: BoxDecoration(
                              color: kRed,
                              borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 26),
                        ),
                        onDismissed: (_) => _deleteWithUndo(item),
                        child: Card(
                          elevation: 0,
                          color:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: cat.color.withOpacity(0.15),
                              child: Icon(cat.icon, color: cat.color, size: 22),
                            ),
                            title: Text(item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${item.category}・${item.note.isEmpty ? "無備註" : item.note}'),
                                Text(
                                    DateFormat('yyyy/MM/dd').format(item.date)),
                                if (item.isEdited)
                                  const Text('已編輯',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.orange)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Text(
                                '${item.type == TransactionType.income ? "+" : "-"}NT\$ ${_fmt(item.amount)}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: item.type == TransactionType.income
                                        ? kGreen
                                        : kRed)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ),  // Container(key: TourKeys.detailList)
        ),
      ]),
    );
  }

  void _showItemMenu(ExpenseItem item) {
    final ctrl = context.read<TourController>();
    final isLongPressStep = ctrl.isActive &&
        ctrl.isWaitingForInteraction &&
        ctrl.currentStep?.targetKey == TourKeys.detailList;

    final future = showModalBottomSheet<dynamic>(
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
                widget.state
                    .addExpense(item.copyWith(title: '${item.title}（副本）'));
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

    if (isLongPressStep) {
      future.then((_) {
        if (mounted) ctrl.onInteractionComplete();
      });
    }
  }
}

// ─── 管理頁 ───
class ManagePage extends StatefulWidget {
  final AppState state;
  final ScrollController? scrollController;
  final VoidCallback? onRewatchOnboarding;
  const ManagePage({
    super.key,
    required this.state,
    this.scrollController,
    this.onRewatchOnboarding,
  });
  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  late final TextEditingController _budgetCtrl;
  final _backupService = BackupService();
  final _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _budgetCtrl = TextEditingController(text: widget.state.budget.toString());
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _doBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 過濾 demo 資料，不備份進正式備份檔
      const demoPrefix = 'tour_demo_';
      final filename = await _backupService.exportBackup(
        expenses: widget.state.expenses
            .where((e) => !e.id.startsWith(demoPrefix))
            .toList(),
        fixedItems: widget.state.fixedItems
            .where((f) => !f.id.startsWith(demoPrefix))
            .toList(),
        accounts: widget.state.accounts
            .where((a) => !a.id.startsWith(demoPrefix))
            .toList(),
        holdings: widget.state.holdings
            .where((h) => !h.id.startsWith(demoPrefix))
            .toList(),
        budget: widget.state.budget,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('✓ 備份已儲存：$filename'), backgroundColor: kGreen),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('備份失敗：$e'), backgroundColor: kRed),
      );
    }
  }

  Future<void> _doExportCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final filename = await _exportService.exportExpensesAsCsv(
        expenses: widget.state.expenses,
        title: '支出記錄',
      );
      messenger.showSnackBar(
        SnackBar(content: Text('✓ CSV 已匯出：$filename'), backgroundColor: kGreen),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('匯出失敗：$e'), backgroundColor: kRed),
      );
    }
  }

  Future<void> _doExportExcel() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final filename = await _exportService.exportFullReportAsExcel(
        expenses: widget.state.expenses,
        fixedItems: widget.state.fixedItems,
        budget: widget.state.budget,
        month: DateTime.now(),
      );
      messenger.showSnackBar(
        SnackBar(
            content: Text('✓ Excel 已匯出：$filename'), backgroundColor: kGreen),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('匯出失敗：$e'), backgroundColor: kRed),
      );
    }
  }

  Future<void> _doRestore() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backups = await _backupService.getBackupList();
      if (backups.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('尚無備份檔案'), backgroundColor: kGray),
        );
        return;
      }
      if (!mounted) return;
      final selectedFilename = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _BackupPickerSheet(backups: backups),
      );
      if (selectedFilename == null || !mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('確定還原？'),
          content: const Text('現有所有資料（支出、固定開銷、帳戶、投資）將被備份內容完整取代，此操作無法還原。'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('還原',
                  style: TextStyle(color: kGold, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final backupData = await _backupService.importBackup(selectedFilename);
      widget.state.restoreFromBackup(
        newExpenses: backupData.expenses,
        newFixedItems: backupData.fixedItems,
        newAccounts: backupData.accounts,
        newHoldings: backupData.holdings,
        newBudget: backupData.settings?['budget'] as int?,
      );
      if (!mounted) return;
      if (backupData.isLegacy) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              '⚠ 舊版備份已還原。此備份不含帳戶與投資資料，帳戶已清空，請重新建立或手動校正餘額。',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '✓ 已還原 ${backupData.expenses.length} 筆支出、'
              '${backupData.accounts.length} 個帳戶、'
              '${backupData.holdings.length} 筆持股',
            ),
            backgroundColor: kGreen,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('還原失敗：$e'), backgroundColor: kRed),
      );
    }
  }

  void _openFixedDialog({FixedItem? existing}) =>
      _showFixedItemDialog(context, widget.state, existing: existing);

  void _addFixed() => _openFixedDialog();

  String _localeDisplayName(Locale locale) {
    switch ('${locale.languageCode}_${locale.countryCode}') {
      case 'zh_TW':
        return '繁體中文 (Traditional Chinese)';
      case 'zh_CN':
        return '简体中文 (Simplified Chinese)';
      case 'en_US':
        return 'English';
      case 'ja_JP':
        return '日本語 (Japanese)';
      default:
        return '繁體中文 (Traditional Chinese)';
    }
  }

  void _showLanguagePicker(BuildContext context, ThemeProvider themeProvider) {
    final options = [
      (const Locale('zh', 'TW'), '繁體中文', 'Traditional Chinese'),
      (const Locale('zh', 'CN'), '简体中文', 'Simplified Chinese'),
      (const Locale('en', 'US'), 'English', ''),
      (const Locale('ja', 'JP'), '日本語', 'Japanese'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('語言 / Language',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ...options.map((o) {
            final isSelected = themeProvider.locale == o.$1;
            return ListTile(
              title: Text(o.$2,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? kGold : null)),
              subtitle:
                  o.$3.isNotEmpty ? Text(o.$3, style: const TextStyle(fontSize: 12)) : null,
              trailing: isSelected
                  ? const Icon(Icons.check_rounded, color: kGold)
                  : null,
              onTap: () {
                themeProvider.setLocale(o.$1);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SafeArea(
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('管理',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),

          // Gmail 登入卡片
          const LoginCard(),

          // 我的帳戶 — 核心功能入口
          GestureDetector(
            key: TourKeys.accountCard,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AccountPage(state: widget.state))),
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: kGold.withValues(alpha: 0.35), width: 1.5),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: kGold,
                        size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('我的帳戶',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      ListenableBuilder(
                        listenable: widget.state,
                        builder: (_, __) => Text(
                          '${widget.state.accounts.length} 個帳戶',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('管理',
                          style: TextStyle(
                              color: kGold,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, color: kGold, size: 15),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (_, __) {
                    final net = widget.state.netAssets;
                    final assets = widget.state.totalAssets;
                    final liabilities = widget.state.totalLiabilities;
                    final isNeg = net < 0;
                    final cs = Theme.of(context).colorScheme;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        'NT\$ ${NumberFormat('#,##0', 'en_US').format(net.round())}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isNeg ? kRed : cs.onSurface,
                        ),
                      ),
                      const Text('淨資產',
                          style: TextStyle(
                              color: kGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('資產',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                'NT\$ ${NumberFormat('#,##0', 'en_US').format(assets.round())}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kGreen),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('負債',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                'NT\$ ${NumberFormat('#,##0', 'en_US').format(liabilities.round())}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: liabilities > 0
                                        ? kRed
                                        : cs.onSurfaceVariant),
                              ),
                            ]),
                          ),
                        ),
                      ]),
                    ]);
                  },
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // 外觀設定
          _AppCard(
              child: Row(children: [
            const Icon(Icons.dark_mode_rounded, color: kGold),
            const SizedBox(width: 12),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('深色模式',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('切換深色/淺色介面',
                      style: TextStyle(color: kGray, fontSize: 12)),
                ])),
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeColor: kGold,
            ),
          ])),
          const SizedBox(height: 16),

          // 語言設定
          _AppCard(
              child: InkWell(
            onTap: () => _showLanguagePicker(context, themeProvider),
            borderRadius: BorderRadius.circular(22),
            child: Row(children: [
              const Icon(Icons.language_rounded, color: kGold),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('語言 / Language',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(_localeDisplayName(themeProvider.locale),
                        style: const TextStyle(color: kGray, fontSize: 12)),
                  ])),
              const Icon(Icons.chevron_right, color: kGray, size: 18),
            ]),
          )),
          const SizedBox(height: 16),

          // 月預算
          _AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('月預算',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _budgetCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        prefixText: 'NT\$ ',
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: kGold, width: 1.5)),
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
                            const SnackBar(
                                content: Text('✓ 預算已更新'),
                                backgroundColor: kGreen,
                                duration: Duration(seconds: 2)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text('更新',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ])),
          const SizedBox(height: 16),

          // 固定開銷
          _AppCard(
              key: TourKeys.fixedCard,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Expanded(
                      child: Text('固定開銷',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700))),
                  Text('每月 NT\$ ${_fmt(widget.state.fixedTotal)}',
                      style: const TextStyle(
                          color: kGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addFixed,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add, color: kGold, size: 18),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                if (widget.state.fixedItems.isEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('點右上角 + 新增固定開銷',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant))),
                ...widget.state.fixedItems.map((f) {
                  final now = DateTime.now();
                  final completed = f.isCompleted;
                  final remaining = f.remainingPeriods(now);
                  final cs = Theme.of(context).colorScheme;
                  return Dismissible(
                    key: Key(f.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                          color: kRed, borderRadius: BorderRadius.circular(12)),
                      child:
                          const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => widget.state.deleteFixed(f.id),
                    child: GestureDetector(
                      onLongPress: () => _openFixedDialog(existing: f),
                      child: Opacity(
                        opacity: completed ? 0.45 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                              color: cs.surfaceContainer,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.receipt_long,
                                      color: completed
                                          ? cs.onSurfaceVariant
                                          : kGold,
                                      size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(f.title,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: completed
                                                  ? cs.onSurfaceVariant
                                                  : cs.onSurface))),
                                  Text('NT\$ ${_fmt(f.amount)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _openFixedDialog(existing: f),
                                    child: const Icon(Icons.edit_outlined,
                                        color: kGold, size: 18),
                                  ),
                                ]),
                                if (f.totalPeriods != null) ...[
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const SizedBox(width: 28),
                                    if (completed)
                                      Text('已完成全部 ${f.totalPeriods} 期',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurfaceVariant))
                                    else ...[
                                      Text(
                                        '${DateFormat('yyyy/MM').format(f.startDate)} 起・共 ${f.totalPeriods} 期',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: kGold.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text('剩 $remaining 期',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: kGold,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ]),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: completed
                                          ? 1.0
                                          : (f.totalPeriods! -
                                                  (remaining ?? 0)) /
                                              f.totalPeriods!,
                                      minHeight: 4,
                                      backgroundColor:
                                          cs.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(
                                          completed
                                              ? cs.onSurfaceVariant
                                              : kGold),
                                    ),
                                  ),
                                ],
                              ]),
                        ),
                      ),
                    ),
                  );
                }),
              ])),
          const SizedBox(height: 16),

          // 備份與匯出
          _AppCard(
              key: TourKeys.backupCard,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('備份與匯出',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _doBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('備份資料'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _doExportCsv,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('匯出 CSV'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kGold),
                      foregroundColor: kGold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _doExportExcel,
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('匯出 Excel'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kGold),
                      foregroundColor: kGold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _doRestore,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('恢復備份'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kGold),
                      foregroundColor: kGold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ])),
          const SizedBox(height: 16),

          // 危險區
          _AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('危險區',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kRed)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('確定清除？'),
                          content: const Text('所有支出記錄將被永久刪除，無法還原。'),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('清除',
                                    style: TextStyle(
                                        color: kRed,
                                        fontWeight: FontWeight.w700))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        widget.state.clearAll();
                        messenger.showSnackBar(
                            const SnackBar(content: Text('所有記錄已清除')));
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: kRed),
                    label:
                        const Text('清除所有支出記錄', style: TextStyle(color: kRed)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ])),
          const SizedBox(height: 16),

          // 說明與支援
          _AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('說明與支援',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ListTile(
                  key: TourKeys.rewatchTile,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline_rounded, color: kGold),
                  title: const Text('重新觀看新手導覽',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('再次查看錢錢管家的主要功能與使用方式',
                      style: TextStyle(fontSize: 12)),
                  trailing:
                      const Icon(Icons.chevron_right, color: kGray, size: 18),
                  onTap: widget.onRewatchOnboarding,
                ),
                const Divider(height: 1),
                ListTile(
                  key: TourKeys.feedbackTile,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.feedback_outlined, color: kGold),
                  title: const Text('回報問題與建議',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('問題回報、功能建議或使用感受',
                      style: TextStyle(fontSize: 12)),
                  trailing:
                      const Icon(Icons.chevron_right, color: kGray, size: 18),
                  onTap: () {
                    final ctrl = context.read<TourController>();
                    final isFeedbackStep = ctrl.isActive &&
                        ctrl.isWaitingForInteraction &&
                        ctrl.currentStep?.targetKey == TourKeys.feedbackTile;
                    if (isFeedbackStep) ctrl.hide();
                    final future = Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FeedbackPage()),
                    );
                    if (isFeedbackStep) {
                      future.then((_) {
                        if (context.mounted) ctrl.onInteractionComplete();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── 小元件 ───
class _AppCard extends StatelessWidget {
  final Widget child;
  const _AppCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );
}

class _MonthBtn extends StatelessWidget {
  final String label;
  final String subText;
  final bool selected;
  final VoidCallback onTap;
  const _MonthBtn(
      {required this.label,
      required this.subText,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kGold : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: selected ? Colors.white.withValues(alpha: 0.85) : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text(subText,
              style: TextStyle(
                  color: selected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ]),
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool alignEnd;
  const _BudgetStat(
      {required this.label,
      required this.value,
      this.valueColor,
      this.alignEnd = false});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: kGray, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color:
                      valueColor ?? Theme.of(context).colorScheme.onSurface)),
        ],
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF4D8ED8) : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── 明細類型篩選 chip ───
class _DetailTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _DetailTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? kGold;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── 分析圖表元件 ───
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? kGold
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      );
}

class _CategoryRow extends StatelessWidget {
  final Category cat;
  final String name;
  final double pct;
  final int amount;
  final VoidCallback? onTap;
  const _CategoryRow({
    required this.cat,
    required this.name,
    required this.pct,
    required this.amount,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14))),
            Text('NT\$ ${_fmt(amount)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(width: 10),
            SizedBox(
              width: 46,
              child: Text('${pct.toStringAsFixed(1)}%',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ]),
        ),
      );
}

// ─── 環形圖 ───
class _DoughnutChart extends StatelessWidget {
  final Map<String, int> catMap;
  const _DoughnutChart({required this.catMap});
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DoughnutPainter(
          catMap: catMap,
          trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Center(),
      );
}

class _DoughnutPainter extends CustomPainter {
  final Map<String, int> catMap;
  final Color trackColor;
  _DoughnutPainter({required this.catMap, required this.trackColor});
  @override
  void paint(Canvas canvas, Size size) {
    final total = catMap.values.fold<int>(0, (s, v) => s + v).toDouble();
    if (total == 0) return;
    const sw = 40.0;
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) - sw;
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    double start = -pi / 2;
    const gap = 0.07;
    for (final e in catMap.entries) {
      final sweep = (e.value / total) * 2 * pi - gap;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        sweep,
        false,
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
  bool shouldRepaint(_DoughnutPainter o) =>
      o.catMap != catMap || o.trackColor != trackColor;
}

class _AnnualStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AnnualStat(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: kGray, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]);
}

// ─── 工具函式 ───
String _fmt(int n) => NumberFormat('#,###').format(n);

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _BackupPickerSheet extends StatelessWidget {
  final List<BackupMetadata> backups;
  const _BackupPickerSheet({required this.backups});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('選擇備份',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 8),
          ...backups.map((b) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_rounded, color: kGold),
                title: Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(b.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${b.expenseCount} 筆支出・${b.fixedCount} 項固定開銷'),
                onTap: () => Navigator.pop(context, b.filename),
              )),
        ],
      ),
    );
  }
}

void _showFixedItemDialog(BuildContext context, AppState state,
    {FixedItem? existing}) async {
  final result = await Navigator.push<FixedItem>(
    context,
    MaterialPageRoute(
      builder: (_) => AddEditFixedPage(existing: existing),
      fullscreenDialog: true,
    ),
  );
  if (result == null) return;
  if (existing != null) {
    state.updateFixed(existing.id, result);
  } else {
    state.addFixed(result);
  }
}
