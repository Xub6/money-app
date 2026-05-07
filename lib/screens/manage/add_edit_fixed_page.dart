import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fixed_item.dart';
import '../../data/models/account.dart';
import '../../data/repositories/app_state.dart';

class AddEditFixedPage extends StatefulWidget {
  final FixedItem? existing;
  const AddEditFixedPage({super.key, this.existing});

  @override
  State<AddEditFixedPage> createState() => _AddEditFixedPageState();
}

class _AddEditFixedPageState extends State<AddEditFixedPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amtCtrl;
  late final TextEditingController _periodsCtrl;
  late final TextEditingController _notesCtrl;

  late DateTime _startMonth;
  bool _hasPeriods = false;
  String? _selectedAccountId;
  String? _selectedDebtAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amtCtrl =
        TextEditingController(text: e != null ? e.amount.toString() : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _selectedAccountId = e?.accountId;
    _selectedDebtAccountId = e?.linkedDebtAccountId;

    final now = DateTime.now();
    final sd = e?.startDate ?? now;
    _startMonth = DateTime(sd.year, sd.month);

    if (e?.totalPeriods != null) {
      _hasPeriods = true;
      _periodsCtrl = TextEditingController(text: e!.totalPeriods.toString());
    } else {
      _periodsCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amtCtrl.dispose();
    _periodsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _endMonthLabel {
    final n = int.tryParse(_periodsCtrl.text.trim());
    if (n == null || n <= 0) return '—';
    final end = DateTime(_startMonth.year, _startMonth.month + n - 1);
    return DateFormat('yyyy/MM').format(end);
  }

  String get _startMonthLabel => DateFormat('yyyy/MM').format(_startMonth);

  Future<void> _pickStartMonth() async {
    int selectedYear = _startMonth.year;
    int selectedMonth = _startMonth.month;

    final now = DateTime.now();
    final yearCtrl = FixedExtentScrollController(
        initialItem: selectedYear - (now.year - 10));
    final monthCtrl =
        FixedExtentScrollController(initialItem: selectedMonth - 1);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, ss) {
          return SizedBox(
            height: 300,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Text(AppLocalizations.of(context, 'select_month'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startMonth = DateTime(selectedYear, selectedMonth);
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(AppLocalizations.of(context, 'confirm'),
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Expanded(
                child: Row(children: [
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: yearCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) =>
                          selectedYear = now.year - 10 + i,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 21,
                        builder: (ctx, i) {
                          final y = now.year - 10 + i;
                          return Center(
                            child: Text(
                                AppLocalizations.ofParam(
                                    context, 'year_label', {'year': y}),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListWheelScrollView(
                      controller: monthCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => selectedMonth = i + 1,
                      children: List.generate(
                        12,
                        (i) => Center(
                          child: Text(
                              AppLocalizations.ofParam(
                                  context, 'month_label', {'month': i + 1}),
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        });
      },
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amt = int.tryParse(_amtCtrl.text.trim());
    if (title.isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context, 'please_fill_name_amount'))),
      );
      return;
    }

    int? periods;
    if (_hasPeriods) {
      periods = int.tryParse(_periodsCtrl.text.trim());
      if (periods == null || periods <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(
                  context, 'please_enter_valid_periods'))),
        );
        return;
      }
    }

    final now = DateTime.now();
    final result = FixedItem(
      id: widget.existing?.id,
      title: title,
      amount: amt,
      startDate: _startMonth,
      totalPeriods: periods,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      editedAt: widget.existing != null ? now : null,
      accountId: _selectedAccountId,
      linkedDebtAccountId: _selectedDebtAccountId,
    );

    Navigator.pop(context, result);
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _row({
    required String label,
    required Widget child,
    bool topBorder = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topBorder)
          Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
              indent: 16,
              endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            Expanded(child: child),
          ]),
        ),
      ],
    );
  }

  /// Account selector row — shows savings accounts for debit, credit accounts for debt.
  Widget _accountSelectorRow({
    required String label,
    required List<Account> options,
    required String? selected,
    required void Function(String?) onChanged,
    bool topBorder = false,
    bool allowNone = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selectedAccount =
        options.where((a) => a.id == selected).firstOrNull;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (topBorder)
        Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.35),
            indent: 16,
            endIndent: 16),
      InkWell(
        onTap: () => _showAccountPicker(
          options: options,
          selected: selected,
          allowNone: allowNone,
          onPicked: onChanged,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              selectedAccount?.displayName ?? AppLocalizations.of(context, 'not_selected'),
              style: TextStyle(
                fontSize: 14,
                color: selected != null ? AppColors.gold : cs.onSurfaceVariant,
                fontWeight: selected != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
          ]),
        ),
      ),
    ]);
  }

  void _showAccountPicker({
    required List<Account> options,
    required String? selected,
    required bool allowNone,
    required void Function(String?) onPicked,
  }) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        if (allowNone)
          ListTile(
            leading: const Text('—', style: TextStyle(fontSize: 18)),
            title: Text(AppLocalizations.of(context, 'not_linked'),
                style: TextStyle(color: cs.onSurface)),
            trailing: selected == null
                ? Icon(Icons.check, color: AppColors.gold)
                : null,
            onTap: () {
              onPicked(null);
              setState(() {});
              Navigator.pop(ctx);
            },
          ),
        ...options.map((a) => ListTile(
              leading: Text(a.icon ?? '💳',
                  style: const TextStyle(fontSize: 20)),
              title: Text(a.displayName,
                  style: TextStyle(color: cs.onSurface)),
              subtitle: Text(
                '${a.currencySymbol} ${a.balance.toStringAsFixed(0)}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              trailing: selected == a.id
                  ? Icon(Icons.check, color: AppColors.gold)
                  : null,
              onTap: () {
                onPicked(a.id);
                setState(() {});
                Navigator.pop(ctx);
              },
            )),
        const SizedBox(height: 20),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    final appState = Provider.of<AppState>(context, listen: false);
    final savingsAccounts = appState.accounts
        .where((a) => a.category == AccountCategory.savings)
        .toList();
    final creditAccounts = appState.accounts
        .where((a) => a.category == AccountCategory.credit)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
            isEdit
                ? AppLocalizations.of(context, 'edit_fixed')
                : AppLocalizations.of(context, 'add_fixed'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context, 'cancel'),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(AppLocalizations.of(context, 'save_label'),
                style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── 基本資訊 ──
            _sectionHeader(AppLocalizations.of(context, 'basic_info')),
            _card([
              _row(
                label: AppLocalizations.of(context, 'name_label'),
                child: TextField(
                  controller: _titleCtrl,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context, 'fixed_name_hint'),
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _row(
                label: AppLocalizations.of(context, 'monthly_amount'),
                topBorder: true,
                child: TextField(
                  controller: _amtCtrl,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    prefixText: 'NT\$ ',
                    prefixStyle:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),

            // ── 扣款帳戶 ──
            _sectionHeader(AppLocalizations.of(context, 'debit_account')),
            _card([
              _accountSelectorRow(
                label: AppLocalizations.of(context, 'debit_from'),
                options: savingsAccounts,
                selected: _selectedAccountId,
                onChanged: (id) => setState(() => _selectedAccountId = id),
              ),
              if (creditAccounts.isNotEmpty)
                _accountSelectorRow(
                  label: AppLocalizations.of(context, 'linked_debt'),
                  options: creditAccounts,
                  selected: _selectedDebtAccountId,
                  onChanged: (id) => setState(() => _selectedDebtAccountId = id),
                  topBorder: true,
                ),
            ]),
            if (_selectedDebtAccountId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(
                  AppLocalizations.of(context, 'debt_reduction_hint'),
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),

            // ── 時間設定 ──
            _sectionHeader(AppLocalizations.of(context, 'time_settings')),
            _card([
              _row(
                label: AppLocalizations.of(context, 'start_month'),
                child: GestureDetector(
                  onTap: _pickStartMonth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_startMonthLabel,
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 18, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              _row(
                label: AppLocalizations.of(context, 'set_periods'),
                topBorder: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Switch.adaptive(
                      value: _hasPeriods,
                      activeColor: AppColors.gold,
                      onChanged: (v) => setState(() {
                        _hasPeriods = v;
                        if (!v) _periodsCtrl.clear();
                      }),
                    ),
                  ],
                ),
              ),
              if (_hasPeriods) ...[
                _row(
                  label: AppLocalizations.of(context, 'total_periods'),
                  topBorder: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _periodsCtrl,
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle:
                                TextStyle(color: cs.onSurfaceVariant),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(AppLocalizations.of(context, 'period_unit'),
                          style:
                              TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                _row(
                  label: AppLocalizations.of(context, 'end_month'),
                  topBorder: true,
                  child: Text(
                    _endMonthLabel,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 15,
                        color: _endMonthLabel == '—'
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (isEdit && widget.existing!.totalPeriods != null) ...[
                  Builder(builder: (ctx) {
                    final now = DateTime.now();
                    final remaining =
                        widget.existing!.remainingPeriods(now) ?? 0;
                    final current = widget.existing!.currentPeriod(now);
                    final total = widget.existing!.totalPeriods!;
                    final done = total - remaining;
                    return _row(
                      label:
                          AppLocalizations.of(context, 'current_progress'),
                      topBorder: true,
                      child: Text(
                        AppLocalizations.ofParam(context, 'progress_fmt', {
                          'current': current,
                          'done': done,
                          'remaining': remaining
                        }),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    );
                  }),
                ],
              ],
            ]),

            // ── 備註 ──
            _sectionHeader(AppLocalizations.of(context, 'notes_optional')),
            _card([
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context, 'fixed_notes_hint'),
                    hintStyle: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

extension on Account {
  String? get icon {
    try {
      return kAccountTypes
          .firstWhere((t) => t.name == typeName && t.category == category)
          .icon;
    } catch (_) {
      return null;
    }
  }
}
