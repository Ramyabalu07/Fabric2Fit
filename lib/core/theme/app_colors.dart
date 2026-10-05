import 'package:flutter/material.dart';

abstract final class AppColors {
  static const lavender = Color(0xFFB9A7E0);
  static const deepPurple = Color(0xFF5B477A);
  static const cream = Color(0xFFFFF9F5);
  static const white = Color(0xFFFFFFFF);
  static const rose = Color(0xFFD98FA3);
  static const charcoal = Color(0xFF29252D);

  static const lavenderSoft = Color(0xFFEDE7F8);
  static const roseSoft = Color(0xFFF8E6EB);
  static const muted = Color(0xFF7A7280);
  static const divider = Color(0xFFEDE6EE);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepPurple, Color(0xFF8B74B8), rose],
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: deepPurple.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
