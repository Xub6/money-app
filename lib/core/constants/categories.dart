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

/// Predefined categories
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

/// Get category by name, returns '其他' if not found
Category categoryOf(String name) {
  try {
    return kCategories.firstWhere((c) => c.name == name);
  } catch (e) {
    return kCategories.last; // Return '其他'
  }
}

/// Get category list (for dropdowns)
List<String> getCategoryNames() => kCategories.map((c) => c.name).toList();

/// Validate if category name is valid
bool isValidCategory(String name) {
  return kCategories.any((c) => c.name == name);
}
