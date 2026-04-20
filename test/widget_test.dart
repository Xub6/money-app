import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/core/utils/validators.dart';
import 'package:money_app/core/utils/formatters.dart';

void main() {
  group('App Smoke Tests', () {
    test('formatCurrency formats correctly', () {
      expect(formatCurrency(1000), '1,000');
      expect(formatCurrency(0), '0');
    });

    test('validateAmount accepts valid amounts', () {
      expect(Validators.validateAmount('500'), null);
      expect(Validators.validateAmount('1'), null);
    });

    test('validateAmount rejects invalid amounts', () {
      expect(Validators.validateAmount(''), isNotNull);
      expect(Validators.validateAmount('0'), isNotNull);
      expect(Validators.validateAmount('abc'), isNotNull);
    });
  });
}
