import 'package:flutter/material.dart';

class AppColors {
  // Brand Florals
  static const Color primary = Color(0xFFE11D48); // Rose 600
  static const Color primaryDark = Color(0xFF9F1239); // Rose 800
  static const Color primaryLight = Color(0xFFFFE4E6); // Rose 100
  static const Color accent = Color(0xFF059669); // Emerald 600
  static const Color accentLight = Color(0xFFD1FAE5); // Emerald 100

  // Secondary Accents
  static const Color amber = Color(0xFFD97706); // Amber 600
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color violet = Color(0xFF7C3AED); // Violet 600
  static const Color violetLight = Color(0xFFEDE9FE);

  // Neutrals (Zomato/Swiggy style)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFF1F5F9); // Slate 100
  static const Color divider = Color(0xFFE2E8F0); // Slate 200

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Statuses
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBannerGradient = LinearGradient(
    colors: [Color(0xFF881337), Color(0xFFE11D48), Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

