/// Business rules that the spec says must be configurable.
/// TODO(Step 11): move these to a Firestore `settings/app` document so
/// admins can change them without a new release.
class AppConfig {
  AppConfig._();

  static const String currency = 'SAR';

  /// Auto logout after this many minutes without touching the screen.
  static const int inactivityMinutes = 15;

  /// An expiry within this many days counts as a "red flag".
  static const int expiryWarningDays = 30;

  /// Employment statuses included in "Fully-Loaded Monthly Cost".
  static const Set<String> costRosterStatuses = {'Active'};

  /// Contract statuses shown in "Contract Status Watch".
  static const Set<String> contractWatchStatuses = {
    'Transfer Pending',
    'Pending Renewal',
    'Cancelled',
  };

  /// Payroll ledger statuses that still need payment.
  static const Set<String> openLedgerStatuses = {'Unpaid', 'Partial', 'On Hold'};

  /// EOSB statuses that still have an amount to pay out.
  static const Set<String> eosbPayableStatuses = {'Approved', 'Partially Paid'};
}
