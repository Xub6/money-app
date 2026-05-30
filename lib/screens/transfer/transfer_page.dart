import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/account.dart';
import '../../data/repositories/app_state.dart';
import '../../widgets/calculator/amount_calculator_sheet.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final amtStr = _amtCtrl.text.trim();
    final amt = int.tryParse(amtStr.replaceAll(',', ''));

    if (_fromAccountId == null) {
      _showError(AppLocalizations.of(context, 'select_from_account'));
      return;
    }
    if (_toAccountId == null) {
      _showError(AppLocalizations.of(context, 'select_to_account'));
      return;
    }
    if (_fromAccountId == _toAccountId) {
      _showError(AppLocalizations.of(context, 'same_account_error'));
      return;
    }
    if (amt == null || amt <= 0) {
      _showError(AppLocalizations.of(context, 'enter_valid_amount'));
      return;
    }

    setState(() => _saving = true);
    final state = Provider.of<AppState>(context, listen: false);
    state.addTransfer(
      fromAccountId: _fromAccountId!,
      toAccountId: _toAccountId!,
      amount: amt,
      date: _date,
      note: _noteCtrl.text.trim(),
    );

    Navigator.pop(context, true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = Provider.of<AppState>(context, listen: false)
        .accounts
        .where((a) => a.typeName != '股票帳戶')
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalizations.of(context, 'transfer'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context, 'cancel'),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(AppLocalizations.of(context, 'confirm'),
                style: TextStyle(
                    color: cs.primary,
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
            _sectionHeader(AppLocalizations.of(context, 'transfer_accounts')),
            _card([
              _accountPickerRow(
                label: AppLocalizations.of(context, 'from_account'),
                accounts: accounts,
                selected: _fromAccountId,
                excludeId: _toAccountId,
                onChanged: (id) => setState(() => _fromAccountId = id),
              ),
              _arrow(cs),
              _accountPickerRow(
                label: AppLocalizations.of(context, 'to_account'),
                accounts: accounts,
                selected: _toAccountId,
                excludeId: _fromAccountId,
                topBorder: true,
                onChanged: (id) => setState(() => _toAccountId = id),
              ),
            ]),

            _sectionHeader(AppLocalizations.of(context, 'transfer_amount')),
            _card([
              GestureDetector(
                onTap: () async {
                  final current = double.tryParse(_amtCtrl.text) ?? 0;
                  final result = await AmountCalculatorSheet.show(context, initialValue: current);
                  if (result != null && mounted) {
                    setState(() {
                      _amtCtrl.text = result.toInt().toString();
                    });
                  }
                },
                child: AbsorbPointer(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [
                      Text('NT\$',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amtCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 28,
                                fontWeight: FontWeight.w700),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),

            _sectionHeader(AppLocalizations.of(context, 'date')),
            _card([
              InkWell(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Text(AppLocalizations.of(context, 'date'),
                        style: TextStyle(
                            fontSize: 15,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(DateFormat('yyyy/MM/dd').format(_date),
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 18, color: cs.onSurfaceVariant),
                  ]),
                ),
              ),
            ]),

            _sectionHeader(AppLocalizations.of(context, 'note')),
            _card([
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context, 'note_optional'),
                    hintStyle: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context, 'confirm_transfer'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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

  Widget _arrow(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Icon(Icons.arrow_downward_rounded,
              size: 20, color: cs.primary.withValues(alpha: 0.6)),
        ),
      );

  Widget _accountPickerRow({
    required String label,
    required List<Account> accounts,
    required String? selected,
    required void Function(String?) onChanged,
    String? excludeId,
    bool topBorder = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final options = accounts.where((a) => a.id != excludeId).toList();
    final sel = options.where((a) => a.id == selected).firstOrNull;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (topBorder)
        Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.35),
            indent: 16,
            endIndent: 16),
      InkWell(
        onTap: () => _showPicker(options, selected, onChanged),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            if (sel != null) ...[
              Text(sel.icon ?? '💳',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(sel.displayName,
                  style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(width: 2),
              Text(
                '(${sel.currencySymbol}${sel.balance.toStringAsFixed(0)})',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ] else
              Text(AppLocalizations.of(context, 'please_select'),
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 14)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
          ]),
        ),
      ),
    ]);
  }

  void _showPicker(
    List<Account> accounts,
    String? selected,
    void Function(String?) onChanged,
  ) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),
        ...accounts.map((a) => ListTile(
              leading: Text(a.icon ?? '💳',
                  style: const TextStyle(fontSize: 20)),
              title: Text(a.displayName,
                  style: TextStyle(
                      color: cs.onSurface, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${a.currencySymbol} ${a.balance.toStringAsFixed(0)}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              trailing: selected == a.id
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () {
                onChanged(a.id);
                setState(() {});
                Navigator.pop(ctx);
              },
            )),
        const SizedBox(height: 20),
      ]),
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
