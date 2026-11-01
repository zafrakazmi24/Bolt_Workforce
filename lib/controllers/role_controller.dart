import 'package:get/get.dart';
import '../core/constants/app_roles.dart';
import 'permission_controller.dart';

/// Requirement #10 - Roles Module (Super Admin only).
class RoleController extends GetxController {
  final PermissionController _permissionController =
      Get.find<PermissionController>();

  List<String> get roles => _permissionController.rolePermissions.keys.toList();

  List<String> permissionsOf(String role) =>
      _permissionController.permissionsForRole(role);

  bool isSystemRole(String role) => AppRoles.all.contains(role);

  void createRole(String name, List<String> permissions) {
    _permissionController.addRole(name, permissions);
  }

  void assignPermissions(String role, List<String> permissions) {
    _permissionController.updateRolePermissions(role, permissions);
  }
}
