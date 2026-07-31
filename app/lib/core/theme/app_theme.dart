import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF1F7A4D);

  static const Color good = Color(0xFF1F7A4D);
  static const Color moderate = Color(0xFFB7791F);
  static const Color poor = Color(0xFFC53030);

  static const Color riskLow = Color(0xFF2B6CB0);
  static const Color riskMedium = Color(0xFFB7791F);
  static const Color riskHigh = Color(0xFFC53030);

  static const Color confidenceGood = Color(0xFFE6F4EA);
  static const Color confidenceLow = Color(0xFFFFF4D6);

  static Color scoreColor(int value, BuildContext context) {
    if (value >= 80) return good;
    if (value >= 55) return moderate;
    return Theme.of(context).colorScheme.error;
  }

  static String scoreLabel(int value) {
    if (value >= 80) return 'Good composition';
    if (value >= 55) return 'Needs attention';
    return 'Risky composition';
  }
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double cardPadding = 16;
  static const double screenPadding = 20;
  static const double bottomSheetPadding = 20;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double full = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
}
