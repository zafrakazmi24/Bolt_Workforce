import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only UI preferences. Users, roles and permissions now live in
/// Firebase (Auth + Firestore) - nothing sensitive is stored on the device here.
class StorageService extends GetxService {
  static const _kRemember = 'remember_me';
  static const _kDarkMode = 'dark_mode';

  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<void> setRememberMe(bool value) async => _prefs.setBool(_kRemember, value);
  bool getRememberMe() => _prefs.getBool(_kRemember) ?? false;

  Future<void> setDarkMode(bool value) async => _prefs.setBool(_kDarkMode, value);
  bool getDarkMode() => _prefs.getBool(_kDarkMode) ?? false;
}
