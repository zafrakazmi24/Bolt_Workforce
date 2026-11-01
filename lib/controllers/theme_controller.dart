import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/storage_service.dart';

/// Bonus Feature - Dark Mode / Theme Switcher.
class ThemeController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final RxBool isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDark.value = _storage.getDarkMode();
  }

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    isDark.value = !isDark.value;
    _storage.setDarkMode(isDark.value);
    Get.changeThemeMode(themeMode);
  }
}
