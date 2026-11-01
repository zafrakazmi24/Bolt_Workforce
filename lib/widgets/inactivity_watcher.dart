import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../core/config/app_config.dart';

/// Logs the user out after [AppConfig.inactivityMinutes] without any touch.
class InactivityWatcher extends StatefulWidget {
  final Widget child;
  const InactivityWatcher({super.key, required this.child});
  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _t;

  void _reset() {
    _t?.cancel();
    _t = Timer(Duration(minutes: AppConfig.inactivityMinutes), () {
      final auth = Get.find<AuthController>();
      if (auth.isLoggedIn) {
        auth.logout();
        Get.snackbar('Session expired', 'You were logged out due to inactivity.',
            snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(12));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Listener(behavior: HitTestBehavior.translucent, onPointerDown: (_) => _reset(), child: widget.child);
}
