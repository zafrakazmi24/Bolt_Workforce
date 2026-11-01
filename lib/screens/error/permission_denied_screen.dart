import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

/// Requirement #4 - 403 Permission Denied screen.
class PermissionDeniedScreen extends StatelessWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 54, color: AppColors.danger),
              ),
              const SizedBox(height: 24),
              const Text('403',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.danger)),
              const SizedBox(height: 8),
              const Text('Permission Denied',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'You do not have the required permission\nto access this page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
