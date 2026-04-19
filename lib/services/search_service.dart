import 'dart:async';
import '../data/models/expense_item.dart';
import '../data/models/fixed_item.dart';
import '../data/models/backup_metadata.dart';
import '../core/utils/logger.dart';

/// Service for searching expenses and fixed items
class SearchService {
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  /// Search expenses with multiple filters
  Future<List<SearchResult>> searchExpenses(
    List<ExpenseItem> expenses, {
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    int? minAmount,
    int? maxAmount,
    String sortBy = 'relevance', // 'relevance', 'date', 'amount'
  }) async {
    try {
      final results = <SearchResult>[];

      for (final expense in expenses) {
        // Apply date filter
        if (startDate != null && expense.date.isBefore(startDate)) continue;
        if (endDate != null && expense.date.isAfter(endDate)) continue;

        // Apply category filter
        if (categories != null && !categories.contains(expense.category)) {
          continue;
        }

        // Apply amount filter
        if (minAmount != null && expense.amount < minAmount) continue;
        if (maxAmount != null && expense.amount > maxAmount) continue;

        // Calculate relevance
        final relevance = _calculateRelevance(
          expense.title,
          expense.note,
          expense.category,
          query,
        );

        // Add to results if matches
        if (relevance > 0) {
          results.add(SearchResult(
            id: expense.id,
            type: 'expense',
            item: expense,
            relevance: relevance,
            matchedFields: _getMatchedFields(
              expense.title,
              expense.note,
              query,
            ),
          ));
        }
      }

      // Sort results
      results.sort((a, b) {
        if (sortBy == 'relevance') {
          return b.relevance.compareTo(a.relevance);
        } else if (sortBy == 'date') {
          return (b.item as ExpenseItem).date.compareTo(
            (a.item as ExpenseItem).date,
          );
        } else if (sortBy == 'amount') {
          return (b.item as ExpenseItem).amount.compareTo(
            (a.item as ExpenseItem).amount,
          );
        }
        return 0;
      });

      AppLogger.info('Search completed: ${results.length} results found');
      return results;
    } catch (e) {
      AppLogger.error('Search failed', error: e);
      rethrow;
    }
  }

  /// Calculate relevance score (0.0 to 1.0)
  double _calculateRelevance(
    String title,
    String note,
    String category,
    String query,
  ) {
    final lowerQuery = query.toLowerCase();
    final lowerTitle = title.toLowerCase();
    final lowerNote = note.toLowerCase();
    final lowerCategory = category.toLowerCase();

    double relevance = 0.0;

    // Title exact match
    if (lowerTitle == lowerQuery) {
      relevance += 1.0;
    }
    // Title contains
    else if (lowerTitle.contains(lowerQuery)) {
      relevance += 0.8;
    }
    // Title starts with
    else if (lowerTitle.startsWith(lowerQuery)) {
      relevance += 0.85;
    }

    // Note contains
    if (lowerNote.contains(lowerQuery)) {
      relevance += 0.5;
    }

    // Category match
    if (lowerCategory.contains(lowerQuery)) {
      relevance += 0.3;
    }

    return relevance.clamp(0.0, 1.0);
  }

  /// Get which fields matched the query
  List<String> _getMatchedFields(String title, String note, String query) {
    final matched = <String>[];
    final lowerQuery = query.toLowerCase();

    if (title.toLowerCase().contains(lowerQuery)) {
      matched.add('title');
    }
    if (note.toLowerCase().contains(lowerQuery)) {
      matched.add('note');
    }

    return matched;
  }

  /// Search fixed items
  Future<List<SearchResult>> searchFixedItems(
    List<FixedItem> fixedItems, {
    required String query,
    bool? isActive,
    List<String>? categories,
  }) async {
    try {
      final results = <SearchResult>[];

      for (final item in fixedItems) {
        // Apply active filter
        if (isActive != null && item.isActive != isActive) continue;

        // Apply category filter
        if (categories != null && !categories.contains(item.category)) {
          continue;
        }

        // Calculate relevance
        final lowerQuery = query.toLowerCase();
        final lowerTitle = item.title.toLowerCase();
        final lowerNote = item.notes?.toLowerCase() ?? '';

        double relevance = 0.0;

        if (lowerTitle == lowerQuery) {
          relevance = 1.0;
        } else if (lowerTitle.contains(lowerQuery)) {
          relevance = 0.8;
        } else if (lowerTitle.startsWith(lowerQuery)) {
          relevance = 0.85;
        }

        if (lowerNote.contains(lowerQuery)) {
          relevance = (relevance + 0.5).clamp(0.0, 1.0);
        }

        if (relevance > 0) {
          results.add(SearchResult(
            id: item.id,
            type: 'fixed',
            item: item,
            relevance: relevance,
            matchedFields: [],
          ));
        }
      }

      // Sort by relevance
      results.sort((a, b) => b.relevance.compareTo(a.relevance));

      return results;
    } catch (e) {
      AppLogger.error('Search fixed items failed', error: e);
      rethrow;
    }
  }

  /// Combined search across both expenses and fixed items
  Future<List<SearchResult>> searchAll(
    List<ExpenseItem> expenses,
    List<FixedItem> fixedItems, {
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
  }) async {
    try {
      final expenseResults = await searchExpenses(
        expenses,
        query: query,
        startDate: startDate,
        endDate: endDate,
        categories: categories,
      );

      final fixedResults = await searchFixedItems(
        fixedItems,
        query: query,
        categories: categories,
      );

      // Combine and sort by relevance
      final combined = [...expenseResults, ...fixedResults];
      combined.sort((a, b) => b.relevance.compareTo(a.relevance));

      return combined;
    } catch (e) {
      AppLogger.error('Combined search failed', error: e);
      rethrow;
    }
  }

  /// Get suggestions based on partial query
  Future<List<String>> getSuggestions(
    List<ExpenseItem> expenses, {
    required String partialQuery,
    int limit = 10,
  }) async {
    try {
      final suggestions = <String>{};
      final lowerQuery = partialQuery.toLowerCase();

      for (final expense in expenses) {
        if (expense.title.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(expense.title);
        }
        if (expense.note.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(expense.note);
        }
      }

      return suggestions.toList()..sort().take(limit);
    } catch (e) {
      AppLogger.error('Get suggestions failed', error: e);
      return [];
    }
  }
}
