import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../../config/localization.dart';

/// Number formatting utilities
String formatCurrency(int amount) {
  return NumberFormat('#,###').format(amount);
}

String formatCurrencyWithNT(int amount) {
  return 'NT\$ ${formatCurrency(amount)}';
}

/// Format large numbers with K suffix
String formatNumberShort(int n) {
  if (n >= 10000) {
    return '${(n / 1000).toStringAsFixed(0)}K';
  }
  return formatCurrency(n);
}

/// Format percentage
String formatPercentage(double percent) {
  return '${(percent * 100).round()}%';
}

/// Format amount as percentage of total
String formatAsPercentage(int amount, int total) {
  if (total == 0) return '0%';
  return formatPercentage(amount / total);
}

/// Date formatting
String formatDate(DateTime date, {String pattern = 'yyyy/MM/dd'}) {
  return DateFormat(pattern).format(date);
}

String formatMonthYear(DateTime date, {String locale = 'zh_TW'}) {
  return DateFormat('M月', locale).format(date);
}

String formatFullMonthYear(DateTime date, {String locale = 'zh_TW'}) {
  return DateFormat('yyyy年M月', locale).format(date);
}

String formatDateRange(DateTime start, DateTime end, {String locale = 'zh_TW'}) {
  if (start.month == end.month && start.year == end.year) {
    return '${start.day} - ${end.day} ${formatMonthYear(end, locale: locale)}';
  }
  return '${formatDate(start)} ~ ${formatDate(end)}';
}

/// Relative date formatting with locale support
String formatRelativeDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly == today) return AppLocalizations.of(context, 'today');
  if (dateOnly == yesterday) return AppLocalizations.of(context, 'yesterday');
  if (dateOnly.year == today.year) return DateFormat('M/d').format(date);
  return formatDate(date);
}
