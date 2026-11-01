import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../core/routes/app_routes.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'permission_controller.dart';

/// Authentication via Firebase Auth + profile/role from Firestore `users/{uid}`.
class AuthController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final UserRepository _userRepo = UserRepository.instance;
  final FirebaseAuth _fa = FirebaseAuth.instance;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool rememberMe = false.obs;

  StreamSubscription<UserModel?>? _profileSub;

  bool get isLoggedIn => currentUser.value != null;

  /// Called once from main() before runApp.
  Future<void> restoreSession() async {
    rememberMe.value = _storage.getRememberMe();
    final fu = _fa.currentUser;
    if (fu == null) return;
    if (!rememberMe.value) {
      await _fa.signOut();
      return;
    }
    try {
      final profile = await _userRepo.getById(fu.uid);
      if (profile == null || !profile.isActive) {
        await _fa.signOut();
        return;
      }
      await _loadPermissions();
      currentUser.value = profile;
      _watchOwnProfile(fu.uid);
    } catch (_) {
      // Offline / transient failure: stay logged out, user can retry on login.
      await _fa.signOut();
    }
  }

  Future<bool> login(String email, String password, {bool remember = false}) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final cred = await _fa.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      final profile = await _userRepo.getById(cred.user!.uid);
      if (profile == null) {
        await _fa.signOut();
        errorMessage.value = 'No profile found for this account. Contact your administrator.';
        return false;
      }
      if (!profile.isActive) {
        await _fa.signOut();
        errorMessage.value = 'This account has been deactivated.';
        return false;
      }
      await _loadPermissions();
      currentUser.value = profile;
      rememberMe.value = remember;
      await _storage.setRememberMe(remember);
      _watchOwnProfile(profile.id);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapError(e.code);
      return false;
    } catch (_) {
      errorMessage.value = 'Something went wrong. Check your connection and try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Keeps the session in sync if an admin changes this user's role/status.
  void _watchOwnProfile(String uid) {
    _profileSub?.cancel();
    _profileSub = _userRepo.watchById(uid).listen((p) {
      if (p == null || !p.isActive) {
        logout();
      } else {
        currentUser.value = p;
      }
    }, onError: (_) {});
  }

  Future<void> _loadPermissions() async {
    if (Get.isRegistered<PermissionController>()) {
      await Get.find<PermissionController>().loadRoles();
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Login failed ($code)';
    }
  }

  void refreshCurrentUser(UserModel updated) => currentUser.value = updated;

  Future<void> logout() async {
    await _profileSub?.cancel();
    _profileSub = null;
    currentUser.value = null;
    await _fa.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
