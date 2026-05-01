import 'package:flutter/material.dart';

/// Expense category definition
class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category(this.name, this.icon, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Predefined expense categories
const List<Category> kCategories = [
  Category('餐飲', Icons.restaurant, Color(0xFFD7BC74)),
  Category('教育', Icons.school, Color(0xFF7B9BB5)),
  Category('娛樂', Icons.sports_esports, Color(0xFF98AF82)),
  Category('交通', Icons.directions_bus, Color(0xFFC59B63)),
  Category('購物', Icons.shopping_bag, Color(0xFFC48DA0)),
  Category('醫療', Icons.local_hospital, Color(0xFF88A89A)),
  Category('住居', Icons.home, Color(0xFFB8956A)),
  Category('其他', Icons.more_horiz, Color(0xFFB4B2A9)),
];

/// Predefined income categories
const List<Category> kIncomeCategories = [
  Category('薪資', Icons.work_rounded, Color(0xFF5B9BD5)),
  Category('獎金', Icons.star_rounded, Color(0xFFD7BC74)),
  Category('投資', Icons.trending_up_rounded, Color(0xFF98AF82)),
  Category('退款', Icons.replay_rounded, Color(0xFF88A89A)),
  Category('其他收入', Icons.attach_money_rounded, Color(0xFFB4B2A9)),
];

/// Get category by name — checks expense first, then income, falls back to '其他'
Category categoryOf(String name) {
  for (final c in kCategories) {
    if (c.name == name) return c;
  }
  for (final c in kIncomeCategories) {
    if (c.name == name) return c;
  }
  return kCategories.last;
}

/// Get category list (for dropdowns)
List<String> getCategoryNames() => kCategories.map((c) => c.name).toList();

/// Validate if category name is a valid expense category
bool isValidCategory(String name) => kCategories.any((c) => c.name == name);

/// Check if name belongs to income categories
bool isIncomeCategoryName(String name) =>
    kIncomeCategories.any((c) => c.name == name);
