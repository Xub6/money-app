import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Sync status for items
enum SyncStatus {
  local('local'), // Only in local device
  synced('synced'), // Synced to server/backup
  failed('failed'); // Sync failed

  final String value;
  const SyncStatus(this.value);

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.local,
    );
  }
}

/// Expense item model
class ExpenseItem {
  final String id;
  final String title;
  final String category;
  final int amount; // Amount in cents to avoid float precision issues
  final DateTime date;
  final String note;
  final DateTime createdAt; // When created
  final DateTime? editedAt; // When last edited (null if never edited)
  final SyncStatus syncStatus; // Sync state
  final String? attachmentPath; // Path to receipt image (optional)
  final Map<String, dynamic>? metadata; // Extensible metadata

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
  })  : id = id ?? const Uuid().v4(),
        note = note,
        createdAt = createdAt ?? DateTime.now();

  /// Whether this item has been edited
  bool get isEdited => editedAt != null;

  /// Whether this item is pending sync
  bool get isPending => syncStatus == SyncStatus.local;

  /// Create a copy with modifications
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
    );
  }

  /// Convert to JSON for storage
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
      };

  /// Create from JSON
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
      );

  /// Convert to database JSON (SQLite format)
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
      };

  /// Create from database
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
