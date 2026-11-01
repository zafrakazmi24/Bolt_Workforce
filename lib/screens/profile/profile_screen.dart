import 'package:flutter/material.dart';
import '../../repositories/user_repository.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/permission_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/routes/app_routes.dart';
import '../../utils/validators.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/permission_chip.dart';
import '../../widgets/role_badge.dart';

/// Requirement #8 - Profile Module (view/update own profile only).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _auth = Get.find<AuthController>();
  final PermissionController _perm = Get.find<PermissionController>();
  late TextEditingController _name;
  late TextEditingController _phone;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser.value;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser.value!;
    final updated = user.copyWith(name: _name.text.trim(), phone: _phone.text.trim());

    if (Get.isRegistered<UserController>()) {
      Get.find<UserController>().updateUser(updated);
    } else {
      // UserController not created yet (Users screen never opened): write directly.
      UserRepository.instance.update(updated);
    }
    _auth.refreshCurrentUser(updated);

    setState(() => _editing = false);
    Get.snackbar('Profile Updated', 'Your profile has been updated successfully',
        snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(12), borderRadius: 12);
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.profile,
      title: 'My Profile',
      body: Obx(() {
        final user = _auth.currentUser.value;
        if (user == null) return const SizedBox.shrink();
        final canUpdate = _perm.hasPermission(AppPermissions.profileUpdate);
        final permissions = _perm.permissionsForRole(user.role);

        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 10),
                        RoleBadge(role: user.role, fontSize: 11),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Profile Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              if (canUpdate)
                                TextButton.icon(
                                  onPressed: () => setState(() => _editing = !_editing),
                                  icon: Icon(_editing ? Icons.close : Icons.edit_outlined, size: 18),
                                  label: Text(_editing ? 'Cancel' : 'Edit'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _name,
                            enabled: _editing,
                            validator: (v) => Validators.required(v, 'Name'),
                            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: user.email,
                            enabled: false,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            enabled: _editing,
                            validator: Validators.phone,
                            decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                          ),
                          if (_editing) ...[
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Permissions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: permissions.map((p) => PermissionChip(label: p)).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
