class LoanPayment {
  final String id;
  final String loanId;
  final DateTime date;
  final String? accountId;
  final double total;
  final double principal;
  final double interest;
  final String? notes;

  LoanPayment({
    String? id,
    required this.loanId,
    DateTime? date,
    this.accountId,
    required this.total,
    required this.principal,
    this.interest = 0,
    this.notes,
  })  : id = id ?? _uid(),
        date = date ?? DateTime.now();

  static String _uid() =>
      'lp_${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'loanId': loanId,
        'date': date.toIso8601String(),
        'accountId': accountId,
        'total': total,
        'principal': principal,
        'interest': interest,
        'notes': notes,
      };

  factory LoanPayment.fromJson(Map<String, dynamic> j) => LoanPayment(
        id: j['id'] as String,
        loanId: j['loanId'] as String,
        date: DateTime.parse(j['date'] as String),
        accountId: j['accountId'] as String?,
        total: (j['total'] as num).toDouble(),
        principal: (j['principal'] as num).toDouble(),
        interest: (j['interest'] as num? ?? 0).toDouble(),
        notes: j['notes'] as String?,
      );
}
