import 'expense_item.dart';
import 'fixed_item.dart';

/// Search result item
class SearchResult<T> {
  final String id;
  final String type; // 'expense' or 'fixed'
  final T item; // ExpenseItem or FixedItem
  final double relevance; // 0.0 to 1.0
  final List<String> matchedFields; // Which fields matched

  const SearchResult({
    required this.id,
    required this.type,
    required this.item,
    required this.relevance,
    required this.matchedFields,
  });

  @override
  String toString() => 'SearchResult(type: $type, relevance: $relevance)';
}

/// Backup metadata
class BackupMetadata {
  final String id;
  final DateTime timestamp;
  final String version; // Backup format version
  final int expenseCount;
  final int fixedCount;
  final int totalAmount;
  final String appVersion;
  final String? deviceInfo;
  final String? notes;

  BackupMetadata({
    String? id,
    DateTime? timestamp,
    String version = '1.0',
    this.expenseCount = 0,
    this.fixedCount = 0,
    this.totalAmount = 0,
    String appVersion = '2.0.0',
    this.deviceInfo,
    this.notes,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now(),
        version = version,
        appVersion = appVersion;

  /// Generate backup filename
  String get filename {
    final iso =
        timestamp.toIso8601String().replaceAll(':', '').substring(0, 15);
    return 'backup_$iso.json';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'expenseCount': expenseCount,
        'fixedCount': fixedCount,
        'totalAmount': totalAmount,
        'appVersion': appVersion,
        'deviceInfo': deviceInfo,
        'notes': notes,
      };

  /// Create from JSON
  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
        id: json['id'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
        version: json['version'] as String? ?? '1.0',
        expenseCount: json['expenseCount'] as int? ?? 0,
        fixedCount: json['fixedCount'] as int? ?? 0,
        totalAmount: json['totalAmount'] as int? ?? 0,
        appVersion: json['appVersion'] as String? ?? '2.0.0',
        deviceInfo: json['deviceInfo'] as String?,
        notes: json['notes'] as String?,
      );
}

/// Complete backup data
class BackupData {
  final BackupMetadata metadata;
  final List<ExpenseItem> expenses;
  final List<FixedItem> fixedItems;
  final Map<String, dynamic>? settings; // App settings backup

  BackupData({
    required this.metadata,
    required this.expenses,
    required this.fixedItems,
    this.settings,
  });

  /// Convert to JSON for file storage
  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'fixedItems': fixedItems.map((f) => f.toJson()).toList(),
        'settings': settings,
      };

  /// Create from JSON
  factory BackupData.fromJson(Map<String, dynamic> json) {
    final metaJson = json['metadata'] as Map<String, dynamic>?;
    final meta =
        metaJson != null ? BackupMetadata.fromJson(metaJson) : BackupMetadata();

    final expensesJson = json['expenses'] as List? ?? [];
    final expenses = expensesJson
        .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final fixedJson = json['fixedItems'] as List? ?? [];
    final fixedItems = fixedJson
        .map((f) => FixedItem.fromJson(f as Map<String, dynamic>))
        .toList();

    return BackupData(
      metadata: meta,
      expenses: expenses,
      fixedItems: fixedItems,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }
}
