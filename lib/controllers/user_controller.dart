import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../core/constants/app_roles.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_controller.dart';

/// Requirement #9 - Users Module (Super Admin & Admin only).
class UserController extends GetxController {
  final UserRepository _repo = UserRepository.instance;
  final AuthController _auth = Get.find<AuthController>();

  final RxList<UserModel> users = <UserModel>[].obs;
  StreamSubscription<List<UserModel>>? _sub;

  @override
  void onInit() {
    super.onInit();
    // Re-subscribe on every login/logout (controller is permanent).
    ever(_auth.currentUser, (_) => _resubscribe());
    _resubscribe();
  }

  void _resubscribe() {
    _sub?.cancel();
    users.clear();
    if (!_auth.isLoggedIn) return;
    _sub = _repo.watchAll().listen(users.assignAll, onError: (_) {});
  }

  /// Admin cannot manage Super Admin accounts.
  bool canManage(UserModel target) {
    final myRole = _auth.currentUser.value?.role;
    if (myRole == AppRoles.superAdmin) return true;
    if (myRole == AppRoles.admin) return target.role != AppRoles.superAdmin;
    return false;
  }

  /// Returns null on success, or an error message.
  Future<String?> addUser(UserModel user, String password) async {
    try {
      await _repo.createWithPassword(user, password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'This email is already registered';
      if (e.code == 'weak-password') return 'Password is too weak (min 6 characters)';
      return 'Could not create user (${e.code})';
    } catch (e) {
      return 'Could not create user: $e';
    }
  }

  Future<String?> updateUser(UserModel user) async {
    try {
      await _repo.update(user);
      return null;
    } catch (e) {
      return 'Could not update: $e';
    }
  }

  /// Soft delete = deactivate (cannot sign in, record kept for audit).
  Future<void> deleteUser(String id) => _repo.deactivate(id);

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
