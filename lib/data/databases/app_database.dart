import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense_item.dart';
import '../models/fixed_item.dart';
import '../../core/utils/logger.dart';

/// SQLite database initialization and schema
class AppDatabase {
  static const String _databaseName = 'money_app.db';
  static const int _version = 1;

  static const String _expensesTable = 'expenses';
  static const String _fixedItemsTable = 'fixed_items';
  static const String _metadataTable = 'metadata';

  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);

      AppLogger.info('Opening database at: $path');

      return await openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      AppLogger.error('Failed to initialize database', error: e);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      AppLogger.info('Creating database schema v$version');

      // Expenses table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_expensesTable (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          amount INTEGER NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          edited_at TEXT,
          sync_status TEXT DEFAULT 'local',
          attachment_path TEXT,
          metadata TEXT
        )
      ''');

      // Create indexes for better performance
      await db.execute('CREATE INDEX idx_expenses_date ON $_expensesTable(date)');
      await db.execute('CREATE INDEX idx_expenses_category ON $_expensesTable(category)');
      await db.execute('CREATE INDEX idx_expenses_created_at ON $_expensesTable(created_at)');

      // Fixed items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_fixedItemsTable (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount INTEGER NOT NULL,
          category TEXT DEFAULT '其他',
          start_date TEXT NOT NULL,
          end_date TEXT,
          renewal_cycle TEXT DEFAULT 'monthly',
          created_at TEXT NOT NULL,
          edited_at TEXT,
          is_active INTEGER DEFAULT 1,
          sync_status TEXT DEFAULT 'local',
          notes TEXT
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX idx_fixed_is_active ON $_fixedItemsTable(is_active)');
      await db.execute('CREATE INDEX idx_fixed_created_at ON $_fixedItemsTable(created_at)');

      // Metadata table (for app-level data)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_metadataTable (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      AppLogger.info('Database schema created successfully');
    } catch (e) {
      AppLogger.error('Failed to create database schema', error: e);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      AppLogger.info('Upgrading database from v$oldVersion to v$newVersion');
      // Handle future schema migrations here
    } catch (e) {
      AppLogger.error('Database upgrade failed', error: e);
      rethrow;
    }
  }

  // ─── Expenses Operations ───

  Future<String> insertExpense(ExpenseItem item) async {
    try {
      final db = await database;
      await db.insert(
        _expensesTable,
        item.toDatabaseJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.debug('Expense inserted: ${item.id}');
      return item.id;
    } catch (e) {
      AppLogger.error('Failed to insert expense', error: e);
      rethrow;
    }
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    try {
      final db = await database;
      final maps = await db.query(
        _expensesTable,
        orderBy: 'date DESC, created_at DESC',
      );
      return maps.map((m) => ExpenseItem.fromDatabase(m)).toList();
    } catch (e) {
      AppLogger.error('Failed to get all expenses', error: e);
      return [];
    }
  }

  Future<List<ExpenseItem>> getExpensesByMonth(DateTime month) async {
    try {
      final db = await database;
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final maps = await db.query(
        _expensesTable,
        where: 'date >= ? AND date <= ?',
        whereArgs: [
          firstDay.toIso8601String(),
          lastDay.toIso8601String(),
        ],
        orderBy: 'date DESC',
      );
      return maps.map((m) => ExpenseItem.fromDatabase(m)).toList();
    } catch (e) {
      AppLogger.error('Failed to get expenses by month', error: e);
      return [];
    }
  }

  Future<ExpenseItem?> getExpense(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        _expensesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      return maps.isNotEmpty ? ExpenseItem.fromDatabase(maps[0]) : null;
    } catch (e) {
      AppLogger.error('Failed to get expense', error: e);
      return null;
    }
  }

  Future<void> updateExpense(ExpenseItem item) async {
    try {
      final db = await database;
      await db.update(
        _expensesTable,
        item.toDatabaseJson(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      AppLogger.debug('Expense updated: ${item.id}');
    } catch (e) {
      AppLogger.error('Failed to update expense', error: e);
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final db = await database;
      await db.delete(
        _expensesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.debug('Expense deleted: $id');
    } catch (e) {
      AppLogger.error('Failed to delete expense', error: e);
      rethrow;
    }
  }

  // ─── Fixed Items Operations ───

  Future<String> insertFixedItem(FixedItem item) async {
    try {
      final db = await database;
      await db.insert(
        _fixedItemsTable,
        item.toDatabaseJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.debug('Fixed item inserted: ${item.id}');
      return item.id;
    } catch (e) {
      AppLogger.error('Failed to insert fixed item', error: e);
      rethrow;
    }
  }

  Future<List<FixedItem>> getActiveFixedItems() async {
    try {
      final db = await database;
      final maps = await db.query(
        _fixedItemsTable,
        where: 'is_active = 1',
        orderBy: 'created_at DESC',
      );
      return maps.map((m) => FixedItem.fromDatabase(m)).toList();
    } catch (e) {
      AppLogger.error('Failed to get active fixed items', error: e);
      return [];
    }
  }

  Future<List<FixedItem>> getAllFixedItems() async {
    try {
      final db = await database;
      final maps = await db.query(
        _fixedItemsTable,
        orderBy: 'created_at DESC',
      );
      return maps.map((m) => FixedItem.fromDatabase(m)).toList();
    } catch (e) {
      AppLogger.error('Failed to get all fixed items', error: e);
      return [];
    }
  }

  Future<void> updateFixedItem(FixedItem item) async {
    try {
      final db = await database;
      await db.update(
        _fixedItemsTable,
        item.toDatabaseJson(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      AppLogger.debug('Fixed item updated: ${item.id}');
    } catch (e) {
      AppLogger.error('Failed to update fixed item', error: e);
      rethrow;
    }
  }

  Future<void> deleteFixedItem(String id) async {
    try {
      final db = await database;
      await db.delete(
        _fixedItemsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.debug('Fixed item deleted: $id');
    } catch (e) {
      AppLogger.error('Failed to delete fixed item', error: e);
      rethrow;
    }
  }

  // ─── Metadata Operations ───

  Future<void> setMetadata(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        _metadataTable,
        {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      AppLogger.error('Failed to set metadata', error: e);
    }
  }

  Future<String?> getMetadata(String key) async {
    try {
      final db = await database;
      final maps = await db.query(
        _metadataTable,
        where: 'key = ?',
        whereArgs: [key],
      );
      return maps.isNotEmpty ? maps[0]['value'] as String? : null;
    } catch (e) {
      AppLogger.error('Failed to get metadata', error: e);
      return null;
    }
  }

  // ─── Utility ───

  Future<void> clear() async {
    try {
      final db = await database;
      await db.delete(_expensesTable);
      await db.delete(_fixedItemsTable);
      AppLogger.info('Database cleared');
    } catch (e) {
      AppLogger.error('Failed to clear database', error: e);
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
      AppLogger.info('Database closed');
    } catch (e) {
      AppLogger.error('Failed to close database', error: e);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await database;
      final expenseCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_expensesTable'),
      ) ?? 0;
      final fixedCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_fixedItemsTable'),
      ) ?? 0;

      return {
        'expenses': expenseCount,
        'fixedItems': fixedCount,
        'totalSize': (await _getDatabaseFileSize()),
      };
    } catch (e) {
      AppLogger.error('Failed to get database stats', error: e);
      return {};
    }
  }

  Future<int> _getDatabaseFileSize() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

// Required imports
import 'package:path/path.dart';
import 'dart:io';
