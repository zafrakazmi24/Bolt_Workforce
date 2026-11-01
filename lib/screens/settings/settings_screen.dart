import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';
import '../../core/services/sample_data_seed.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/role_badge.dart';

/// Bonus Features - Theme Switcher / Dark Mode + Logout Confirmation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final auth = Get.find<AuthController>();

    return MainShell(
      currentRoute: AppRoutes.settings,
      title: 'Settings',
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                context,
                title: 'Appearance',
                child: Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Switch between light & dark theme'),
                      secondary: const Icon(Icons.dark_mode_rounded),
                      value: theme.isDark.value,
                      onChanged: (_) => theme.toggleTheme(),
                    )),
              ),
              const SizedBox(height: 16),
              if (kDebugMode && auth.currentUser.value?.role == AppRoles.superAdmin) ...[
                _sectionCard(
                  context,
                  title: 'Developer (debug build only)',
                  child: const _SampleDataButton(),
                ),
                const SizedBox(height: 16),
              ],
              _sectionCard(
                context,
                title: 'Account',
                child: Obx(() {
                  final user = auth.currentUser.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(user?.name ?? ''),
                        subtitle: Text(user?.email ?? ''),
                        trailing: RoleBadge(role: user?.role ?? '', fontSize: 10),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                        title: const Text('Logout', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                        onTap: () => _confirmLogout(context, auth),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthController auth) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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
}


class _SampleDataButton extends StatefulWidget {
  const _SampleDataButton();
  @override
  State<_SampleDataButton> createState() => _SampleDataButtonState();
}

class _SampleDataButtonState extends State<_SampleDataButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final msg = await SampleDataSeed.run();
      Get.snackbar('Done', msg, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(12));
    } catch (e) {
      Get.snackbar('Failed', '$e', backgroundColor: AppColors.danger, colorText: Colors.white,
          snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(12), duration: const Duration(seconds: 8));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: _busy ? null : _run,
        icon: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.dataset_outlined, size: 18),
        label: const Text('Load sample workforce data (60 employees)'),
      );
}
