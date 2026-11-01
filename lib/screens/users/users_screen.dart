import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/lookup_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/constants/app_roles.dart';
import '../../core/routes/app_routes.dart';
import '../../models/user_model.dart';
import '../../utils/validators.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/permission_gate.dart';
import '../../widgets/role_badge.dart';

/// Requirement #9 - Users Module (CRUD, Super Admin & Admin only).
/// Admin cannot manage Super Admin accounts.
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController(), permanent: true);

    return MainShell(
      currentRoute: AppRoutes.users,
      title: 'Users',
      floatingActionButton: PermissionGate(
        permission: AppPermissions.userCreate,
        child: FloatingActionButton.extended(
          onPressed: () => _openUserDialog(context, controller),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add User'),
        ),
      ),
      body: Obx(() {
        final users = controller.users;
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final u = users[i];
            final manageable = controller.canManage(u);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.roleColor(u.role).withOpacity(0.15),
                    child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: TextStyle(color: AppColors.roleColor(u.role), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(u.isActive ? u.name : '${u.name} (inactive)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: u.isActive ? null : Colors.grey)),
                        const SizedBox(height: 3),
                        Text(u.email, style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  RoleBadge(role: u.role, fontSize: 10),
                  const SizedBox(width: 6),
                  if (manageable) ...[
                    PermissionGate(
                      permission: AppPermissions.userUpdate,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _openUserDialog(context, controller, existing: u),
                      ),
                    ),
                    PermissionGate(
                      permission: AppPermissions.userDelete,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                        onPressed: () => _confirmDelete(context, controller, u),
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
                    ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, UserController controller, UserModel u) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deactivate User'),
        content: Text('"${u.name}" will no longer be able to sign in. Continue?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              controller.deleteUser(u.id);
              Get.back();
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _openUserDialog(BuildContext context, UserController controller, {UserModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final myRole = Get.find<AuthController>().currentUser.value?.role;
    final assignableRoles = myRole == AppRoles.superAdmin
        ? AppRoles.all
        : AppRoles.all.where((r) => r != AppRoles.superAdmin).toList();
    String selectedRole = existing?.role ?? assignableRoles.first;
    final passCtrl = TextEditingController();
    final lookups = Get.find<LookupController>();
    String? selectedRegion = existing?.regionId;
    String? selectedDept = existing?.departmentId;
    bool saving = false;

    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Add User' : 'Edit User'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => Validators.required(v, 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    enabled: existing == null, // email belongs to Firebase Auth
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: Validators.phone,
                  ),
                  if (existing == null) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Temporary password (min 6)'),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                    ),
                  ],
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: assignableRoles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRole = v ?? selectedRole),
                  ),
                  if (selectedRole == AppRoles.regionalManager) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRegion,
                      decoration: const InputDecoration(labelText: 'Assigned region'),
                      items: lookups.activeRegions
                          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                          .toList(),
                      validator: (v) => v == null ? 'Select a region' : null,
                      onChanged: (v) => setState(() => selectedRegion = v),
                    ),
                  ],
                  if (selectedRole == AppRoles.departmentManager) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      decoration: const InputDecoration(labelText: 'Assigned department'),
                      items: lookups.activeDepartments
                          .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                          .toList(),
                      validator: (v) => v == null ? 'Select a department' : null,
                      onChanged: (v) => setState(() => selectedDept = v),
                    ),
                  ],
                ],
              ),
            )),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final region = selectedRole == AppRoles.regionalManager ? selectedRegion : null;
                      final dept = selectedRole == AppRoles.departmentManager ? selectedDept : null;
                      String? error;
                      if (existing == null) {
                        error = await controller.addUser(
                          UserModel(
                            id: '',
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            role: selectedRole,
                            phone: phoneCtrl.text.trim(),
                            regionId: region,
                            departmentId: dept,
                          ),
                          passCtrl.text,
                        );
                      } else {
                        error = await controller.updateUser(existing.copyWith(
                          name: nameCtrl.text.trim(),
                          role: selectedRole,
                          phone: phoneCtrl.text.trim(),
                          regionId: region,
                          departmentId: dept,
                          clearRegion: region == null,
                          clearDepartment: dept == null,
                        ));
                      }
                      if (error == null) {
                        Get.back();
                      } else {
                        setState(() => saving = false);
                        Get.snackbar('Error', error, backgroundColor: AppColors.danger, colorText: Colors.white);
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }
}
