import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Bonus Feature - Permission Chips (used in Roles module & Profile).
class PermissionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const PermissionChip({
    super.key,
    required this.label,
    this.selected = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: selected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
