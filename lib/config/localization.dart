import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Localization support
class AppLocalizations {
  static const supportedLocales = [
    Locale('zh', 'TW'), // Traditional Chinese
    Locale('zh', 'CN'), // Simplified Chinese
    Locale('en', 'US'), // English
    Locale('ja', 'JP'), // Japanese
  ];

  static const defaultLocale = Locale('zh', 'TW');

  static const Map<String, Map<String, String>> _localizedStrings = {
    'zh_TW': {
      // Common
      'app_name': '錢錢管家',
      'yes': '是',
      'no': '否',
      'confirm': '確認',
      'cancel': '取消',
      'save': '保存',
      'delete': '刪除',
      'edit': '編輯',
      'add': '新增',
      'search': '搜索',
      'back': '返回',
      'close': '關閉',

      // Dashboard
      'dashboard': '記帳',
      'budget_progress': '預算進度',
      'remaining_budget': '剩餘預算',
      'daily_avg': '日均支出',
      'recommended_daily': '建議日均',
      'streak': '天連勝',
      'this_month': '本月',
      'last_month': '上月',
      'next_month': '下月',

      // Expense
      'add_expense': '新增支出',
      'edit_expense': '編輯支出',
      'expense_name': '項目名稱',
      'amount': '金額',
      'date': '日期',
      'category': '分類',
      'note': '備註',
      'optional': '選填',
      'expense_details': '支出明細',
      'total': '總計',

      // Category
      'dining': '餐飲',
      'education': '教育',
      'entertainment': '娛樂',
      'transport': '交通',
      'shopping': '購物',
      'medical': '醫療',
      'living': '住居',
      'other': '其他',

      // Fixed Items
      'fixed_expenses': '固定開銷',
      'add_fixed': '新增固定開銷',
      'monthly': '每月',
      'yearly': '每年',
      'active': '啟用',
      'inactive': '已停用',

      // Search
      'search_expenses': '搜索支出',
      'search_hint': '搜索支出、固定開銷...',
      'no_results': '沒有找到結果',
      'date_range': '日期範圍',
      'clear_filters': '清除篩選',

      // Backup & Export
      'backup': '備份',
      'restore': '恢復',
      'export': '導出',
      'import': '導入',
      'backup_data': '備份數據',
      'restore_backup': '恢復備份',
      'export_csv': '導出為 CSV',
      'export_report': '導出報告',
      'backup_list': '備份列表',
      'backup_success': '✓ 備份成功',
      'restore_success': '✓ 恢復成功',
      'export_success': '✓ 導出成功',

      // Statistics
      'statistics': '統計',
      'trend': '趨勢',
      'highest_month': '花最多的月',
      'lowest_month': '花最少的月',
      'monthly_details': '月份詳情',
      'category_breakdown': '分類統計',

      // Settings & Management
      'manage': '管理',
      'settings': '設置',
      'dark_mode': '深色模式',
      'language': '語言',
      'about': '關於',
      'version': '版本',
      'clear_all': '清除所有數據',
      'danger_zone': '危險區',

      // Messages
      'please_enter_name': '請填寫名稱',
      'please_enter_amount': '請填寫金額',
      'invalid_amount': '金額無效',
      'confirm_delete': '確定要刪除嗎？',
      'confirm_clear_all': '確定要清除所有數據嗎？此操作無法撤銷。',
      'no_data': '暫無數據',
      'loading': '加載中...',
      'error': '錯誤',
      'success': '成功',
      'warning': '警告',
    },
    'zh_CN': {
      'app_name': '钱钱管家',
      'dashboard': '记账',
      'add_expense': '新增支出',
      'edit_expense': '编辑支出',
      'expense_name': '项目名称',
      'amount': '金额',
      'date': '日期',
      'category': '分类',
      'note': '备注',
      'optional': '选填',
      'search': '搜索',
      'backup': '备份',
      'restore': '恢复',
      'export': '导出',
      'settings': '设置',
      'dark_mode': '深色模式',
      // ... more Chinese Simplified translations
    },
    'en_US': {
      'app_name': 'Money Manager',
      'yes': 'Yes',
      'no': 'No',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'dashboard': 'Dashboard',
      'add_expense': 'Add Expense',
      'edit_expense': 'Edit Expense',
      'expense_name': 'Expense Name',
      'amount': 'Amount',
      'date': 'Date',
      'category': 'Category',
      'note': 'Note',
      'optional': 'Optional',
      'backup': 'Backup',
      'restore': 'Restore',
      'export': 'Export',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      // ... more English translations
    },
    'ja_JP': {
      'app_name': 'マネーマネージャー',
      'yes': 'はい',
      'no': 'いいえ',
      'confirm': '確認',
      'cancel': 'キャンセル',
      'save': '保存',
      'delete': '削除',
      'edit': '編集',
      'add': '追加',
      'search': '検索',
      'dashboard': 'ダッシュボード',
      'add_expense': '支出を追加',
      'edit_expense': '支出を編集',
      'expense_name': '支出名',
      'amount': '金額',
      'date': '日付',
      'category': 'カテゴリー',
      'note': 'メモ',
      'optional': 'オプション',
      'backup': 'バックアップ',
      'restore': '復元',
      'export': 'エクスポート',
      'settings': '設定',
      'dark_mode': 'ダークモード',
      // ... more Japanese translations
    },
  };

  static String getLocaleKey(Locale locale) {
    return '${locale.languageCode}_${locale.countryCode}';
  }

  static String translate(Locale locale, String key) {
    final localeKey = getLocaleKey(locale);
    final translations = _localizedStrings[localeKey] ?? _localizedStrings['zh_TW']!;
    return translations[key] ?? key;
  }

  /// Get localized string for current locale
  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    return translate(locale, key);
  }

  /// Format date based on locale
  static String formatDateForLocale(DateTime date, Locale locale) {
    try {
      Intl.defaultLocale = '${locale.languageCode}_${locale.countryCode}';
      final format = DateFormat.yMd();
      return format.format(date);
    } catch (e) {
      return date.toString();
    }
  }

  /// Format currency based on locale
  static String formatCurrencyForLocale(int amount, Locale locale) {
    try {
      Intl.defaultLocale = '${locale.languageCode}_${locale.countryCode}';
      final format = NumberFormat.currency(symbol: 'NT\$ ');
      return format.format(amount / 100);
    } catch (e) {
      return 'NT\$ ${(amount / 100).toStringAsFixed(2)}';
    }
  }
}

// Delegate for Flutter localization
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
