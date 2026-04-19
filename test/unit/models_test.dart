import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/data/models/expense_item.dart';
import 'package:money_app/data/models/fixed_item.dart';
import 'package:money_app/core/utils/validators.dart';
import 'package:money_app/core/utils/formatters.dart';

void main() {
  group('Data Models Tests', () {
    test('ExpenseItem.fromJson creates valid instance', () {
      final json = {
        'id': 'test-id',
        'title': '午餐',
        'category': '餐飲',
        'amount': 12000,
        'date': '2024-01-15T10:00:00.000Z',
        'note': '公司便當',
        'createdAt': '2024-01-15T09:00:00.000Z',
      };

      final item = ExpenseItem.fromJson(json);

      expect(item.id, 'test-id');
      expect(item.title, '午餐');
      expect(item.category, '餐飲');
      expect(item.amount, 12000);
      expect(item.note, '公司便當');
      expect(item.isEdited, false);
    });

    test('ExpenseItem.toJson includes all fields', () {
      final now = DateTime.now();
      final item = ExpenseItem(
        title: '咖啡',
        category: '餐飲',
        amount: 6500,
        date: now,
        note: '超商',
        createdAt: now,
      );

      final json = item.toJson();

      expect(json['title'], '咖啡');
      expect(json['amount'], 6500);
      expect(json['syncStatus'], 'local');
    });

    test('ExpenseItem.copyWith creates modified copy', () {
      final original = ExpenseItem(
        title: '原始',
        category: '餐飲',
        amount: 10000,
        date: DateTime.now(),
      );

      final modified = original.copyWith(title: '修改後', amount: 15000);

      expect(original.title, '原始');
      expect(original.amount, 10000);
      expect(modified.title, '修改後');
      expect(modified.amount, 15000);
      expect(modified.id, original.id); // ID preserved
    });

    test('FixedItem.isActiveAt calculates correctly', () {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final item = FixedItem(
        title: '訂閱',
        amount: 10000,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
      );

      expect(item.isActiveAt(startDate), true);
      expect(item.isActiveAt(endDate), true);
      expect(item.isActiveAt(startDate.subtract(const Duration(days: 1))), false);
      expect(item.isActiveAt(endDate.add(const Duration(days: 1))), false);
    });
  });

  group('Validators Tests', () {
    test('validateTitle requires non-empty string', () {
      expect(Validators.validateTitle(null), '請填寫支出名稱');
      expect(Validators.validateTitle(''), '請填寫支出名稱');
      expect(Validators.validateTitle('午餐'), null);
      expect(Validators.validateTitle('x' * 51), '名稱不超過50個字符');
    });

    test('validateAmount checks valid numbers', () {
      expect(Validators.validateAmount(null), '請填寫金額');
      expect(Validators.validateAmount(''), '請填寫金額');
      expect(Validators.validateAmount('abc'), '金額必須是數字');
      expect(Validators.validateAmount('0'), '金額必須大於 0');
      expect(Validators.validateAmount('-10'), '金額必須大於 0');
      expect(Validators.validateAmount('120'), null);
      expect(Validators.validateAmount('99999999'), '金額過大');
    });

    test('validateBudget checks budget input', () {
      expect(Validators.validateBudget(null), '請填寫預算金額');
      expect(Validators.validateBudget(''), '請填寫預算金額');
      expect(Validators.validateBudget('invalid'), '預算必須是數字');
      expect(Validators.validateBudget('0'), '預算必須大於 0');
      expect(Validators.validateBudget('30000'), null);
    });
  });

  group('Formatters Tests', () {
    test('formatCurrency formats numbers with comma', () {
      expect(formatCurrency(0), '0');
      expect(formatCurrency(1000), '1,000');
      expect(formatCurrency(1234567), '1,234,567');
    });

    test('formatCurrencyWithNT adds currency symbol', () {
      expect(formatCurrencyWithNT(10000), 'NT\$ 10,000');
      expect(formatCurrencyWithNT(120), 'NT\$ 120');
    });

    test('formatNumberShort shortens large numbers', () {
      expect(formatNumberShort(1000), '1,000');
      expect(formatNumberShort(10000), '10K');
      expect(formatNumberShort(1234567), '1235K');
    });

    test('formatPercentage formats percentages', () {
      expect(formatPercentage(0.5), '50%');
      expect(formatPercentage(0.333), '33%');
      expect(formatPercentage(1.0), '100%');
    });

    test('formatDate formats dates correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(formatDate(date), '2024/01/15');
    });
  });

  group('Integration Tests', () {
    test('Create, modify, and serialize expense', () {
      // Create
      final expense = ExpenseItem(
        title: '午餐',
        category: '餐飲',
        amount: 12000,
        date: DateTime.now(),
        note: '便當',
      );

      // Modify
      final updated = expense.copyWith(title: '午餐便當', amount: 15000);
      expect(updated.isEdited, false); // editedAt not set in copyWith
      expect(updated.title, '午餐便當');

      // Serialize
      final json = updated.toJson();
      expect(json['title'], '午餐便當');
      expect(json['amount'], 15000);

      // Deserialize
      final restored = ExpenseItem.fromJson(json);
      expect(restored.title, updated.title);
      expect(restored.amount, updated.amount);
    });

    test('Expense list aggregation', () {
      final expenses = [
        ExpenseItem(
          title: '午餐',
          category: '餐飲',
          amount: 10000,
          date: DateTime(2024, 1, 15),
        ),
        ExpenseItem(
          title: '晚餐',
          category: '餐飲',
          amount: 15000,
          date: DateTime(2024, 1, 15),
        ),
        ExpenseItem(
          title: '課程',
          category: '教育',
          amount: 50000,
          date: DateTime(2024, 1, 15),
        ),
      ];

      final totalExpense = expenses.fold<int>(0, (sum, e) => sum + e.amount);
      expect(totalExpense, 75000);

      final categoryMap = <String, int>{};
      for (final e in expenses) {
        categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
      }

      expect(categoryMap['餐飲'], 25000);
      expect(categoryMap['教育'], 50000);
    });
  });
}
