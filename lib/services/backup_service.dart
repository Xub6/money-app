import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../data/models/expense_item.dart';
import '../data/models/fixed_item.dart';
import '../data/models/backup_metadata.dart';
import '../core/utils/logger.dart';
import '../core/utils/app_exceptions.dart';

/// Service for handling backup and restore operations
class BackupService {
  static const String _backupDirName = 'Money_App_Backups';

  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${documentsDir.path}/$_backupDirName');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir;
    } catch (e) {
      throw BackupException(
        message: '無法獲取備份目錄',
        originalException: e,
      );
    }
  }

  /// Export data as JSON backup
  Future<String> exportBackup({
    required List<ExpenseItem> expenses,
    required List<FixedItem> fixedItems,
    int? budget,
    String? notes,
  }) async {
    try {
      AppLogger.info('Starting backup export...');

      // Calculate total
      final totalAmount = expenses.fold<int>(
        0,
        (sum, e) => sum + e.amount,
      );

      // Create metadata
      final metadata = BackupMetadata(
        expenseCount: expenses.length,
        fixedCount: fixedItems.length,
        totalAmount: totalAmount,
        notes: notes,
      );

      // Create backup data
      final backupData = BackupData(
        metadata: metadata,
        expenses: expenses,
        fixedItems: fixedItems,
        settings: budget != null ? {'budget': budget} : null,
      );

      // Convert to JSON
      final jsonData = backupData.toJson();
      final jsonString = jsonEncode(jsonData);

      // Save to file
      final backupDir = await _getBackupDirectory();
      final filename = metadata.filename;
      final backupFile = File('${backupDir.path}/$filename');
      await backupFile.writeAsString(jsonString);

      AppLogger.info('Backup exported successfully: $filename');
      return filename;
    } catch (e) {
      AppLogger.error('Backup export failed', error: e);
      throw BackupException(
        message: '導出備份失敗',
        originalException: e,
      );
    }
  }

  /// Import backup from file
  Future<BackupData> importBackup(String filename) async {
    try {
      AppLogger.info('Importing backup: $filename');

      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/$filename');

      if (!await backupFile.exists()) {
        throw BackupException(message: '備份文件不存在');
      }

      // Read file
      final jsonString = await backupFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse backup data
      final backupData = BackupData.fromJson(jsonData);

      // Validate version compatibility
      if (backupData.metadata.version != '1.0') {
        AppLogger.warning(
          'Backup version mismatch: ${backupData.metadata.version}',
        );
      }

      AppLogger.info('Backup imported successfully');
      return backupData;
    } catch (e) {
      AppLogger.error('Backup import failed', error: e);
      throw BackupException(
        message: '導入備份失敗: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// Get list of available backups
  Future<List<BackupMetadata>> getBackupList() async {
    try {
      final backupDir = await _getBackupDirectory();
      final files = await backupDir.list().toList();

      final backups = <BackupMetadata>[];
      for (final file in files) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await File(file.path).readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            final metadata = BackupMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>,
            );
            backups.add(metadata);
          } catch (e) {
            AppLogger.warning('Failed to parse backup: ${file.path}');
          }
        }
      }

      // Sort by date descending
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return backups;
    } catch (e) {
      AppLogger.error('Failed to get backup list', error: e);
      return [];
    }
  }

  /// Delete backup file
  Future<void> deleteBackup(String filename) async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/$filename');
      if (await backupFile.exists()) {
        await backupFile.delete();
        AppLogger.info('Backup deleted: $filename');
      }
    } catch (e) {
      AppLogger.error('Failed to delete backup', error: e);
      throw BackupException(
        message: '刪除備份失敗',
        originalException: e,
      );
    }
  }

  /// Get backup file details
  Future<FileSystemEntity?> getBackupFile(String filename) async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/$filename');
      if (await backupFile.exists()) {
        return backupFile;
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get backup file', error: e);
      return null;
    }
  }

  /// Get backup file size in KB
  Future<double> getBackupFileSize(String filename) async {
    try {
      final file = await getBackupFile(filename);
      if (file != null && file is File) {
        final size = await file.length();
        return size / 1024; // Convert to KB
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Clean old backups (keep only last N backups)
  Future<void> cleanOldBackups({int keepCount = 7}) async {
    try {
      final backups = await getBackupList();
      if (backups.length > keepCount) {
        final toDelete = backups.sublist(keepCount);
        for (final backup in toDelete) {
          await deleteBackup(backup.filename);
        }
        AppLogger.info('Cleaned old backups, kept $keepCount');
      }
    } catch (e) {
      AppLogger.warning('Failed to clean old backups', error: e);
    }
  }

  /// Validate backup integrity
  Future<bool> validateBackup(String filename) async {
    try {
      final backupData = await importBackup(filename);

      // Check if data structure is valid
      if (backupData.metadata.expenseCount != backupData.expenses.length) {
        AppLogger.warning('Backup metadata mismatch: expense count');
        return false;
      }

      if (backupData.metadata.fixedCount != backupData.fixedItems.length) {
        AppLogger.warning('Backup metadata mismatch: fixed count');
        return false;
      }

      AppLogger.info('Backup validation passed: $filename');
      return true;
    } catch (e) {
      AppLogger.error('Backup validation failed', error: e);
      return false;
    }
  }
}
