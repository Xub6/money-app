import 'expense_item.dart';
import 'fixed_item.dart';
import 'account.dart';
import 'stock_holding.dart';

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
  final String version;
  final int expenseCount;
  final int fixedCount;
  final int accountCount;
  final int holdingCount;
  final int totalAmount;
  final String appVersion;
  final String? deviceInfo;
  final String? notes;

  BackupMetadata({
    String? id,
    DateTime? timestamp,
    String version = '2.0',
    this.expenseCount = 0,
    this.fixedCount = 0,
    this.accountCount = 0,
    this.holdingCount = 0,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'expenseCount': expenseCount,
        'fixedCount': fixedCount,
        'accountCount': accountCount,
        'holdingCount': holdingCount,
        'totalAmount': totalAmount,
        'appVersion': appVersion,
        'deviceInfo': deviceInfo,
        'notes': notes,
      };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
        id: json['id'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
        version: json['version'] as String? ?? '1.0',
        expenseCount: json['expenseCount'] as int? ?? 0,
        fixedCount: json['fixedCount'] as int? ?? 0,
        accountCount: json['accountCount'] as int? ?? 0,
        holdingCount: json['holdingCount'] as int? ?? 0,
        totalAmount: json['totalAmount'] as int? ?? 0,
        appVersion: json['appVersion'] as String? ?? '2.0.0',
        deviceInfo: json['deviceInfo'] as String?,
        notes: json['notes'] as String?,
      );
}

/// Complete backup data (v2.0 includes accounts + holdings).
/// [isLegacy] is true when loaded from a v1.0 backup that lacks those fields.
class BackupData {
  final BackupMetadata metadata;
  final List<ExpenseItem> expenses;
  final List<FixedItem> fixedItems;
  final List<Account> accounts;
  final List<StockHolding> holdings;
  final Map<String, dynamic>? settings;
  final bool isLegacy;

  BackupData({
    required this.metadata,
    required this.expenses,
    required this.fixedItems,
    this.accounts = const [],
    this.holdings = const [],
    this.settings,
    this.isLegacy = false,
  });

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'fixedItems': fixedItems.map((f) => f.toJson()).toList(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'holdings': holdings.map((h) => h.toJson()).toList(),
        'settings': settings,
      };

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

    // v1.0 backups don't have 'accounts' → mark as legacy
    final isLegacy = !json.containsKey('accounts');

    final accountsJson = json['accounts'] as List? ?? [];
    final accounts = accountsJson
        .map((a) => Account.fromJson(a as Map<String, dynamic>))
        .toList();

    final holdingsJson = json['holdings'] as List? ?? [];
    final holdings = holdingsJson
        .map((h) => StockHolding.fromJson(h as Map<String, dynamic>))
        .toList();

    return BackupData(
      metadata: meta,
      expenses: expenses,
      fixedItems: fixedItems,
      accounts: accounts,
      holdings: holdings,
      settings: json['settings'] as Map<String, dynamic>?,
      isLegacy: isLegacy,
    );
  }
}
