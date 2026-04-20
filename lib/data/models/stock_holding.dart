import 'package:uuid/uuid.dart';

enum StockCurrency { twd, usd }

class StockHolding {
  final String id;
  final String code;
  final String name;
  final double shares;
  final double totalCost; // in TWD
  final StockCurrency currency;
  final DateTime purchaseDate;
  double currentPrice; // per share, in original currency
  final String buyReason;
  final String sellStrategy;
  final DateTime createdAt;

  StockHolding({
    String? id,
    required this.code,
    this.name = '',
    required this.shares,
    required this.totalCost,
    this.currency = StockCurrency.twd,
    required this.purchaseDate,
    this.currentPrice = 0,
    this.buyReason = '',
    this.sellStrategy = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double currentValueTwd(double usdTwd) {
    if (currency == StockCurrency.usd) {
      return shares * currentPrice * usdTwd;
    }
    return shares * currentPrice;
  }

  double profitTwd(double usdTwd) => currentValueTwd(usdTwd) - totalCost;

  double profitPct(double usdTwd) {
    if (totalCost == 0) return 0;
    return profitTwd(usdTwd) / totalCost * 100;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'shares': shares,
        'totalCost': totalCost,
        'currency': currency.name,
        'purchaseDate': purchaseDate.toIso8601String(),
        'currentPrice': currentPrice,
        'buyReason': buyReason,
        'sellStrategy': sellStrategy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StockHolding.fromJson(Map<String, dynamic> j) => StockHolding(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String? ?? '',
        shares: (j['shares'] as num).toDouble(),
        totalCost: (j['totalCost'] as num).toDouble(),
        currency: j['currency'] == 'usd' ? StockCurrency.usd : StockCurrency.twd,
        purchaseDate: DateTime.parse(j['purchaseDate'] as String),
        currentPrice: (j['currentPrice'] as num?)?.toDouble() ?? 0,
        buyReason: j['buyReason'] as String? ?? '',
        sellStrategy: j['sellStrategy'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  StockHolding copyWith({double? currentPrice, String? name}) => StockHolding(
        id: id,
        code: code,
        name: name ?? this.name,
        shares: shares,
        totalCost: totalCost,
        currency: currency,
        purchaseDate: purchaseDate,
        currentPrice: currentPrice ?? this.currentPrice,
        buyReason: buyReason,
        sellStrategy: sellStrategy,
        createdAt: createdAt,
      );
}
