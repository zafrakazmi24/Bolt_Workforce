import 'package:get/get.dart';
import '../../controllers/permission_controller.dart';

/// Shortcuts for the current user's data scope and permissions.
class Scope {
  Scope._();
  static PermissionController get _p => Get.find<PermissionController>();
  static String? get region => _p.scopeRegionId;
  static String? get dept => _p.scopeDepartmentId;
  static bool can(String permission) => _p.hasPermission(permission);
}
