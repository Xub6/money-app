import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../data/models/expense_item.dart';
import '../data/models/fixed_item.dart';
import '../core/utils/formatters.dart';
import '../core/utils/logger.dart';
import '../core/utils/app_exceptions.dart';

/// Service for exporting data to CSV and Excel formats
class ExportService {
  static const String _exportDirName = 'Money_App_Exports';

  Future<Directory> _getExportDirectory() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${documentsDir.path}/$_exportDirName');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir;
    } catch (e) {
      throw FileException(
        message: '無法獲取導出目錄',
        originalException: e,
      );
    }
  }

  /// Export expenses to CSV
  Future<String> exportExpensesAsCsv({
    required List<ExpenseItem> expenses,
    required String title,
  }) async {
    try {
      AppLogger.info('Exporting expenses to CSV...');

      // Prepare data
      final List<List<dynamic>> rows = [
        ['支出記錄 - $title'],
        [],
        ['項目名稱', '分類', '金額', '日期', '備註', '創建時間', '編輯時間'],
      ];

      for (final expense in expenses) {
        rows.add([
          expense.title,
          expense.category,
          expense.amount / 100,
          formatDate(expense.date),
          expense.note,
          formatDate(expense.createdAt, pattern: 'yyyy/MM/dd HH:mm'),
          expense.editedAt != null
              ? formatDate(expense.editedAt!, pattern: 'yyyy/MM/dd HH:mm')
              : '',
        ]);
      }

      // Add summary
      rows.add([]);
      rows.add(['總計', '', expenses.fold(0, (sum, e) => sum + e.amount) / 100]);

      final csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final exportDir = await _getExportDirectory();
      final timestamp =
          DateTime.now().toString().replaceAll(':', '').substring(0, 15);
      final filename = 'expenses_$timestamp.csv';
      final file = File('${exportDir.path}/$filename');
      await file.writeAsString(csv, encoding: utf8);

      AppLogger.info('CSV exported: $filename');
      return filename;
    } catch (e) {
      AppLogger.error('CSV export failed', error: e);
      throw FileException(
        message: '導出 CSV 失敗',
        originalException: e,
      );
    }
  }

  /// Export fixed items to CSV
  Future<String> exportFixedItemsAsCsv({
    required List<FixedItem> fixedItems,
    required String title,
  }) async {
    try {
      AppLogger.info('Exporting fixed items to CSV...');

      final List<List<dynamic>> rows = [
        ['固定開銷記錄 - $title'],
        [],
        ['項目名稱', '分類', '金額', '續費周期', '開始日期', '結束日期', '狀態'],
      ];

      for (final item in fixedItems) {
        rows.add([
          item.title,
          item.category,
          item.amount / 100,
          item.renewalCycle.label,
          formatDate(item.startDate),
          item.endDate != null ? formatDate(item.endDate!) : '進行中',
          item.isActive ? '啟用' : '已停用',
        ]);
      }

      rows.add([]);
      rows.add(
          ['月計', '', fixedItems.fold(0, (sum, i) => sum + i.amount) / 100]);

      final csv = const ListToCsvConverter().convert(rows);

      final exportDir = await _getExportDirectory();
      final timestamp =
          DateTime.now().toString().replaceAll(':', '').substring(0, 15);
      final filename = 'fixed_items_$timestamp.csv';
      final file = File('${exportDir.path}/$filename');
      await file.writeAsString(csv, encoding: utf8);

      AppLogger.info('Fixed items CSV exported: $filename');
      return filename;
    } catch (e) {
      AppLogger.error('Fixed items CSV export failed', error: e);
      throw FileException(
        message: '導出固定開銷 CSV 失敗',
        originalException: e,
      );
    }
  }

  /// Export comprehensive report
  Future<String> exportFullReport({
    required List<ExpenseItem> expenses,
    required List<FixedItem> fixedItems,
    required int budget,
    required DateTime month,
  }) async {
    try {
      AppLogger.info('Generating full report...');

      // Calculate statistics
      final monthExpenses = expenses
          .where(
            (e) => e.date.year == month.year && e.date.month == month.month,
          )
          .toList();

      final totalExpenses = monthExpenses.fold<int>(0, (s, e) => s + e.amount);
      final totalFixed = fixedItems.fold<int>(0, (s, i) => s + i.amount);
      final total = totalExpenses + totalFixed;
      final remaining = budget - total;

      final List<List<dynamic>> rows = [
        ['錢錢管家 - 月度報告'],
        [formatFullMonthYear(month)],
        [],
        ['= 支出統計 ='],
        ['日常支出', formatCurrency(totalExpenses)],
        ['固定開銷', formatCurrency(totalFixed)],
        ['總計', formatCurrency(total)],
        ['預算', formatCurrency(budget)],
        ['剩餘', formatCurrency(remaining)],
        ['使用率', '${((total / budget) * 100).toStringAsFixed(1)}%'],
        [],
        ['= 分類統計 ='],
        ['分類', '金額'],
      ];

      // Category breakdown
      final catMap = <String, int>{};
      for (final e in monthExpenses) {
        catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
      }
      for (final entry in catMap.entries) {
        rows.add([entry.key, formatCurrency(entry.value)]);
      }

      rows.add([]);
      rows.add(['= 支出明細 =']);
      rows.add(['項目', '分類', '金額', '日期', '備註']);
      for (final expense in monthExpenses) {
        rows.add([
          expense.title,
          expense.category,
          formatCurrency(expense.amount),
          formatDate(expense.date),
          expense.note,
        ]);
      }

      rows.add([]);
      rows.add(['= 固定開銷 =']);
      rows.add(['項目', '金額', '周期']);
      for (final item in fixedItems) {
        rows.add([
          item.title,
          formatCurrency(item.amount),
          item.renewalCycle.label,
        ]);
      }

      rows.add([]);
      rows.add(
          ['導出時間', DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())]);

      final csv = const ListToCsvConverter().convert(rows);

      final exportDir = await _getExportDirectory();
      final timestamp =
          DateTime.now().toString().replaceAll(':', '').substring(0, 15);
      final filename =
          'report_${DateFormat('yyyyMM').format(month)}_$timestamp.csv';
      final file = File('${exportDir.path}/$filename');
      await file.writeAsString(csv, encoding: utf8);

      AppLogger.info('Report exported: $filename');
      return filename;
    } catch (e) {
      AppLogger.error('Report export failed', error: e);
      throw FileException(
        message: '導出報告失敗',
        originalException: e,
      );
    }
  }

  /// Export a comprehensive monthly report to Excel (.xlsx)
  Future<String> exportFullReportAsExcel({
    required List<ExpenseItem> expenses,
    required List<FixedItem> fixedItems,
    required int budget,
    required DateTime month,
  }) async {
    try {
      AppLogger.info('Exporting full report to Excel...');

      final workbook = Excel.createExcel();
      workbook.delete('Sheet1'); // remove default sheet

      final monthLabel = DateFormat('yyyy年MM月').format(month);
      final monthExpenses = expenses
          .where(
              (e) => e.date.year == month.year && e.date.month == month.month)
          .toList();
      final totalExp = monthExpenses.fold<int>(0, (s, e) => s + e.amount);
      final totalFixed = fixedItems.fold<int>(0, (s, i) => s + i.amount);
      final total = totalExp + totalFixed;
      final remaining = budget - total;

      final headerStyle = CellStyle(bold: true);

      // ── 月度統計 ──
      final summary = workbook['月度統計'];
      void addSummaryRow(String label, String value) =>
          summary.appendRow([label, value]);
      summary.cell(CellIndex.indexByString('A1')).value =
          '錢錢管家 — $monthLabel 月度統計';
      summary.cell(CellIndex.indexByString('A1')).cellStyle =
          CellStyle(bold: true);
      summary.appendRow([]);
      addSummaryRow('日常支出', formatCurrency(totalExp));
      addSummaryRow('固定開銷', formatCurrency(totalFixed));
      addSummaryRow('合計支出', formatCurrency(total));
      addSummaryRow('月預算', formatCurrency(budget));
      addSummaryRow('剩餘預算', formatCurrency(remaining));
      addSummaryRow('預算使用率',
          budget == 0 ? '—' : '${(total / budget * 100).toStringAsFixed(1)}%');
      summary.appendRow([]);
      summary.appendRow(['分類統計']);
      final catMap = <String, int>{};
      for (final e in monthExpenses) {
        catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
      }
      for (final entry in (catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))) {
        summary.appendRow([entry.key, formatCurrency(entry.value)]);
      }

      // ── 支出明細 ──
      final expSheet = workbook['支出明細'];
      final expHeaders = ['項目名稱', '分類', '金額', '日期', '備註'];
      for (var i = 0; i < expHeaders.length; i++) {
        final cell = expSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = expHeaders[i];
        cell.cellStyle = headerStyle;
      }
      for (final e in monthExpenses) {
        expSheet.appendRow([
          e.title,
          e.category,
          e.amount / 100.0,
          formatDate(e.date),
          e.note ?? '',
        ]);
      }
      expSheet.appendRow([]);
      expSheet.appendRow(['總計', '', totalExp / 100.0]);

      // ── 固定開銷 ──
      final fixedSheet = workbook['固定開銷'];
      final fixedHeaders = ['項目名稱', '分類', '金額', '周期', '開始日期', '狀態'];
      for (var i = 0; i < fixedHeaders.length; i++) {
        final cell = fixedSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = fixedHeaders[i];
        cell.cellStyle = headerStyle;
      }
      for (final f in fixedItems) {
        fixedSheet.appendRow([
          f.title,
          f.category,
          f.amount / 100.0,
          f.renewalCycle.label,
          formatDate(f.startDate),
          f.isActive ? '啟用' : '已停用',
        ]);
      }
      fixedSheet.appendRow([]);
      fixedSheet.appendRow(['月計', '', totalFixed / 100.0]);

      workbook.setDefaultSheet('月度統計');

      final fileBytes = workbook.save();
      if (fileBytes == null) {
        throw FileException(message: '無法生成 Excel 文件');
      }

      final exportDir = await _getExportDirectory();
      final timestamp =
          DateTime.now().toString().replaceAll(':', '').substring(0, 15);
      final filename =
          'report_${DateFormat('yyyyMM').format(month)}_$timestamp.xlsx';
      final file = File('${exportDir.path}/$filename');
      await file.writeAsBytes(fileBytes);

      AppLogger.info('Excel report exported: $filename');
      return filename;
    } catch (e) {
      AppLogger.error('Excel export failed', error: e);
      throw FileException(message: '導出 Excel 失敗', originalException: e);
    }
  }

  /// Get list of exported files
  Future<List<FileSystemEntity>> getExportedFiles() async {
    try {
      final exportDir = await _getExportDirectory();
      final files = await exportDir.list().toList();
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      AppLogger.error('Failed to get exported files', error: e);
      return [];
    }
  }

  /// Delete exported file
  Future<void> deleteExportedFile(String filename) async {
    try {
      final exportDir = await _getExportDirectory();
      final file = File('${exportDir.path}/$filename');
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('Exported file deleted: $filename');
      }
    } catch (e) {
      AppLogger.error('Failed to delete exported file', error: e);
      throw FileException(
        message: '刪除導出文件失敗',
        originalException: e,
      );
    }
  }

  /// Get file size in KB
  Future<double> getFileSize(String filename) async {
    try {
      final exportDir = await _getExportDirectory();
      final file = File('${exportDir.path}/$filename');
      if (await file.exists()) {
        return (await file.length()) / 1024;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
