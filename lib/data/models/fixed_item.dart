import 'package:uuid/uuid.dart';
import 'expense_item.dart';

const _sentinel = Object();

/// Renewal cycle for fixed items
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

/// Fixed item model (subscriptions, recurring expenses)
class FixedItem {
  final String id;
  final String title;
  final int amount; // Amount in cents
  final String category;
  final DateTime startDate; // When subscription started
  final DateTime? endDate; // Explicit end (null = ongoing)
  final int? totalPeriods; // Number of installments (null = no limit)
  final RenewalCycle renewalCycle;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isActive;
  final SyncStatus syncStatus;
  final String? notes;

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
  })  : id = id ?? const Uuid().v4(),
        category = category,
        startDate = startDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Computed end date from totalPeriods (overrides endDate when set)
  DateTime? get effectiveEndDate {
    if (totalPeriods != null) {
      final s = startDate;
      return DateTime(s.year, s.month + totalPeriods!, s.day);
    }
    return endDate;
  }

  /// How many periods have elapsed (1-based current period)
  int currentPeriod(DateTime now) {
    final diff =
        (now.year - startDate.year) * 12 + (now.month - startDate.month) + 1;
    return diff.clamp(0, totalPeriods ?? diff);
  }

  /// Remaining periods from now
  int? remainingPeriods(DateTime now) {
    if (totalPeriods == null) return null;
    final elapsed =
        (now.year - startDate.year) * 12 + (now.month - startDate.month);
    return (totalPeriods! - elapsed).clamp(0, totalPeriods!);
  }

  /// Whether all periods are done
  bool get isCompleted {
    if (totalPeriods == null) return false;
    final now = DateTime.now();
    return remainingPeriods(now) == 0;
  }

  /// Whether this item has been edited
  bool get isEdited => editedAt != null;

  /// Whether this item is pending sync
  bool get isPending => syncStatus == SyncStatus.local;

  /// Check if active at a given date
  bool isActiveAt(DateTime date) {
    if (!isActive) return false;
    if (date.isBefore(startDate)) return false;
    final end = effectiveEndDate;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }

  /// Create a copy with modifications
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
    );
  }

  /// Convert to JSON
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
      };

  /// Create from JSON
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
      );

  /// Convert to database JSON
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
      };

  /// Create from database
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
