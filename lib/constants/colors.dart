import 'package:flutter/material.dart';

class AppColors {
  // Slate / Navy Dark Palette
  static const Color background = Color(0xFF0D1527);
  static const Color surface = Color(0xFF161F33);
  static const Color surfaceVariant = Color(0xFF212D4A);
  static const Color cardBackground = Color(0xFF182238);
  static const Color borderSubtle = Color(0xFF263554);

  // Accents
  static const Color accentCyan = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFEF4444);

  // Chart Specific Colors (matching Screenshot 1)
  static const Color chartRed = Color(0xFFEF4444);
  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartYellow = Color(0xFFF59E0B);
  static const Color chartGreen = Color(0xFF10B981);

  // Gradient definitions
  static const LinearGradient radiantGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Utility
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
}
