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
      return StockQuote(
        symbol: symbol,
        name: (meta?['shortName'] ?? meta?['longName'] ?? code) as String,
        price: price,
        currency: (meta?['currency'] ?? (isTwd ? 'TWD' : 'USD')) as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Search stocks by keyword (for autocomplete)
  static Future<List<StockSearchResult>> search(
      String query, bool isTwd) async {
    if (query.isEmpty) return [];
    final q = Uri.encodeComponent(isTwd ? '$query.TW' : query);
    final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=$q&quotesCount=8&newsCount=0&lang=en-US');
    try {
      final resp =
          await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final quotes = (data['quotes'] as List?) ?? [];
      return quotes
          .where((q) => q['quoteType'] == 'EQUITY')
          .where((q) {
            final sym = (q['symbol'] as String?) ?? '';
            return isTwd
                ? sym.endsWith('.TW') || sym.endsWith('.TWO')
                : !sym.contains('.');
          })
          .map((q) {
            final raw = (q['symbol'] as String);
            final cleanSym =
                raw.replaceAll('.TW', '').replaceAll('.TWO', '');
            return StockSearchResult(
              symbol: cleanSym,
              name: (q['shortname'] ?? q['longname'] ?? cleanSym) as String,
              exchange: (q['exchange'] ?? '') as String,
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
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
