import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/core/utils/formatters.dart';

void main() {
  group('App Smoke Tests', () {
    test('formatCurrency formats correctly', () {
      expect(formatCurrency(1000), '1,000');
      expect(formatCurrency(0), '0');
    });

    // Validators require BuildContext for i18n and are tested via widget tests
  });
}
