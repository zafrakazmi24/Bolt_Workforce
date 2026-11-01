import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/permission_controller.dart';
import '../core/constants/app_permissions.dart';
import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';
import 'role_badge.dart';

class _MenuItem {
  final String label;
  final IconData icon;
  final String route;
  final String? permission;
  const _MenuItem(this.label, this.icon, this.route, {this.permission});
}

const List<_MenuItem> _menuItems = [
  _MenuItem('Dashboard', Icons.dashboard_rounded, AppRoutes.dashboard, permission: AppPermissions.dashboardView),
  _MenuItem('Employees', Icons.groups_rounded, AppRoutes.employees, permission: AppPermissions.employeeView),
  _MenuItem('Employee Ledger', Icons.menu_book_rounded, AppRoutes.ledger, permission: AppPermissions.ledgerView),
  _MenuItem('Payment Log', Icons.payments_rounded, AppRoutes.payments, permission: AppPermissions.paymentView),
  _MenuItem('Attendance', Icons.event_available_rounded, AppRoutes.attendance, permission: AppPermissions.attendanceView),
  _MenuItem('Loans & Advances', Icons.account_balance_wallet_rounded, AppRoutes.loans, permission: AppPermissions.loanView),
  _MenuItem('EOSB Settlements', Icons.work_history_rounded, AppRoutes.eosb, permission: AppPermissions.eosbView),
  _MenuItem('Expiry Alerts', Icons.notification_important_rounded, AppRoutes.expiry, permission: AppPermissions.expiryView),
  _MenuItem('Outsourced (Ajeer)', Icons.handshake_rounded, AppRoutes.ajeer, permission: AppPermissions.ajeerView),
  _MenuItem('Remote Expenses', Icons.receipt_long_rounded, AppRoutes.expenses, permission: AppPermissions.expenseView),
  _MenuItem('Compliance Costs', Icons.verified_user_rounded, AppRoutes.compliance, permission: AppPermissions.complianceView),
  _MenuItem('Company Assets', Icons.devices_other_rounded, AppRoutes.assets, permission: AppPermissions.assetView),
  _MenuItem('Trash', Icons.delete_outline_rounded, AppRoutes.trash, permission: AppPermissions.trashView),
  _MenuItem('Reports', Icons.bar_chart_rounded, AppRoutes.reports, permission: AppPermissions.reportView),
  _MenuItem('Users', Icons.manage_accounts_rounded, AppRoutes.users, permission: AppPermissions.userView),
  _MenuItem('Roles', Icons.admin_panel_settings_rounded, AppRoutes.roles, permission: AppPermissions.roleView),
  _MenuItem('Master Data', Icons.tune_rounded, AppRoutes.masterData, permission: AppPermissions.lookupView),
  _MenuItem('Notifications', Icons.notifications_rounded, AppRoutes.notifications),
  _MenuItem('My Profile', Icons.person_rounded, AppRoutes.profile, permission: AppPermissions.profileView),
  _MenuItem('Settings', Icons.settings_rounded, AppRoutes.settings),
];

/// Requirement #5 - Sidebar / Drawer.
/// Menu items automatically change based on logged-in user's permissions.
class AppSidebar extends StatelessWidget {
  final String currentRoute;
  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final perm = Get.find<PermissionController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final user = auth.currentUser.value;
      final visibleItems = _menuItems.where((item) {
        if (item.permission == null) return true;
        return perm.hasPermission(item.permission!);
      }).toList();

      return Container(
        width: 260,
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Bolt Workforce\nLedger',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14, height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppColors.roleColor(user?.role ?? '').withOpacity(0.15),
                      child: Text(
                        (user?.name.isNotEmpty ?? false)
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.roleColor(user?.role ?? ''),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          RoleBadge(role: user?.role ?? '', fontSize: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    final selected = item.route == currentRoute;
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      child: Material(
                        color: selected
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (!selected) {
                              if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                                Navigator.of(context).maybePop();
                              }
                              Get.offNamed(item.route);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(item.icon,
                                    size: 20,
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.grey[600]),
                                const SizedBox(width: 14),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight:
                                        selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primary
                                        : (isDark ? Colors.white70 : Colors.black87),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _confirmLogout(context, auth),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: const [
                          Icon(Icons.logout_rounded,
                              size: 20, color: AppColors.danger),
                          SizedBox(width: 14),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Bonus Feature - Logout Confirmation.
void _confirmLogout(BuildContext context, AuthController auth) {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () {
            Get.back();
            auth.logout();
          },
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}
