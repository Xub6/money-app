import 'package:flutter/widgets.dart';
import '../../config/localization.dart';

/// Data validation utilities
class Validators {
  static String? validateTitle(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context, 'validate_title_empty');
    if (value.length > 50) return AppLocalizations.of(context, 'validate_title_long');
    return null;
  }

  static String? validateAmount(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context, 'validate_amount_empty');
    final amount = int.tryParse(value);
    if (amount == null) return AppLocalizations.of(context, 'validate_amount_nan');
    if (amount <= 0) return AppLocalizations.of(context, 'validate_amount_zero');
    if (amount >= 99999999) return AppLocalizations.of(context, 'validate_amount_large');
    return null;
  }

  static String? validateNote(BuildContext context, String? value) {
    if (value != null && value.length > 200) return AppLocalizations.of(context, 'validate_note_long');
    return null;
  }

  static String? validateCategory(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context, 'validate_category_empty');
    return null;
  }

  static String? validateDateRange(BuildContext context, DateTime start, DateTime end) {
    if (start.isAfter(end)) return AppLocalizations.of(context, 'validate_date_range');
    return null;
  }

  static String? validateBudget(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context, 'validate_budget_empty');
    final budget = int.tryParse(value);
    if (budget == null) return AppLocalizations.of(context, 'validate_budget_nan');
    if (budget <= 0) return AppLocalizations.of(context, 'validate_budget_zero');
    return null;
  }

  static String? validateFixedItemName(BuildContext context, String? value) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context, 'validate_fixed_name_empty');
    if (value.length > 50) return AppLocalizations.of(context, 'validate_fixed_name_long');
    return null;
  }

  static String? validateSearchQuery(BuildContext context, String? value) {
    if (value != null && value.length > 100) return AppLocalizations.of(context, 'validate_search_long');
    return null;
  }
}
