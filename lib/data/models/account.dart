import 'package:uuid/uuid.dart';

enum AccountCategory { savings, credit }

class AccountTypeOption {
  final String name;
  final String icon;
  final AccountCategory category;
  const AccountTypeOption(this.name, this.icon, this.category);
}

const kAccountTypes = [
  AccountTypeOption('現金',     '💵', AccountCategory.savings),
  AccountTypeOption('銀行帳戶', '🏦', AccountCategory.savings),
  AccountTypeOption('Line Pay', '💚', AccountCategory.savings),
  AccountTypeOption('街口支付', '🟠', AccountCategory.savings),
  AccountTypeOption('悠遊卡',   '🔵', AccountCategory.savings),
  AccountTypeOption('icash',    '🔴', AccountCategory.savings),
  AccountTypeOption('iPass',    '🟡', AccountCategory.savings),
  AccountTypeOption('儲蓄卡',   '💳', AccountCategory.savings),
  AccountTypeOption('其他',     '👜', AccountCategory.savings),
  AccountTypeOption('信用卡',   '💳', AccountCategory.credit),
  AccountTypeOption('欠款',     '📋', AccountCategory.credit),
  AccountTypeOption('其他',     '💰', AccountCategory.credit),
];

const kCurrencies = [
  ('TWD', 'NT\$'),
  ('USD', '\$'),
  ('JPY', '¥'),
  ('EUR', '€'),
  ('GBP', '£'),
  ('CNY', '¥'),
  ('HKD', 'HK\$'),
];

class Account {
  final String id;
  final String typeName;
  final String customName;
  final AccountCategory category;
  final double balance;
  final String currency;
  final String note;
  final bool countInTotal;
  final DateTime createdAt;

  Account({
    String? id,
    required this.typeName,
    this.customName = '',
    required this.category,
    required this.balance,
    this.currency = 'TWD',
    this.note = '',
    this.countInTotal = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get displayName => customName.isNotEmpty ? customName : typeName;

  String get currencySymbol =>
      kCurrencies.firstWhere((c) => c.$1 == currency, orElse: () => ('TWD', 'NT\$')).$2;

  double balanceTwd(Map<String, double> fxRates) {
    if (currency == 'TWD') return balance;
    final rate = fxRates[currency] ?? 1.0;
    return balance * rate;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeName': typeName,
        'customName': customName,
        'category': category.name,
        'balance': balance,
        'currency': currency,
        'note': note,
        'countInTotal': countInTotal,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        typeName: j['typeName'] as String,
        customName: j['customName'] as String? ?? '',
        category: j['category'] == 'credit'
            ? AccountCategory.credit
            : AccountCategory.savings,
        balance: (j['balance'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'TWD',
        note: j['note'] as String? ?? '',
        countInTotal: j['countInTotal'] as bool? ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Account copyWith({
    String? typeName,
    String? customName,
    AccountCategory? category,
    double? balance,
    String? currency,
    String? note,
    bool? countInTotal,
  }) =>
      Account(
        id: id,
        typeName: typeName ?? this.typeName,
        customName: customName ?? this.customName,
        category: category ?? this.category,
        balance: balance ?? this.balance,
        currency: currency ?? this.currency,
        note: note ?? this.note,
        countInTotal: countInTotal ?? this.countInTotal,
        createdAt: createdAt,
      );
}
