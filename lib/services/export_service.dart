import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../config/localization.dart';
import '../data/models/expense_item.dart';
import '../data/models/fixed_item.dart';
import '../core/utils/formatters.dart';
import '../core/utils/logger.dart';
import '../core/utils/app_exceptions.dart';

/// Service for exporting data to CSV and Excel formats
class ExportService {
  static const String _exportDirName = 'Money_App_Exports';

  static String _t(Locale locale, String key) =>
      AppLocalizations.translate(locale, key);

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
        message: 'export_dir_error',
        originalException: e,
      );
    }
  }

  /// Export expenses to CSV
  Future<String> exportExpensesAsCsv({
    required List<ExpenseItem> expenses,
    required String title,
    Locale locale = const Locale('zh', 'TW'),
  }) async {
    try {
      AppLogger.info('Exporting expenses to CSV...');
      String t(String key) => _t(locale, key);

      // Prepare data
      final List<List<dynamic>> rows = [
        ['${t('expense_records')} - $title'],
        [],
        [t('expense_name'), t('category'), t('amount'), t('date'), t('note'), t('created_at'), t('edited_at')],
      ];

      for (final expense in expenses) {
        rows.add([
          expense.title,
          expense.category,
          expense.amount,
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
      rows.add([t('grand_total'), '', expenses.fold(0, (sum, e) => sum + e.amount)]);

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
        message: 'export_csv_error',
        originalException: e,
      );
    }
  }

  /// Export fixed items to CSV
  Future<String> exportFixedItemsAsCsv({
    required List<FixedItem> fixedItems,
    required String title,
    Locale locale = const Locale('zh', 'TW'),
  }) async {
    try {
      AppLogger.info('Exporting fixed items to CSV...');
      String t(String key) => _t(locale, key);

      final List<List<dynamic>> rows = [
        ['${t('fixed_records')} - $title'],
        [],
        [t('expense_name'), t('category'), t('amount'), t('renewal_cycle'), t('start_date'), t('end_date'), t('status')],
      ];

      for (final item in fixedItems) {
        rows.add([
          item.title,
          item.category,
          item.amount / 100,
          t(item.renewalCycle.value),
          formatDate(item.startDate),
          item.endDate != null ? formatDate(item.endDate!) : t('ongoing'),
          item.isActive ? t('active') : t('inactive'),
        ]);
      }

      rows.add([]);
      rows.add(
          [t('monthly_total'), '', fixedItems.fold(0, (sum, i) => sum + i.amount) / 100]);

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
        message: 'export_csv_error',
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
    Locale locale = const Locale('zh', 'TW'),
  }) async {
    try {
      AppLogger.info('Generating full report...');
      String t(String key) => _t(locale, key);

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
        ['錢錢管家 - ${t('monthly_report')}'],
        [formatFullMonthYear(month)],
        [],
        ['= ${t('expense_total')} ='],
        [t('daily_expense'), formatCurrency(totalExpenses)],
        [t('fixed_expenses'), formatCurrency(totalFixed)],
        [t('grand_total'), formatCurrency(total)],
        [t('monthly_budget'), formatCurrency(budget)],
        [t('remaining_budget'), formatCurrency(remaining)],
        [t('usage_rate'), '${((total / budget) * 100).toStringAsFixed(1)}%'],
        [],
        ['= ${t('category_stats')} ='],
        [t('category'), t('amount')],
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
      rows.add(['= ${t('sheet_expense_detail')} =']);
      rows.add([t('item'), t('category'), t('amount'), t('date'), t('note')]);
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
      rows.add(['= ${t('fixed_expenses')} =']);
      rows.add([t('item'), t('amount'), t('cycle')]);
      for (final item in fixedItems) {
        rows.add([
          item.title,
          formatCurrency(item.amount),
          t(item.renewalCycle.value),
        ]);
      }

      rows.add([]);
      rows.add(
          [t('export_time'), DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())]);

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
        message: 'export_report_error',
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
    Locale locale = const Locale('zh', 'TW'),
  }) async {
    try {
      AppLogger.info('Exporting full report to Excel...');
      String t(String key) => _t(locale, key);

      final workbook = Excel.createExcel();
      workbook.delete('Sheet1'); // remove default sheet

      final monthLabel = formatFullMonthYear(month);
      final monthExpenses = expenses
          .where(
              (e) => e.date.year == month.year && e.date.month == month.month)
          .toList();
      final totalExp = monthExpenses.fold<int>(0, (s, e) => s + e.amount);
      final totalFixed = fixedItems.fold<int>(0, (s, i) => s + i.amount);
      final total = totalExp + totalFixed;
      final remaining = budget - total;

      final headerStyle = CellStyle(bold: true);
      final sheetSummary = t('sheet_summary');

      // ── Summary sheet ──
      final summary = workbook[sheetSummary];
      void addSummaryRow(String label, String value) =>
          summary.appendRow([label, value]);
      summary.cell(CellIndex.indexByString('A1')).value =
          '錢錢管家 — $monthLabel ${t('sheet_summary')}';
      summary.cell(CellIndex.indexByString('A1')).cellStyle =
          CellStyle(bold: true);
      summary.appendRow([]);
      addSummaryRow(t('daily_expense'), formatCurrency(totalExp));
      addSummaryRow(t('fixed_expenses'), formatCurrency(totalFixed));
      addSummaryRow(t('expense_total'), formatCurrency(total));
      addSummaryRow(t('monthly_budget'), formatCurrency(budget));
      addSummaryRow(t('remaining_budget'), formatCurrency(remaining));
      addSummaryRow(t('budget_usage_rate'),
          budget == 0 ? '—' : '${(total / budget * 100).toStringAsFixed(1)}%');
      summary.appendRow([]);
      summary.appendRow([t('category_stats')]);
      final catMap = <String, int>{};
      for (final e in monthExpenses) {
        catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
      }
      for (final entry in (catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))) {
        summary.appendRow([entry.key, formatCurrency(entry.value)]);
      }

      // ── Expense detail sheet ──
      final expSheet = workbook[t('sheet_expense_detail')];
      final expHeaders = [t('expense_name'), t('category'), t('amount'), t('date'), t('note')];
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
          e.note,
        ]);
      }
      expSheet.appendRow([]);
      expSheet.appendRow([t('grand_total'), '', totalExp / 100.0]);

      // ── Fixed expenses sheet ──
      final fixedSheet = workbook[t('fixed_expenses')];
      final fixedHeaders = [t('expense_name'), t('category'), t('amount'), t('cycle'), t('start_date'), t('status')];
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
          t(f.renewalCycle.value),
          formatDate(f.startDate),
          f.isActive ? t('active') : t('inactive'),
        ]);
      }
      fixedSheet.appendRow([]);
      fixedSheet.appendRow([t('monthly_total'), '', totalFixed / 100.0]);

      workbook.setDefaultSheet(sheetSummary);

      final fileBytes = workbook.save();
      if (fileBytes == null) {
        throw FileException(message: 'export_excel_error');
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
      throw FileException(message: 'export_excel_error', originalException: e);
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
        message: 'export_delete_error',
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
