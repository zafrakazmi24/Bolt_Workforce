import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/permission_controller.dart';

/// Requirement #6 - UI Protection.
/// Wrap any widget (button, icon, tile...) and it will only render if the
/// current user holds the given permission(s). Otherwise it disappears.
class PermissionGate extends StatelessWidget {
  final String? permission;
  final List<String>? anyOf;
  final List<String>? allOf;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    this.permission,
    this.anyOf,
    this.allOf,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final perm = Get.find<PermissionController>();
    return Obx(() {
      bool allowed = true;
      if (permission != null) allowed = perm.hasPermission(permission!);
      if (anyOf != null) allowed = allowed && perm.hasAnyPermission(anyOf!);
      if (allOf != null) allowed = allowed && perm.hasAllPermissions(allOf!);
      if (allowed) return child;
      return fallback ?? const SizedBox.shrink();
    });
  }
}
