import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/permission_controller.dart';
import 'app_routes.dart';

/// Requirement #4 - Route Protection.
/// Redirects to /login if not authenticated.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// Redirects to /403 (Permission Denied) if the logged-in user lacks
/// the required permission for this route.
class PermissionMiddleware extends GetMiddleware {
  final String? permission;
  final List<String>? anyOf;

  PermissionMiddleware({this.permission, this.anyOf});

  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }

    final perm = Get.find<PermissionController>();

    if (permission != null && !perm.hasPermission(permission!)) {
      return const RouteSettings(name: AppRoutes.permissionDenied);
    }

    if (anyOf != null && !perm.hasAnyPermission(anyOf!)) {
      return const RouteSettings(name: AppRoutes.permissionDenied);
    }

    return null;
  }
}

/// Prevents an already-logged-in user from seeing the Login screen again.
class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }
    return null;
  }
}
