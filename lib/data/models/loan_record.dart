enum LoanStatus { active, completed }

class LoanRecord {
  final String id;
  final String borrowerName;
  final double amount;
  final String currency;
  final double remaining;
  final double paid;
  final DateTime date;
  final LoanStatus status;
  final String? notes;
  final String? accountId;

  LoanRecord({
    String? id,
    required this.borrowerName,
    required this.amount,
    this.currency = 'TWD',
    double? remaining,
    this.paid = 0,
    DateTime? date,
    this.status = LoanStatus.active,
    this.notes,
    this.accountId,
  })  : id = id ?? _uid(),
        remaining = remaining ?? amount,
        date = date ?? DateTime.now();

  static String _uid() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (999 * (DateTime.now().microsecondsSinceEpoch % 1))).toString();

  bool get isCompleted => remaining <= 0 || status == LoanStatus.completed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'borrowerName': borrowerName,
        'amount': amount,
        'currency': currency,
        'remaining': remaining,
        'paid': paid,
        'date': date.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'accountId': accountId,
      };

  factory LoanRecord.fromJson(Map<String, dynamic> j) => LoanRecord(
        id: j['id'] as String,
        borrowerName: j['borrowerName'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'TWD',
        remaining: (j['remaining'] as num).toDouble(),
        paid: (j['paid'] as num? ?? 0).toDouble(),
        date: DateTime.parse(j['date'] as String),
        status: j['status'] == 'completed' ? LoanStatus.completed : LoanStatus.active,
        notes: j['notes'] as String?,
        accountId: j['accountId'] as String?,
      );

  LoanRecord copyWith({
    String? borrowerName,
    double? amount,
    String? currency,
    double? remaining,
    double? paid,
    DateTime? date,
    LoanStatus? status,
    String? notes,
    String? accountId,
  }) =>
      LoanRecord(
        id: id,
        borrowerName: borrowerName ?? this.borrowerName,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        remaining: remaining ?? this.remaining,
        paid: paid ?? this.paid,
        date: date ?? this.date,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        accountId: accountId ?? this.accountId,
      );
}
