import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B5FEF); // Vibrant Indigo
  static const Color primaryDark = Color(0xFF7B7FFF);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFFEC4899); // Pink accent for highlights
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color bgLight = Color(0xFFF7F8FC);
  static const Color bgDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF1A1D24);
  static const Color surfaceDarkElevated = Color(0xFF23262F);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B5FEF), Color(0xFF7B5FEF), Color(0xFF06B6D4)],
  );

  // Role colors used for Role Badge (bonus feature)
  static const Map<String, Color> roleColors = {
    'Super Admin': Color(0xFF8B5CF6),
    'Admin': Color(0xFF3B82F6),
    'Manager': Color(0xFF14B8A6),
    'Employee': Color(0xFFF59E0B),
    'Guest': Color(0xFF64748B),
    'HR Admin': Color(0xFFEC4899),
    'Payroll / Accounts': Color(0xFF10B981),
    'Regional Manager': Color(0xFF0EA5E9),
    'Department Manager': Color(0xFF6366F1),
    'Viewer / Auditor': Color(0xFF94A3B8),
  };

  static Color roleColor(String role) => roleColors[role] ?? Colors.grey;
}
