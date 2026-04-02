import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color surfaceLight = Color(0xFFFFFBFE);

  static const Color surfaceContainerDark = Color(0xFF211F26);
  static const Color surfaceContainerLight = Color(0xFFF3EDF7);

  static const Color surfaceContainerHighDark = Color(0xFF2B2930);
  static const Color surfaceContainerHighLight = Color(0xFFECE6F0);

  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  static const Color onSurfaceLight = Color(0xFF1C1B1F);

  static const Color onSurfaceVariantDark = Color(0xFFCAC4D0);
  static const Color onSurfaceVariantLight = Color(0xFF49454F);

  static const Color outlineDark = Color(0xFF938F99);
  static const Color outlineLight = Color(0xFF79747E);

  static const Color outlineVariantDark = Color(0xFF49454F);
  static const Color outlineVariantLight = Color(0xFFCAC4D0);

  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31111D);

  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static Color scrimDark = Colors.black.withOpacity(0.32);
  static Color scrimLight = Colors.black.withOpacity(0.32);

  static List<BoxShadow> elevationLight1 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> elevationLight2 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevationLight3 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.11),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevationDark1 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> elevationDark2 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevationDark3 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
