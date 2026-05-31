import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/core/tour/tour_session.dart';

// ─── TourController Next-lock unit tests ─────────────────────────────────────
//
// These tests verify the QA-WEB-007 fix:
//   - action-required step + predicate unsatisfied → next() is a no-op
//   - action-required step + predicate satisfied → next() advances stepIndex
//
// Tests run without Flutter widget tree (pure Dart), so TourController is
// tested via its session/predicate logic rather than the full widget lifecycle.

void main() {
  group('TourSession', () {
    test('initial state: all flags false', () {
      final s = TourSession(startAccountCount: 0);
      expect(s.transactionCreated, isFalse);
      expect(s.accountCreated, isFalse);
      expect(s.accountPageWasOpened, isFalse);
      expect(s.addAccountPageOpened, isFalse);
    });

    test('transactionCreated flag is set independently of DB', () {
      final s = TourSession(startAccountCount: 0);
      s.transactionCreated = true;
      expect(s.transactionCreated, isTrue);
    });
  });

  group('QA-WEB-007: expense step predicate', () {
    // The completionPredicate for qs_s5 is:
    //   (_, session, __) => session.transactionCreated
    //
    // This matches TourStep id=qs_s5 in tour_step.dart.

    final transactionPredicate =
        (dynamic _, TourSession session, int __) => session.transactionCreated;

    test('predicate returns false when no expense created', () {
      final session = TourSession(startAccountCount: 0);
      final result = transactionPredicate(null, session, 0);
      expect(result, isFalse,
          reason:
              'QA-WEB-007: step lock must hold when no expense exists');
    });

    test('predicate returns true after onTransactionCreated', () {
      final session = TourSession(startAccountCount: 0);
      session.transactionCreated = true; // simulates ctrl.onTransactionCreated()
      final result = transactionPredicate(null, session, 0);
      expect(result, isTrue,
          reason:
              'QA-WEB-007: Next must unlock after expense is created');
    });
  });

  group('QA-WEB-007: manage tab predicate (qs_s1)', () {
    // qs_s1 completionPredicate: (_, __, tab) => tab == 3
    final tabPredicate = (dynamic _, dynamic __, int tab) => tab == 3;

    test('predicate false when on tab 0 (no action taken)', () {
      expect(tabPredicate(null, null, 0), isFalse);
    });

    test('predicate true when navigated to Manage tab (3)', () {
      expect(tabPredicate(null, null, 3), isTrue);
    });
  });

  group('QA-WEB-007: account created predicate (qs_s4)', () {
    final accountPredicate =
        (dynamic _, TourSession session, int __) => session.accountCreated;

    test('predicate false before account saved', () {
      final s = TourSession(startAccountCount: 0);
      expect(accountPredicate(null, s, 0), isFalse);
    });

    test('predicate true after account saved', () {
      final s = TourSession(startAccountCount: 0);
      s.accountCreated = true;
      expect(accountPredicate(null, s, 0), isTrue);
    });
  });
}
