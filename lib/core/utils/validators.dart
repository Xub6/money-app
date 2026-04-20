/// Data validation utilities
class Validators {
  /// Validate expense title
  /// Returns error message if invalid, null if valid
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return '請填寫支出名稱';
    }
    if (value.length > 50) {
      return '名稱不超過50個字符';
    }
    return null;
  }

  /// Validate amount in cents
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return '請填寫金額';
    }
    final amount = int.tryParse(value);
    if (amount == null) {
      return '金額必須是數字';
    }
    if (amount <= 0) {
      return '金額必須大於 0';
    }
    if (amount >= 99999999) {
      return '金額過大';
    }
    return null;
  }

  /// Validate note (optional)
  static String? validateNote(String? value) {
    if (value != null && value.length > 200) {
      return '備註不超過200個字符';
    }
    return null;
  }

  /// Validate category name
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return '請選擇分類';
    }
    return null;
  }

  /// Validate date range (startDate should be before endDate)
  static String? validateDateRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      return '開始日期不能晚於結束日期';
    }
    return null;
  }

  /// Validate budget amount
  static String? validateBudget(String? value) {
    if (value == null || value.isEmpty) {
      return '請填寫預算金額';
    }
    final budget = int.tryParse(value);
    if (budget == null) {
      return '預算必須是數字';
    }
    if (budget <= 0) {
      return '預算必須大於 0';
    }
    return null;
  }

  /// Validate fixed item name
  static String? validateFixedItemName(String? value) {
    if (value == null || value.isEmpty) {
      return '請填寫項目名稱';
    }
    if (value.length > 50) {
      return '名稱不超過50個字符';
    }
    return null;
  }

  /// Validate search query
  static String? validateSearchQuery(String? value) {
    if (value != null && value.length > 100) {
      return '搜尋詞不超過100個字符';
    }
    return null;
  }
}
