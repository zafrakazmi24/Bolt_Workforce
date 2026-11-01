import 'dart:async';
import 'package:get/get.dart';
import '../core/constants/app_permissions.dart';
import '../core/constants/app_roles.dart';
import '../repositories/role_repository.dart';
import 'auth_controller.dart';

/// Requirement #3 - Permission Manager.
/// Role -> permissions come from Firestore `roles`; defaults are used until
/// the first snapshot arrives (and as a fallback for missing roles).
class PermissionController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();
  final RoleRepository _repo = RoleRepository.instance;

  final RxMap<String, List<String>> rolePermissions = <String, List<String>>{}.obs;
  StreamSubscription<Map<String, List<String>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    rolePermissions.assignAll(kDefaultRolePermissions);
    ever(_auth.currentUser, (u) => u == null ? _stop() : _listen());
  }

  void _merge(Map<String, List<String>> remote) {
    rolePermissions.assignAll({...kDefaultRolePermissions, ...remote});
  }

  /// One-shot load used right after login so the first screen is correct.
  Future<void> loadRoles() async {
    try {
      _merge(await _repo.getAll());
    } catch (_) {/* keep defaults */}
  }

  void _listen() {
    _sub?.cancel();
    _sub = _repo.watchAll().listen(_merge, onError: (_) {});
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
  }

  List<String> get _currentPermissions {
    final role = _auth.currentUser.value?.role;
    if (role == null) return [];
    if (role == AppRoles.superAdmin) return AppPermissions.all; // locked: always everything
    return rolePermissions[role] ?? [];
  }

  String? get currentRole => _auth.currentUser.value?.role;

  bool hasPermission(String permission) => _currentPermissions.contains(permission);
  bool hasRole(String role) => currentRole == role;
  bool hasAnyPermission(List<String> permissions) => permissions.any(_currentPermissions.contains);
  bool hasAllPermissions(List<String> permissions) => permissions.every(_currentPermissions.contains);

  // ---- Data scope (used by Dashboard / lists from Step 2 onwards) ----
  /// Non-null only for roles that must be restricted to one region.
  String? get scopeRegionId {
    final u = _auth.currentUser.value;
    return (u?.role == AppRoles.regionalManager) ? u?.regionId : null;
  }

  /// Non-null only for roles that must be restricted to one department.
  String? get scopeDepartmentId {
    final u = _auth.currentUser.value;
    return (u?.role == AppRoles.departmentManager) ? u?.departmentId : null;
  }

  List<String> permissionsForRole(String role) =>
      role == AppRoles.superAdmin ? AppPermissions.all : (rolePermissions[role] ?? []);

  void updateRolePermissions(String role, List<String> permissions) {
    if (role == AppRoles.superAdmin) return; // locked
    rolePermissions[role] = permissions;
    rolePermissions.refresh();
    _repo.save(role, permissions);
  }

  void addRole(String role, List<String> permissions) {
    rolePermissions[role] = permissions;
    rolePermissions.refresh();
    _repo.save(role, permissions);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
