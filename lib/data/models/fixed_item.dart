import 'package:uuid/uuid.dart';
import 'expense_item.dart';

const _sentinel = Object();

enum RenewalCycle {
  monthly('monthly', '每月'),
  yearly('yearly', '每年');

  final String value;
  final String label;
  const RenewalCycle(this.value, this.label);

  static RenewalCycle fromString(String value) {
    return RenewalCycle.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RenewalCycle.monthly,
    );
  }
}

class FixedItem {
  final String id;
  final String title;
  final int amount;
  final String category;
  final DateTime startDate;
  final DateTime? endDate;
  final int? totalPeriods;
  final RenewalCycle renewalCycle;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isActive;
  final SyncStatus syncStatus;
  final String? notes;
  final String? accountId;           // debit account when executed
  final String? linkedDebtAccountId; // debt account to reduce on execution
  final String currency;             // currency of the amount
  final int debitDay;                // 0=manual only, 1-28=auto-debit day of month
  final String? lastExecutedYearMonth; // "2026-05" format, prevents double-execution

  FixedItem({
    String? id,
    required this.title,
    required this.amount,
    String category = '其他',
    DateTime? startDate,
    this.endDate,
    this.totalPeriods,
    this.renewalCycle = RenewalCycle.monthly,
    DateTime? createdAt,
    this.editedAt,
    this.isActive = true,
    this.syncStatus = SyncStatus.local,
    this.notes,
    this.accountId,
    this.linkedDebtAccountId,
    this.currency = 'TWD',
    this.debitDay = 0,
    this.lastExecutedYearMonth,
  })  : id = id ?? const Uuid().v4(),
        category = category,
        startDate = startDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  DateTime? get effectiveEndDate {
    if (totalPeriods != null) {
      final s = startDate;
      return DateTime(s.year, s.month + totalPeriods!, s.day);
    }
    return endDate;
  }

  int currentPeriod(DateTime now) {
    final diff =
        (now.year - startDate.year) * 12 + (now.month - startDate.month) + 1;
    return diff.clamp(0, totalPeriods ?? diff);
  }

  int? remainingPeriods(DateTime now) {
    if (totalPeriods == null) return null;
    final elapsed =
        (now.year - startDate.year) * 12 + (now.month - startDate.month);
    return (totalPeriods! - elapsed).clamp(0, totalPeriods!);
  }

  bool get isCompleted {
    if (totalPeriods == null) return false;
    final now = DateTime.now();
    return remainingPeriods(now) == 0;
  }

  bool get isEdited => editedAt != null;
  bool get isPending => syncStatus == SyncStatus.local;

  bool isActiveAt(DateTime date) {
    if (!isActive) return false;
    if (date.isBefore(startDate)) return false;
    final end = effectiveEndDate;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }

  FixedItem copyWith({
    String? id,
    String? title,
    int? amount,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    Object? totalPeriods = _sentinel,
    RenewalCycle? renewalCycle,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isActive,
    SyncStatus? syncStatus,
    String? notes,
    Object? accountId = _sentinel,
    Object? linkedDebtAccountId = _sentinel,
    String? currency,
    int? debitDay,
    Object? lastExecutedYearMonth = _sentinel,
  }) {
    return FixedItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPeriods:
          totalPeriods == _sentinel ? this.totalPeriods : totalPeriods as int?,
      renewalCycle: renewalCycle ?? this.renewalCycle,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes ?? this.notes,
      accountId:
          accountId == _sentinel ? this.accountId : accountId as String?,
      linkedDebtAccountId: linkedDebtAccountId == _sentinel
          ? this.linkedDebtAccountId
          : linkedDebtAccountId as String?,
      currency: currency ?? this.currency,
      debitDay: debitDay ?? this.debitDay,
      lastExecutedYearMonth: lastExecutedYearMonth == _sentinel
          ? this.lastExecutedYearMonth
          : lastExecutedYearMonth as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'totalPeriods': totalPeriods,
        'renewalCycle': renewalCycle.value,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'isActive': isActive,
        'syncStatus': syncStatus.value,
        'notes': notes,
        'accountId': accountId,
        'linkedDebtAccountId': linkedDebtAccountId,
        'currency': currency,
        'debitDay': debitDay,
        'lastExecutedYearMonth': lastExecutedYearMonth,
      };

  factory FixedItem.fromJson(Map<String, dynamic> json) => FixedItem(
        id: json['id'] as String? ?? const Uuid().v4(),
        title: json['title'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        category: json['category'] as String? ?? '其他',
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : DateTime.now(),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        totalPeriods: json['totalPeriods'] as int?,
        renewalCycle: RenewalCycle.fromString(
          json['renewalCycle'] as String? ?? 'monthly',
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        editedAt: json['editedAt'] != null
            ? DateTime.parse(json['editedAt'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? true,
        syncStatus:
            SyncStatus.fromString(json['syncStatus'] as String? ?? 'local'),
        notes: json['notes'] as String?,
        accountId: json['accountId'] as String?,
        linkedDebtAccountId: json['linkedDebtAccountId'] as String?,
        currency: json['currency'] as String? ?? 'TWD',
        debitDay: json['debitDay'] as int? ?? 0,
        lastExecutedYearMonth: json['lastExecutedYearMonth'] as String?,
      );

  Map<String, dynamic> toDatabaseJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'total_periods': totalPeriods,
        'renewal_cycle': renewalCycle.value,
        'created_at': createdAt.toIso8601String(),
        'edited_at': editedAt?.toIso8601String(),
        'is_active': isActive ? 1 : 0,
        'sync_status': syncStatus.value,
        'notes': notes,
        'account_id': accountId,
        'linked_debt_account_id': linkedDebtAccountId,
        'currency': currency,
        'debit_day': debitDay,
        'last_executed_year_month': lastExecutedYearMonth,
      };

  factory FixedItem.fromDatabase(Map<String, dynamic> map) => FixedItem(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: map['amount'] as int,
        category: map['category'] as String,
        startDate: DateTime.parse(map['start_date'] as String),
        endDate: map['end_date'] != null
            ? DateTime.parse(map['end_date'] as String)
            : null,
        totalPeriods: map['total_periods'] as int?,
        renewalCycle: RenewalCycle.fromString(
            map['renewal_cycle'] as String? ?? 'monthly'),
        createdAt: DateTime.parse(map['created_at'] as String),
        editedAt: map['edited_at'] != null
            ? DateTime.parse(map['edited_at'] as String)
            : null,
        isActive: (map['is_active'] as int?) == 1,
        syncStatus:
            SyncStatus.fromString(map['sync_status'] as String? ?? 'local'),
        notes: map['notes'] as String?,
        accountId: map['account_id'] as String?,
        linkedDebtAccountId: map['linked_debt_account_id'] as String?,
        currency: map['currency'] as String? ?? 'TWD',
        debitDay: map['debit_day'] as int? ?? 0,
        lastExecutedYearMonth: map['last_executed_year_month'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FixedItem(id: $id, title: $title, amount: $amount)';
}
