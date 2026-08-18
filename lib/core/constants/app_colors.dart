import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF179E43);
  static const Color primaryDark = Color(0xFF0B7D35);
  static const Color primaryLight = Color(0xFFE8F5E9);

  static const Color background = Color(0xFFF5F7FB);
  static const Color card = Colors.white;

  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Colors.grey;

  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color danger = Colors.red;
  static const Color info = Color(0xFF1976D2);

  static const Color border = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x14000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primary,
      primaryDark,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
