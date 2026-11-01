import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Bonus Feature - Role Badge.
class RoleBadge extends StatelessWidget {
  final String role;
  final double fontSize;
  const RoleBadge({super.key, required this.role, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
