import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../config/localization.dart';
import '../../data/models/account.dart';
import '../../data/models/loan_record.dart';
import '../../data/models/loan_payment.dart';
import '../../data/repositories/app_state.dart';

const kGold = AppColors.gold;
const kRed = AppColors.error;
const kGray = AppColors.textSecondary;
const kGreen = AppColors.success;

class LoanPage extends StatelessWidget {
  final AppState state;
  const LoanPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalizations.of(context, 'loan_records'), style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: kGold,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addLoan(context),
        backgroundColor: kGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context, 'add_loan'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final loans = state.loans;
          if (loans.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.handshake_outlined, size: 56, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context, 'no_loans'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context, 'tap_to_add'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ]),
            );
          }

          final active = loans.where((l) => !l.isCompleted).toList();
          final completed = loans.where((l) => l.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            children: [
              if (active.isNotEmpty) ...[
                _sectionHeader('進行中', cs),
                ...active.map((l) => _LoanCard(loan: l, state: state)),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _sectionHeader('已完成', cs),
                ...completed.map((l) => _LoanCard(loan: l, state: state)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String text, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant)),
      );

  void _addLoan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLoanPage(state: state)),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanRecord loan;
  final AppState state;
  const _LoanCard({required this.loan, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0', 'en_US');
    final pct = loan.amount > 0 ? (loan.paid / loan.amount * 100).clamp(0.0, 100.0) : 0.0;
    final isCompleted = loan.isCompleted;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoanDetailPage(loan: loan, state: state)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))
              : Border.all(color: kGold.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? cs.surfaceContainerHighest
                    : kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_outline : Icons.handshake_rounded,
                color: isCompleted ? cs.onSurfaceVariant : kGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(loan.borrowerName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(DateFormat('yyyy/MM/dd').format(loan.date),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${loan.currency} ${fmt.format(loan.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(isCompleted ? '已還清' : '剩 ${loan.currency} ${fmt.format(loan.remaining)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? kGreen : kRed,
                      fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(isCompleted ? kGreen : kGold),
            ),
          ),
          const SizedBox(height: 6),
          Text(AppLocalizations.ofParam(context, 'recovered_pct', {'pct': pct.toStringAsFixed(1)}),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ── 借款詳情頁 ──
class LoanDetailPage extends StatelessWidget {
  final LoanRecord loan;
  final AppState state;
  const LoanDetailPage({super.key, required this.loan, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(loan.borrowerName, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: kGold,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kRed),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      floatingActionButton: loan.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addPayment(context),
              backgroundColor: kGold,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context, 'add_payment'), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final currentLoan = state.loans.firstWhere(
              (l) => l.id == loan.id,
              orElse: () => loan);
          final payments = state.loanPayments.where((p) => p.loanId == loan.id).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final pct = currentLoan.amount > 0
              ? (currentLoan.paid / currentLoan.amount * 100).clamp(0.0, 100.0)
              : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
            children: [
              // 摘要卡
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kGold.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: _statBox('借款總額', '${currentLoan.currency} ${fmt.format(currentLoan.amount)}', cs),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statBox('已收回', '${currentLoan.currency} ${fmt.format(currentLoan.paid)}', cs, color: kGreen),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statBox('剩餘', '${currentLoan.currency} ${fmt.format(currentLoan.remaining)}', cs, color: currentLoan.isCompleted ? kGreen : kRed),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(currentLoan.isCompleted ? kGreen : kGold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.ofParam(context, 'repayment_progress', {'pct': pct.toStringAsFixed(1)}),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (currentLoan.notes != null && currentLoan.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(currentLoan.notes!,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ]),
              ),
              const SizedBox(height: 20),

              // 收款紀錄
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(AppLocalizations.of(context, 'payment_records'),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ),
              if (payments.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(AppLocalizations.of(context, 'no_payment_records'),
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                )
              else
                ...payments.map((p) => _PaymentRow(
                      payment: p,
                      state: state,
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _statBox(String label, String value, ColorScheme cs, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  void _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.ofParam(context, 'delete_loan_title', {'name': loan.borrowerName}), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(AppLocalizations.of(context, 'delete_loan_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context, 'delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ) ?? false;
    if (ok && context.mounted) {
      state.deleteLoan(loan.id);
      Navigator.pop(context);
    }
  }

  void _addPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPaymentPage(loan: loan, state: state)),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final LoanPayment payment;
  final AppState state;
  const _PaymentRow({required this.payment, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0', 'en_US');
    final account = state.accounts.where((a) => a.id == payment.accountId).firstOrNull;

    return Dismissible(
      key: Key(payment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.of(context, 'delete_payment_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Text(AppLocalizations.of(context, 'delete_payment_body')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context, 'cancel'))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context, 'delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => state.deleteLoanPayment(payment.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward_rounded, color: kGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('yyyy/MM/dd').format(payment.date),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              if (account != null)
                Text(AppLocalizations.ofParam(context, 'deposited_to', {'account': account.displayName}),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              if (payment.interest > 0)
                Text(AppLocalizations.ofParam(context, 'interest_label', {'amount': NumberFormat('#,##0.00', 'en_US').format(payment.interest)}),
                    style: TextStyle(fontSize: 12, color: kGold)),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                Text(payment.notes!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+${fmt.format(payment.total)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, color: kGreen)),
            Text(AppLocalizations.ofParam(context, 'principal_label', {'amount': fmt.format(payment.principal)}),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }
}

// ── 新增借款 ──
class AddLoanPage extends StatefulWidget {
  final AppState state;
  const AddLoanPage({super.key, required this.state});

  @override
  State<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _currency = 'TWD';
  String? _accountId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = widget.state.accounts
        .where((a) =>
            a.category == AccountCategory.savings &&
            a.typeName != '股票帳戶')
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalizations.of(context, 'add_loan'), style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context, 'cancel'), style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(AppLocalizations.of(context, 'save_label'),
                style: const TextStyle(color: kGold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _field('借款人', _nameCtrl, hint: '輸入借款人名稱'),
          const SizedBox(height: 14),
          _field('金額', _amountCtrl, hint: '0', keyboardType: TextInputType.number),
          const SizedBox(height: 14),

          // 幣別
          _label('幣別'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['TWD', 'USD', 'JPY', 'EUR'].map((c) {
              final sel = _currency == c;
              return ChoiceChip(
                label: Text(c),
                selected: sel,
                onSelected: (_) => setState(() => _currency = c),
                selectedColor: kGold.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                    color: sel ? kGold : cs.onSurface,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // 扣款帳戶（從哪個帳戶借出）
          _label('借出帳戶（選填）'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(AppLocalizations.of(context, 'not_specified')),
                selected: _accountId == null,
                onSelected: (_) => setState(() => _accountId = null),
                selectedColor: kGold.withValues(alpha: 0.2),
              ),
              ...accounts.map((a) {
                final sel = _accountId == a.id;
                return ChoiceChip(
                  label: Text(a.displayName),
                  selected: sel,
                  onSelected: (_) => setState(() => _accountId = a.id),
                  selectedColor: kGold.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                      color: sel ? kGold : cs.onSurface,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          // 日期
          _label('借款日期'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: kGold),
                const SizedBox(width: 10),
                Text(DateFormat('yyyy/MM/dd').format(_date),
                    style: const TextStyle(fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          _field('備註', _notesCtrl, hint: '選填'),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kGray));

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType keyboardType = TextInputType.text}) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: cs.surfaceContainerLow,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kGold, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'fill_borrower_amount'))),
      );
      return;
    }
    widget.state.addLoan(LoanRecord(
      borrowerName: name,
      amount: amount,
      currency: _currency,
      date: _date,
      accountId: _accountId,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }
}

// ── 新增收款 ──
class AddPaymentPage extends StatefulWidget {
  final LoanRecord loan;
  final AppState state;
  const AddPaymentPage({super.key, required this.loan, required this.state});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _totalCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _accountId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _totalCtrl.dispose();
    _interestCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = widget.state.accounts
        .where((a) =>
            a.category == AccountCategory.savings &&
            a.typeName != '股票帳戶')
        .toList();
    final fmt = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalizations.of(context, 'add_payment'), style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context, 'cancel'), style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(AppLocalizations.of(context, 'save_label'),
                style: const TextStyle(color: kGold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${widget.loan.borrowerName}・剩餘 ${widget.loan.currency} ${fmt.format(widget.loan.remaining)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: kGold),
            ),
          ),

          _field('收款金額', _totalCtrl, hint: '0', keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          _field('其中利息', _interestCtrl, hint: '0（選填）', keyboardType: TextInputType.number),
          const SizedBox(height: 14),

          _label('存入帳戶（選填）'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(AppLocalizations.of(context, 'not_specified')),
                selected: _accountId == null,
                onSelected: (_) => setState(() => _accountId = null),
                selectedColor: kGold.withValues(alpha: 0.2),
              ),
              ...accounts.map((a) {
                final sel = _accountId == a.id;
                return ChoiceChip(
                  label: Text(a.displayName),
                  selected: sel,
                  onSelected: (_) => setState(() => _accountId = a.id),
                  selectedColor: kGold.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                      color: sel ? kGold : cs.onSurface,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          _label('收款日期'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: kGold),
                const SizedBox(width: 10),
                Text(DateFormat('yyyy/MM/dd').format(_date),
                    style: const TextStyle(fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          _field('備註', _notesCtrl, hint: '選填'),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kGray));

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType keyboardType = TextInputType.text}) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: cs.surfaceContainerLow,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kGold, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final total = double.tryParse(_totalCtrl.text.trim());
    if (total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'fill_payment_amount'))),
      );
      return;
    }
    final interest = double.tryParse(_interestCtrl.text.trim()) ?? 0;
    final principal = (total - interest).clamp(0.0, widget.loan.remaining);

    widget.state.addLoanPayment(LoanPayment(
      loanId: widget.loan.id,
      date: _date,
      accountId: _accountId,
      total: total,
      principal: principal,
      interest: interest,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }
}
