import 'app_permissions.dart';

/// All role names used across the application.
class AppRoles {
  AppRoles._();

  static const String superAdmin = 'Super Admin';
  static const String admin = 'Admin';
  static const String manager = 'Manager';
  static const String employee = 'Employee';
  static const String guest = 'Guest';

  // Bolt Workforce Ledger roles
  static const String hrAdmin = 'HR Admin';
  static const String payrollAccounts = 'Payroll / Accounts';
  static const String regionalManager = 'Regional Manager';
  static const String departmentManager = 'Department Manager';
  static const String viewerAuditor = 'Viewer / Auditor';

  /// Firestore document id for a role name (e.g. "Payroll / Accounts" -> "payroll_accounts").
  /// Needed because "/" is not allowed inside document ids.
  static String idOf(String role) => role
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static const List<String> all = [
    superAdmin,
    admin,
    manager,
    employee,
    guest,
    hrAdmin,
    payrollAccounts,
    regionalManager,
    departmentManager,
    viewerAuditor,
  ];
}

/// Default Role -> Permissions mapping (seed data written to Firestore `roles`).
/// After seeding, the Roles module edits Firestore, not this map.
/// Super Admin is always "everything" and is never read from Firestore.
final Map<String, List<String>> kDefaultRolePermissions = {
  AppRoles.superAdmin: [...AppPermissions.all],
  AppRoles.admin: [
    AppPermissions.dashboardView,
    AppPermissions.employeeCreate,
    AppPermissions.employeeView,
    AppPermissions.employeeUpdate,
    AppPermissions.employeeDelete,
    AppPermissions.reportView,
    AppPermissions.userCreate,
    AppPermissions.userView,
    AppPermissions.userUpdate,
    AppPermissions.profileView,
    AppPermissions.profileUpdate,
    AppPermissions.lookupView,
  ],
  AppRoles.manager: [
    AppPermissions.dashboardView,
    AppPermissions.employeeCreate,
    AppPermissions.employeeUpdate,
    AppPermissions.employeeView,
    AppPermissions.profileView,
    AppPermissions.profileUpdate,
  ],
  AppRoles.employee: [
    AppPermissions.dashboardView,
    AppPermissions.profileView,
    AppPermissions.profileUpdate,
  ],
  AppRoles.guest: [
    AppPermissions.dashboardView,
  ],
  // Employees, attendance, contracts, expiry, Mudad/Ajeer, documents, HR reports.
  AppRoles.hrAdmin: [
    AppPermissions.dashboardView,
    AppPermissions.employeeCreate,
    AppPermissions.employeeView,
    AppPermissions.employeeUpdate,
    AppPermissions.employeeDelete,
    AppPermissions.employeeExport,
    AppPermissions.attendanceView,
    AppPermissions.attendanceCreate,
    AppPermissions.attendanceUpdate,
    AppPermissions.expiryView,
    AppPermissions.ajeerView,
    AppPermissions.ajeerUpdate,
    AppPermissions.assetView,
    AppPermissions.assetCreate,
    AppPermissions.assetUpdate,
    AppPermissions.assetAssign,
    AppPermissions.trashView,
    AppPermissions.trashRestore,
    AppPermissions.lookupView,
    AppPermissions.reportView,
    AppPermissions.reportExport,
    AppPermissions.profileView,
    AppPermissions.profileUpdate,
  ],
  // Ledger, payroll, payments, loans, EOSB, compliance costs, expenses.
  AppRoles.payrollAccounts: [
    AppPermissions.dashboardView,
    AppPermissions.dashboardFinance,
    AppPermissions.employeeView,
    AppPermissions.ledgerView,
    AppPermissions.ledgerExport,
    AppPermissions.paymentView,
    AppPermissions.paymentCreate,
    AppPermissions.paymentReverse,
    AppPermissions.loanView,
    AppPermissions.loanCreate,
    AppPermissions.loanRecover,
    AppPermissions.eosbView,
    AppPermissions.eosbCreate,
    AppPermissions.eosbPay,
    AppPermissions.complianceView,
    AppPermissions.complianceCreate,
    AppPermissions.complianceUpdate,
    AppPermissions.expenseView,
    AppPermissions.expensePay,
    AppPermissions.lookupView,
    AppPermissions.reportView,
    AppPermissions.reportExport,
    AppPermissions.profileView,
    AppPermissions.profileUpdate,
  ],
  // Dashboard + workforce info, limited to the user's assigned region.
  AppRoles.regionalManager: [
    AppPermissions.dashboardView,
    AppPermissions.employeeView,
    AppPermissions.attendanceView,
    AppPermissions.expiryView,
    AppPermissions.ajeerView,
    AppPermissions.expenseView,
    AppPermissions.expenseApprove,
    AppPermissions.lookupView,
    AppPermissions.reportView,
    AppPermissions.profileView,
    AppPermissions.profileUpdate,
  ],
  // Department employee list, attendance, approved operational info.
  AppRoles.departmentManager: [
    AppPermissions.dashboardView,
    AppPermissions.employeeView,
    AppPermissions.attendanceView,
    AppPermissions.attendanceCreate,
    AppPermissions.expiryView,
    AppPermissions.profileView,
    AppPermissions.profileUpdate,
  ],
  // Read-only access to selected modules and reports.
  AppRoles.viewerAuditor: [
    AppPermissions.dashboardView,
    AppPermissions.dashboardFinance,
    AppPermissions.employeeView,
    AppPermissions.ledgerView,
    AppPermissions.paymentView,
    AppPermissions.attendanceView,
    AppPermissions.loanView,
    AppPermissions.eosbView,
    AppPermissions.expiryView,
    AppPermissions.ajeerView,
    AppPermissions.expenseView,
    AppPermissions.complianceView,
    AppPermissions.assetView,
    AppPermissions.trashView,
    AppPermissions.auditView,
    AppPermissions.lookupView,
    AppPermissions.reportView,
    AppPermissions.reportExport,
    AppPermissions.profileView,
  ],
};
