import 'package:get/get.dart';
import '../constants/app_permissions.dart';
import 'app_routes.dart';
import 'route_middleware.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/employees/employee_list_screen.dart';
import '../../screens/employees/employee_form_screen.dart';
import '../../screens/employees/employee_details_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/roles/roles_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/master_data/master_data_screen.dart';
import '../../screens/expiry/expiry_screen.dart';
import '../../screens/ajeer/ajeer_screen.dart';
import '../../screens/ledger/ledger_screen.dart';
import '../../screens/payments/payments_screen.dart';
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/loans/loans_screen.dart';
import '../../screens/eosb/eosb_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/compliance/compliance_screen.dart';
import '../../screens/assets/assets_screen.dart';
import '../../screens/trash/trash_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/error/permission_denied_screen.dart';

/// Requirement #4 - Route Protection.
/// Every protected route declares the exact permission it needs; the
/// [PermissionMiddleware] enforces it before the screen is even built.
class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.dashboardView)],
    ),
    GetPage(
      name: AppRoutes.employees,
      page: () => const EmployeeListScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.employeeView)],
    ),
    GetPage(
      name: AppRoutes.employeeForm,
      page: () => const EmployeeFormScreen(),
      middlewares: [PermissionMiddleware(anyOf: [AppPermissions.employeeCreate, AppPermissions.employeeUpdate])],
    ),
    GetPage(
      name: AppRoutes.employeeDetails,
      page: () => const EmployeeDetailsScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.employeeView)],
    ),
    GetPage(
      name: AppRoutes.expiry,
      page: () => const ExpiryScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.expiryView)],
    ),
    GetPage(
      name: AppRoutes.ajeer,
      page: () => const AjeerScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.ajeerView)],
    ),
    GetPage(
      name: AppRoutes.ledger,
      page: () => const LedgerScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.ledgerView)],
    ),
    GetPage(
      name: AppRoutes.payments,
      page: () => const PaymentsScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.paymentView)],
    ),
    GetPage(
      name: AppRoutes.attendance,
      page: () => const AttendanceScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.attendanceView)],
    ),
    GetPage(
      name: AppRoutes.loans,
      page: () => const LoansScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.loanView)],
    ),
    GetPage(
      name: AppRoutes.eosb,
      page: () => const EosbScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.eosbView)],
    ),
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensesScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.expenseView)],
    ),
    GetPage(
      name: AppRoutes.compliance,
      page: () => const ComplianceScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.complianceView)],
    ),
    GetPage(
      name: AppRoutes.assets,
      page: () => const AssetsScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.assetView)],
    ),
    GetPage(
      name: AppRoutes.trash,
      page: () => const TrashScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.trashView)],
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.profileView)],
    ),
    GetPage(
      name: AppRoutes.users,
      page: () => const UsersScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.userView)],
    ),
    GetPage(
      name: AppRoutes.roles,
      page: () => const RolesScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.roleView)],
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.reportView)],
    ),
    GetPage(
      name: AppRoutes.masterData,
      page: () => const MasterDataScreen(),
      middlewares: [PermissionMiddleware(permission: AppPermissions.lookupView)],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(name: AppRoutes.permissionDenied, page: () => const PermissionDeniedScreen()),
  ];
}
