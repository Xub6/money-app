import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/localization.dart';
import '../../data/models/account.dart';
import '../../core/constants/app_colors.dart';
import 'account_type_page.dart';

class AddEditAccountPage extends StatefulWidget {
  final Account? existing;
  const AddEditAccountPage({super.key, this.existing});

  @override
  State<AddEditAccountPage> createState() => _AddEditAccountPageState();
}

class _AddEditAccountPageState extends State<AddEditAccountPage> {
  AccountTypeOption? _selectedType;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _noteCtrl;
  late String _currency;
  late bool _countInTotal;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.customName ?? '');
    _balanceCtrl = TextEditingController(
        text: e != null && e.balance != 0 ? e.balance.toStringAsFixed(0) : '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _currency = e?.currency ?? 'TWD';
    _countInTotal = e?.countInTotal ?? true;
    if (e != null) {
      _selectedType = kAccountTypes.firstWhere(
        (t) => t.name == e.typeName && t.category == e.category,
        orElse: () => kAccountTypes.first,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickType() async {
    final result = await Navigator.push<AccountTypeOption>(
      context,
      MaterialPageRoute(builder: (_) => const AccountTypePage()),
    );
    if (result != null) setState(() => _selectedType = result);
  }

  void _save() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'please_select_account_type'))),
      );
      return;
    }
    final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 0;
    Navigator.pop(
      context,
      Account(
        id: widget.existing?.id,
        typeName: _selectedType!.name,
        customName: _nameCtrl.text.trim(),
        category: _selectedType!.category,
        balance: balance,
        currency: _currency,
        note: _noteCtrl.text.trim(),
        countInTotal: _countInTotal,
        createdAt: widget.existing?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(isEdit ? AppLocalizations.of(context, 'edit_account') : AppLocalizations.of(context, 'add_account'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context, 'cancel'), style: const TextStyle(color: AppColors.gold)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(isEdit ? AppLocalizations.of(context, 'update') : AppLocalizations.of(context, 'save_label'),
                style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── 帳戶設定 ──
            _SectionHeader(AppLocalizations.of(context, 'account_settings')),
            _GroupCard(
                cs: cs,
                child: Column(children: [
                  // 帳戶類型
                  _RowItem(
                    label: AppLocalizations.of(context, 'account_type'),
                    cs: cs,
                    child: GestureDetector(
                      onTap: _pickType,
                      behavior: HitTestBehavior.opaque,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (_selectedType != null) ...[
                          Text(_selectedType!.icon,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(_selectedType!.name,
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600)),
                        ] else
                          Text(AppLocalizations.of(context, 'please_select'),
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            color: cs.onSurfaceVariant, size: 18),
                      ]),
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  // 自訂名稱
                  _RowItem(
                    label: AppLocalizations.of(context, 'custom_name'),
                    cs: cs,
                    child: TextField(
                      controller: _nameCtrl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: cs.onSurface, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context, 'optional'),
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ])),
            const SizedBox(height: 20),

            // ── 餘額 ──
            _SectionHeader(AppLocalizations.of(context, 'balance')),
            _GroupCard(
                cs: cs,
                child: Column(children: [
                  _RowItem(
                    label: AppLocalizations.of(context, 'current_balance'),
                    cs: cs,
                    child: TextField(
                      controller: _balanceCtrl,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  // 貨幣
                  _RowItem(
                    label: AppLocalizations.of(context, 'currency'),
                    cs: cs,
                    child: DropdownButton<String>(
                      value: _currency,
                      underline: const SizedBox(),
                      style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      dropdownColor: cs.surfaceContainerHigh,
                      items: kCurrencies
                          .map((c) => DropdownMenuItem(
                                value: c.$1,
                                child: Text('${c.$1}  ${c.$2}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ])),
            const SizedBox(height: 20),

            // ── 其他 ──
            _SectionHeader(AppLocalizations.of(context, 'other')),
            _GroupCard(
                cs: cs,
                child: Column(children: [
                  _RowItem(
                    label: AppLocalizations.of(context, 'note'),
                    cs: cs,
                    child: TextField(
                      controller: _noteCtrl,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context, 'optional'),
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  _RowItem(
                    label: AppLocalizations.of(context, 'count_in_total'),
                    cs: cs,
                    child: Switch(
                      value: _countInTotal,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        setState(() => _countInTotal = v);
                      },
                      activeColor: AppColors.gold,
                    ),
                  ),
                ])),
          ]),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _GroupCard extends StatelessWidget {
  final Widget child;
  final ColorScheme cs;
  const _GroupCard({required this.child, required this.cs});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: child,
      );
}

class _RowItem extends StatelessWidget {
  final String label;
  final Widget child;
  final ColorScheme cs;
  const _RowItem({required this.label, required this.child, required this.cs});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface)),
          const SizedBox(width: 12),
          Expanded(
              child: Align(alignment: Alignment.centerRight, child: child)),
        ]),
      );
}
