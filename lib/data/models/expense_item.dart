import 'dart:convert';
import 'package:uuid/uuid.dart';

enum SyncStatus {
  local('local'),
  synced('synced'),
  failed('failed');

  final String value;
  const SyncStatus(this.value);

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.local,
    );
  }
}

enum TransactionType {
  expense('expense'),
  income('income'),
  transfer('transfer');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}

/// pending = future-dated, not yet applied to account balance.
/// completed = applied and counted in statistics.
enum TransactionStatus {
  completed('completed'),
  pending('pending');

  final String value;
  const TransactionStatus(this.value);

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionStatus.completed,
    );
  }
}

class ExpenseItem {
  final String id;
  final String title;
  final String category;
  final int amount;
  final DateTime date;
  final String note;
  final DateTime createdAt;
  final DateTime? editedAt;
  final SyncStatus syncStatus;
  final String? attachmentPath;
  final Map<String, dynamic>? metadata;
  final TransactionType type;
  final String? accountId;
  final TransactionStatus status;
  final String? transferAccountId; // target account for type=transfer
  final String currency;           // transaction currency, default 'TWD'

  ExpenseItem({
    String? id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    String note = '',
    DateTime? createdAt,
    this.editedAt,
    this.syncStatus = SyncStatus.local,
    this.attachmentPath,
    this.metadata,
    this.type = TransactionType.expense,
    this.accountId,
    this.status = TransactionStatus.completed,
    this.transferAccountId,
    this.currency = 'TWD',
  })  : id = id ?? const Uuid().v4(),
        note = note,
        createdAt = createdAt ?? DateTime.now();

  bool get isEdited => editedAt != null;
  bool get isPendingSync => syncStatus == SyncStatus.local;
  bool get isPending => status == TransactionStatus.pending;
  bool get isTransfer => type == TransactionType.transfer;

  ExpenseItem copyWith({
    String? id,
    String? title,
    String? category,
    int? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? editedAt,
    SyncStatus? syncStatus,
    String? attachmentPath,
    Map<String, dynamic>? metadata,
    TransactionType? type,
    String? accountId,
    TransactionStatus? status,
    String? transferAccountId,
    String? currency,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      metadata: metadata ?? this.metadata,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      transferAccountId: transferAccountId ?? this.transferAccountId,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'syncStatus': syncStatus.value,
        'attachmentPath': attachmentPath,
        'metadata': metadata,
        'type': type.value,
        'accountId': accountId,
        'status': status.value,
        'transferAccountId': transferAccountId,
        'currency': currency,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
        id: json['id'] as String? ?? const Uuid().v4(),
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '其他',
        amount: json['amount'] as int? ?? 0,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        note: json['note'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        editedAt: json['editedAt'] != null
            ? DateTime.parse(json['editedAt'] as String)
            : null,
        syncStatus:
            SyncStatus.fromString(json['syncStatus'] as String? ?? 'local'),
        attachmentPath: json['attachmentPath'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        type: TransactionType.fromString(json['type'] as String? ?? 'expense'),
        accountId: json['accountId'] as String?,
        status: TransactionStatus.fromString(
            json['status'] as String? ?? 'completed'),
        transferAccountId: json['transferAccountId'] as String?,
        currency: json['currency'] as String? ?? 'TWD',
      );

  Map<String, dynamic> toDatabaseJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'edited_at': editedAt?.toIso8601String(),
        'sync_status': syncStatus.value,
        'attachment_path': attachmentPath,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
        'type': type.value,
        'account_id': accountId,
        'status': status.value,
        'transfer_account_id': transferAccountId,
        'currency': currency,
      };

  factory ExpenseItem.fromDatabase(Map<String, dynamic> map) => ExpenseItem(
        id: map['id'] as String,
        title: map['title'] as String,
        category: map['category'] as String,
        amount: map['amount'] as int,
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
        editedAt: map['edited_at'] != null
            ? DateTime.parse(map['edited_at'] as String)
            : null,
        syncStatus:
            SyncStatus.fromString(map['sync_status'] as String? ?? 'local'),
        attachmentPath: map['attachment_path'] as String?,
        type: TransactionType.fromString(map['type'] as String? ?? 'expense'),
        accountId: map['account_id'] as String?,
        status: TransactionStatus.fromString(
            map['status'] as String? ?? 'completed'),
        transferAccountId: map['transfer_account_id'] as String?,
        currency: map['currency'] as String? ?? 'TWD',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ExpenseItem(id: $id, title: $title, amount: $amount)';
}
