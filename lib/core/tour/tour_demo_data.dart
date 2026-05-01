import '../../data/models/expense_item.dart';
import '../../data/models/fixed_item.dart';
import '../../data/models/stock_holding.dart';
import '../../data/models/account.dart';

const _p = 'tour_demo_';

bool isTourDemoId(String id) => id.startsWith(_p);

List<ExpenseItem> buildDemoExpenses() {
  final now = DateTime.now();
  final m = now.month;
  final y = now.year;
  return [
    ExpenseItem(id: '${_p}e1', title: '家庭聚餐',    category: '餐飲', amount: 1280, date: DateTime(y, m, 3)),
    ExpenseItem(id: '${_p}e2', title: '捷運月票',    category: '交通', amount: 1280, date: DateTime(y, m, 1)),
    ExpenseItem(id: '${_p}e3', title: 'Netflix 月費',category: '娛樂', amount:  390, date: DateTime(y, m, 5)),
    ExpenseItem(id: '${_p}e4', title: '課程教材',    category: '教育', amount:  850, date: DateTime(y, m, 8)),
    ExpenseItem(id: '${_p}e5', title: '秋季新衣',    category: '購物', amount: 2490, date: DateTime(y, m, 10)),
    ExpenseItem(id: '${_p}e6', title: '健身房月費',  category: '醫療', amount:  600, date: DateTime(y, m, 2)),
    ExpenseItem(id: '${_p}e7', title: '早午餐',      category: '餐飲', amount:  320, date: DateTime(y, m, 12)),
    ExpenseItem(id: '${_p}e8', title: '計程車',      category: '交通', amount:  250, date: DateTime(y, m, 7)),
  ];
}

List<StockHolding> buildDemoHoldings() => [
  StockHolding(
    id: '${_p}h1',
    code: '2330',
    name: '台積電',
    shares: 10,
    totalCost: 7800,
    currency: StockCurrency.twd,
    purchaseDate: DateTime(2024, 6, 1),
    currentPrice: 850,
  ),
  StockHolding(
    id: '${_p}h2',
    code: 'AAPL',
    name: 'Apple Inc.',
    shares: 5,
    totalCost: 28000,
    currency: StockCurrency.usd,
    purchaseDate: DateTime(2024, 9, 15),
    currentPrice: 195,
  ),
  StockHolding(
    id: '${_p}h3',
    code: '0050',
    name: '元大台灣50',
    shares: 20,
    totalCost: 38000,
    currency: StockCurrency.twd,
    purchaseDate: DateTime(2024, 3, 20),
    currentPrice: 205,
  ),
];

List<FixedItem> buildDemoFixed() {
  final now = DateTime.now();
  return [
    FixedItem(
      id: '${_p}f1',
      title: '房租',
      amount: 15000,
      category: '住居',
      startDate: DateTime(now.year, now.month - 3, 1),
    ),
    FixedItem(
      id: '${_p}f2',
      title: 'Spotify 訂閱',
      amount: 179,
      category: '娛樂',
      startDate: DateTime(now.year, 1, 1),
    ),
    FixedItem(
      id: '${_p}f3',
      title: '手機月租費',
      amount: 699,
      category: '其他',
      startDate: DateTime(now.year - 1, 6, 1),
    ),
  ];
}

List<Account> buildDemoAccounts() => [
  Account(
    id: '${_p}a1',
    typeName: '銀行帳戶',
    customName: '台新銀行',
    category: AccountCategory.savings,
    balance: 85000,
    currency: 'TWD',
  ),
  Account(
    id: '${_p}a2',
    typeName: 'Line Pay',
    customName: '',
    category: AccountCategory.savings,
    balance: 3200,
    currency: 'TWD',
  ),
  Account(
    id: '${_p}a3',
    typeName: '信用卡',
    customName: 'VISA 卡',
    category: AccountCategory.credit,
    balance: -12500,
    currency: 'TWD',
  ),
];
