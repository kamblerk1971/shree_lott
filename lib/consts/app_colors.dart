// import 'dart:ui';
//
// class AppColors {
//   static const headerBlue = Color(0xFF0B2D5C);
//   static const timePink = Color(0xFFD98F8F);
//   static const chipGreen = Color(0xFF3FA36C);
//   static const chipBlue = Color(0xFF7DBBFF);
//   static const chipGrey = Color(0xFF6C7A89);
//
//   static const yellowBar = Color(0xFFFFE44D);
//   static const seriesGreen = Color(0xFF7BC043);
//
//   static const highBlue = Color(0xFF4DA6FF);
//   static const lowCyan = Color(0xFF6ED3F3);
//
//   static const qtyBlue = Color(0xFF0B2D5C);
//   static const amountGold = Color(0xFFD9B65B);
//
//   static const borderGrey = Color(0xFF9E9E9E);
// }

import 'package:flutter/material.dart';

/// Premium Color Palette Constants
/// Custom colors: #1e1860, #4556cc, #1f114c
/// Used across the Shreelott app for consistent branding
class AppColors {
  // === PRIMARY COLORS (Premium Blue Palette) ===
  /// Dark blue - primary background color (#1e1860)
  static const Color primaryDark = Color(0xFF1e1860);

  /// Medium blue - primary gradient and accent (#4556cc)
  static const Color primaryMedium = Color(0xFF4556cc);

  /// Darker blue - secondary gradient (#1f114c)
  static const Color primaryDarker = Color(0xFF1f114c);

  // === ACCENT COLORS ===
  /// Gold/Yellow - for highlights and premium elements
  static const Color accentGold = Color(0xFFFFD700);

  /// Green - for success/positive actions
  static const Color accentGreen = Color(0xFF00C853);

  /// Yellow - for warning/secondary actions
  static const Color accentYellow = Color(0xFFFDD835);

  // === TEXT COLORS ===
  /// White text - primary text color
  static const Color textPrimary = Colors.white;

  /// Light gray - secondary/muted text
  static const Color textSecondary = Color(0xFFB0BEC5);

  /// Dark gray/black - for dark theme text
  static const Color textDark = Color(0xFF212121);

  // === BORDER & OVERLAY ===
  /// White for borders and glass effect
  static const Color borderLight = Color(0xFFFFFFFF);

  /// Black for overlay and depth
  static const Color overlayDark = Color(0xFF000000);

  // === SHADOW COLORS ===
  /// Dark shadow for depth effect
  static const Color shadowDark = Color(0xFF0D0D1F);

  // === UTILITY COLORS ===
  /// Transparent black overlay
  static Color overlayBlackTransparent(double opacity) =>
      overlayDark.withOpacity(opacity);

  /// Transparent white border
  static Color borderLightTransparent(double opacity) =>
      borderLight.withOpacity(opacity);

  /// Transparent gold accent
  static Color accentGoldTransparent(double opacity) =>
      accentGold.withOpacity(opacity);

  // === GRADIENT PRESETS ===
  /// Premium dark gradient - for main backgrounds
  static LinearGradient get premiumDarkGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryDarker.withOpacity(0.8)],
  );

  /// Premium radial gradient - for card backgrounds
  static RadialGradient get premiumRadialGradient => RadialGradient(
    center: const Alignment(0.3, -0.3),
    radius: 1.2,
    colors: [
      primaryMedium.withOpacity(0.95),
      primaryDarker,
    ],
    stops: const [0.0, 1.0],
  );

  /// Divider gradient - subtle separator lines
  static LinearGradient get dividerGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      borderLight.withOpacity(0),
      borderLight.withOpacity(0.3),
      borderLight.withOpacity(0),
    ],
  );

  // === BOX SHADOW PRESETS ===
  /// Premium card shadow - deep shadow for elevation
  static List<BoxShadow> get premiumCardShadow => [
    BoxShadow(
      color: shadowDark.withOpacity(0.8),
      blurRadius: 40,
      offset: const Offset(0, 25),
      spreadRadius: 5,
    ),
    BoxShadow(
      color: overlayDark.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 10),
    ),
  ];

  /// Button shadow - subtle shadow for interactive elements
  static BoxShadow buttonShadow(Color buttonColor) => BoxShadow(
    color: buttonColor.withOpacity(0.4),
    blurRadius: 12,
    offset: const Offset(0, 6),
  );

  // === THEME DATA ===
  /// Create a ThemeData with the premium color palette
  static ThemeData get premiumTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryMedium,
      secondary: accentGold,
      surface: primaryDark,
      error: Colors.red,
    ),
    scaffoldBackgroundColor: primaryDark,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryMedium,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryMedium,
      textTheme: ButtonTextTheme.primary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
      ),
    ),
  );
}