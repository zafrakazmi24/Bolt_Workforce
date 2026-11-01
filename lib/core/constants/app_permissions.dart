/// All permission keys used across the application.
/// Naming convention: module.action
/// Actions follow the spec: view, create, update, delete, approve, pay, export.
class AppPermissions {
  AppPermissions._();

  // ---- Core (existing) ----
  static const String dashboardView = 'dashboard.view';
  static const String dashboardFinance = 'dashboard.finance'; // payroll/loan/EOSB KPIs

  static const String employeeCreate = 'employee.create';
  static const String employeeView = 'employee.view';
  static const String employeeUpdate = 'employee.update';
  static const String employeeDelete = 'employee.delete';
  static const String employeeExport = 'employee.export';

  static const String profileView = 'profile.view';
  static const String profileUpdate = 'profile.update';

  static const String reportView = 'report.view';
  static const String reportExport = 'report.export';

  static const String userCreate = 'user.create';
  static const String userView = 'user.view';
  static const String userUpdate = 'user.update';
  static const String userDelete = 'user.delete';

  static const String roleCreate = 'role.create';
  static const String roleView = 'role.view';
  static const String roleUpdate = 'role.update';
  static const String roleDelete = 'role.delete';

  // ---- Master data (regions, departments, commercial registrations) ----
  static const String lookupView = 'lookup.view';
  static const String lookupManage = 'lookup.manage';

  // ---- Bolt Workforce Ledger modules (screens arrive in later steps) ----
  static const String ledgerView = 'ledger.view';
  static const String ledgerExport = 'ledger.export';

  static const String paymentView = 'payment.view';
  static const String paymentCreate = 'payment.create';
  static const String paymentReverse = 'payment.reverse';
  static const String paymentOverride = 'payment.override';

  static const String attendanceView = 'attendance.view';
  static const String attendanceCreate = 'attendance.create';
  static const String attendanceUpdate = 'attendance.update';

  static const String loanView = 'loan.view';
  static const String loanCreate = 'loan.create';
  static const String loanApprove = 'loan.approve';
  static const String loanRecover = 'loan.recover';

  static const String eosbView = 'eosb.view';
  static const String eosbCreate = 'eosb.create';
  static const String eosbApprove = 'eosb.approve';
  static const String eosbPay = 'eosb.pay';

  static const String expiryView = 'expiry.view';

  static const String ajeerView = 'ajeer.view';
  static const String ajeerUpdate = 'ajeer.update';

  static const String expenseView = 'expense.view';
  static const String expenseCreate = 'expense.create';
  static const String expenseApprove = 'expense.approve';
  static const String expensePay = 'expense.pay';

  static const String complianceView = 'compliance.view';
  static const String complianceCreate = 'compliance.create';
  static const String complianceUpdate = 'compliance.update';

  static const String assetView = 'asset.view';
  static const String assetCreate = 'asset.create';
  static const String assetUpdate = 'asset.update';
  static const String assetAssign = 'asset.assign';

  static const String trashView = 'trash.view';
  static const String trashRestore = 'trash.restore';
  static const String trashPurge = 'trash.purge';

  static const String auditView = 'audit.view';

  static const List<String> all = [
    dashboardView, dashboardFinance,
    employeeCreate, employeeView, employeeUpdate, employeeDelete, employeeExport,
    profileView, profileUpdate,
    reportView, reportExport,
    userCreate, userView, userUpdate, userDelete,
    roleCreate, roleView, roleUpdate, roleDelete,
    lookupView, lookupManage,
    ledgerView, ledgerExport,
    paymentView, paymentCreate, paymentReverse, paymentOverride,
    attendanceView, attendanceCreate, attendanceUpdate,
    loanView, loanCreate, loanApprove, loanRecover,
    eosbView, eosbCreate, eosbApprove, eosbPay,
    expiryView,
    ajeerView, ajeerUpdate,
    expenseView, expenseCreate, expenseApprove, expensePay,
    complianceView, complianceCreate, complianceUpdate,
    assetView, assetCreate, assetUpdate, assetAssign,
    trashView, trashRestore, trashPurge,
    auditView,
  ];
}
