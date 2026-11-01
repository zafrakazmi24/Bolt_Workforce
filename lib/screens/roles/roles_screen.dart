import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/role_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/routes/app_routes.dart';
import '../../utils/validators.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/permission_chip.dart';

/// Requirement #10 - Roles Module (Super Admin only):
/// Role List, Create Role, Assign Permissions.
class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RoleController(), permanent: true);

    return MainShell(
      currentRoute: AppRoutes.roles,
      title: 'Roles & Permissions',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createRoleDialog(context, controller),
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Create Role'),
      ),
      body: Obx(() {
        // .obs map -> trigger rebuild reference
        final roles = controller.roles;
        return ListView.separated(
          itemCount: roles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final role = roles[i];
            final permissions = controller.permissionsOf(role);
            final isLocked = role == 'Super Admin';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_moon_rounded, color: AppColors.roleColor(role), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(role, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      Text('${permissions.length} permissions',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                      if (!isLocked)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _assignPermissionsDialog(context, controller, role, permissions),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: permissions.map((p) => PermissionChip(label: p)).toList(),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _createRoleDialog(BuildContext context, RoleController controller) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final Set<String> selected = {};

    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Role'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Role Name'),
                    validator: (v) => Validators.required(v, 'Role name'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Assign Permissions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppPermissions.all.map((p) {
                      final isSelected = selected.contains(p);
                      return PermissionChip(
                        label: p,
                        selected: isSelected,
                        onTap: () => setState(() => isSelected ? selected.remove(p) : selected.add(p)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                controller.createRole(nameCtrl.text.trim(), selected.toList());
                Get.back();
              },
              child: const Text('Create'),
            ),
          ],
        );
      }),
    );
  }

  void _assignPermissionsDialog(
      BuildContext context, RoleController controller, String role, List<String> current) {
    final Set<String> selected = {...current};

    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Assign Permissions — $role'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppPermissions.all.map((p) {
                final isSelected = selected.contains(p);
                return PermissionChip(
                  label: p,
                  selected: isSelected,
                  onTap: () => setState(() => isSelected ? selected.remove(p) : selected.add(p)),
                );
              }).toList(),
            )),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                controller.assignPermissions(role, selected.toList());
                Get.back();
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }
}
