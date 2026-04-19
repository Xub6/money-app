import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/expense_item.dart';
import '../models/fixed_item.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/app_exceptions.dart';
import 'app_database.dart';

/// Helper class for migrating data from SharedPreferences to SQLite
class MigrationHelper {
  static const String _migratedKey = 'app_migrated_to_sqlite';

  /// Check if migration has been done
  static Future<bool> hasMigrated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migratedKey) ?? false;
    } catch (e) {
      AppLogger.warning('Failed to check migration status', error: e);
      return false;
    }
  }

  /// Migrate all data from SharedPreferences to SQLite
  static Future<MigrationResult> migrateFromSharedPreferences() async {
    try {
      AppLogger.info('Starting migration from SharedPreferences to SQLite...');

      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase();

      // Check if already migrated
      if (await hasMigrated()) {
        AppLogger.info('Database already migrated');
        return MigrationResult(
          success: true,
          expensesCount: 0,
          fixedItemsCount: 0,
          message: 'Already migrated',
        );
      }

      int expensesMigrated = 0;
      int fixedItemsMigrated = 0;

      // Migrate expenses
      try {
        final expensesJson = prefs.getString('expenses');
        if (expensesJson != null && expensesJson.isNotEmpty) {
          final list = jsonDecode(expensesJson) as List;
          for (final json in list) {
            try {
              final expense = ExpenseItem.fromJson(json as Map<String, dynamic>);
              await db.insertExpense(expense);
              expensesMigrated++;
            } catch (e) {
              AppLogger.warning('Failed to migrate expense: $json', error: e);
            }
          }
        }
        AppLogger.info('Migrated $expensesMigrated expenses');
      } catch (e) {
        AppLogger.error('Failed to migrate expenses', error: e);
        throw DataException(
          message: '遷移支出失敗',
          originalException: e,
        );
      }

      // Migrate fixed items
      try {
        final fixedJson = prefs.getString('fixed');
        if (fixedJson != null && fixedJson.isNotEmpty) {
          final list = jsonDecode(fixedJson) as List;
          for (final json in list) {
            try {
              final fixed = FixedItem.fromJson(json as Map<String, dynamic>);
              await db.insertFixedItem(fixed);
              fixedItemsMigrated++;
            } catch (e) {
              AppLogger.warning('Failed to migrate fixed item: $json', error: e);
            }
          }
        }
        AppLogger.info('Migrated $fixedItemsMigrated fixed items');
      } catch (e) {
        AppLogger.error('Failed to migrate fixed items', error: e);
        throw DataException(
          message: '遷移固定開銷失敗',
          originalException: e,
        );
      }

      // Migrate metadata
      try {
        final budget = prefs.getInt('budget');
        if (budget != null) {
          await db.setMetadata('budget', budget.toString());
        }

        final streak = prefs.getInt('streak');
        if (streak != null) {
          await db.setMetadata('streak', streak.toString());
        }

        final lastDate = prefs.getString('lastDate');
        if (lastDate != null) {
          await db.setMetadata('lastDate', lastDate);
        }
      } catch (e) {
        AppLogger.warning('Failed to migrate metadata', error: e);
      }

      // Mark as migrated
      await prefs.setBool(_migratedKey, true);

      AppLogger.info(
        'Migration completed: $expensesMigrated expenses, $fixedItemsMigrated fixed items',
      );

      return MigrationResult(
        success: true,
        expensesCount: expensesMigrated,
        fixedItemsCount: fixedItemsMigrated,
        message: '成功遷移 $expensesMigrated 筆支出和 $fixedItemsMigrated 項固定開銷',
      );
    } catch (e) {
      AppLogger.error('Migration failed', error: e);
      throw DataException(
        message: '數據遷移失敗：$e',
        originalException: e,
      );
    }
  }

  /// Validate migration by comparing counts
  static Future<bool> validateMigration({
    required int expectedExpenseCount,
    required int expectedFixedCount,
  }) async {
    try {
      final db = AppDatabase();
      final expenses = await db.getAllExpenses();
      final fixedItems = await db.getAllFixedItems();

      final expensesMatch = expenses.length == expectedExpenseCount;
      final fixedMatch = fixedItems.length == expectedFixedCount;

      if (expensesMatch && fixedMatch) {
        AppLogger.info('Migration validation passed');
        return true;
      } else {
        AppLogger.warning(
          'Migration validation failed: '
          'expected $expectedExpenseCount expenses, got ${expenses.length}; '
          'expected $expectedFixedCount fixed, got ${fixedItems.length}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Migration validation failed', error: e);
      return false;
    }
  }

  /// Rollback by clearing SQLite and unmarking migration
  static Future<void> rollback() async {
    try {
      AppLogger.warning('Rolling back migration...');
      final db = AppDatabase();
      await db.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migratedKey);

      AppLogger.info('Migration rolled back');
    } catch (e) {
      AppLogger.error('Rollback failed', error: e);
      throw DataException(
        message: '回滾失敗',
        originalException: e,
      );
    }
  }

  /// Create backup of SharedPreferences before migration
  static Future<String> backupSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backup = <String, dynamic>{};

      // Copy all preferences
      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);
        backup[key] = value;
      }

      AppLogger.info('SharedPreferences backup created with ${backup.length} entries');
      return jsonEncode(backup);
    } catch (e) {
      AppLogger.error('Failed to backup SharedPreferences', error: e);
      return '';
    }
  }
}

/// Result of migration operation
class MigrationResult {
  final bool success;
  final int expensesCount;
  final int fixedItemsCount;
  final String message;
  final DateTime timestamp;

  MigrationResult({
    required this.success,
    required this.expensesCount,
    required this.fixedItemsCount,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'MigrationResult(success: $success, '
      'expenses: $expensesCount, fixed: $fixedItemsCount, '
      'message: $message)';
}
