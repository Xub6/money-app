import 'dart:convert';
import 'package:http/http.dart' as http;

class StockQuote {
  final String symbol;
  final String name;
  final double price;
  final String currency;

  const StockQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.currency,
  });
}

class StockSearchResult {
  final String symbol;
  final String name;
  final String exchange;

  const StockSearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
  });
}

class StockService {
  static const _headers = {'User-Agent': 'Mozilla/5.0'};
  static const _timeout = Duration(seconds: 8);

  static String toYahooSymbol(String code, bool isTwd) =>
      isTwd ? '${code.toUpperCase()}.TW' : code.toUpperCase();

  /// Fetch real-time quote from Yahoo Finance
  static Future<StockQuote?> fetchQuote(String code, bool isTwd) async {
    final symbol = toYahooSymbol(code, isTwd);
    final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d');
    try {
      final resp =
          await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final result = (data['chart']?['result'] as List?)?.firstOrNull;
      if (result == null) return null;
      final meta = result['meta'] as Map<String, dynamic>?;
      final price = (meta?['regularMarketPrice'] as num?)?.toDouble();
      if (price == null) return null;

      // 台股優先用 TWSE 取中文名稱
      String name = (meta?['shortName'] ?? meta?['longName'] ?? code) as String;
      if (isTwd) {
        final chineseName = await _fetchTwseNameByCode(code);
        if (chineseName != null) name = chineseName;
      }

      return StockQuote(
        symbol: symbol,
        name: name,
        price: price,
        currency: (meta?['currency'] ?? (isTwd ? 'TWD' : 'USD')) as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch live USD/TWD exchange rate from Yahoo Finance
  static Future<double?> fetchUsdTwdRate() async {
    final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/USDTWD=X?interval=1d&range=1d');
    try {
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final result = (data['chart']?['result'] as List?)?.firstOrNull;
      final meta = result?['meta'] as Map<String, dynamic>?;
      final price = (meta?['regularMarketPrice'] as num?)?.toDouble();
      return price;
    } catch (_) {
      return null;
    }
  }

  /// 用股票代碼向 TWSE 查中文名稱
  static Future<String?> _fetchTwseNameByCode(String code) async {
    final results = await _searchTwse(code);
    try {
      return results.firstWhere((r) => r.symbol == code).name;
    } catch (_) {
      return null;
    }
  }

  /// Search Taiwan stocks via TWSE codeQuery (supports Chinese name search)
  static Future<List<StockSearchResult>> _searchTwse(String query) async {
    final q = Uri.encodeComponent(query);
    final uri = Uri.parse('https://www.twse.com.tw/rwd/zh/api/codeQuery?query=$q');
    try {
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List?) ?? [];
      return suggestions
          .where((s) => s != 'more')
          .map((s) {
            final str = s as String;
            final parts = str.split('\t');
            if (parts.length < 2) return null;
            final sym = parts[0].trim();
            // 只保留正股（4碼首位1-9）和 ETF（00 開頭）
            final isStock = RegExp(r'^[1-9]\d{3}$').hasMatch(sym);
            final isEtf = RegExp(r'^00\d+$').hasMatch(sym);
            if (!isStock && !isEtf) return null;
            return StockSearchResult(
              symbol: sym,
              name: parts[1].trim(),
              exchange: 'TWSE',
            );
          })
          .whereType<StockSearchResult>()
          .take(8)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Search US stocks via Yahoo Finance
  static Future<List<StockSearchResult>> _searchYahoo(String query) async {
    final q = Uri.encodeComponent(query);
    final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=$q&quotesCount=8&newsCount=0&lang=en-US');
    try {
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final quotes = (data['quotes'] as List?) ?? [];
      return quotes
          .where((q) => q['quoteType'] == 'EQUITY')
          .where((q) => !((q['symbol'] as String?) ?? '').contains('.'))
          .map((q) => StockSearchResult(
                symbol: (q['symbol'] as String),
                name: (q['shortname'] ?? q['longname'] ?? q['symbol']) as String,
                exchange: (q['exchange'] ?? '') as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Search stocks by keyword (for autocomplete)
  static Future<List<StockSearchResult>> search(
      String query, bool isTwd) async {
    if (query.isEmpty) return [];
    return isTwd ? _searchTwse(query) : _searchYahoo(query);
  }

  /// Fetch quotes for multiple symbols, returns Map<id, quote>
  static Future<Map<String, StockQuote>> fetchBatch(
      List<({String id, String code, bool isTwd})> items) async {
    final results = <String, StockQuote>{};
    await Future.wait(items.map((item) async {
      final q = await fetchQuote(item.code, item.isTwd);
      if (q != null) results[item.id] = q;
    }));
    return results;
  }
}
