/// Baseline state snapshot captured when the onboarding tour starts.
/// Predicates compare live AppState against this snapshot to detect
/// real user actions (account created, expense logged, etc.).
class TourSession {
  final int startAccountCount;
  final DateTime createdAt;
  bool accountPageWasOpened = false;
  bool addAccountPageOpened = false; // + button tapped inside AccountPage
  bool accountCreated = false;       // account form actually saved
  bool transactionCreated = false;   // expense form actually saved

  TourSession({required this.startAccountCount}) : createdAt = DateTime.now();
}
