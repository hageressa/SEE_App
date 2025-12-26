import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:see_app/models/emotion_data.dart';  // Import instead of redefining

// Re-export enums for backward compatibility
export 'package:see_app/models/emotion_data.dart' show EmotionType, AlertSeverity;

/// Main theme class for the SEE App
/// Contains colors, text styles, and component decorations
class SeeAppTheme {
  // --- NEW THERAPY-INSPIRED PALETTE ---
  // A calming, professional, and warm palette.
  static const Color primaryColor = Color(0xFF2A9D8F);      // Soothing Teal Green
  static const Color primaryColorDark = Color(0xFF264653);  // Deep Slate Green (for dark bg)
  static const Color secondaryColor = Color(0xFFF4A261);    // Warm Sandy Peach
  static const Color accentColor = Color(0xFFE76F51);       // Gentle Burnt Coral

  // Background colors - clean and non-distracting
  static const Color lightBackground = Color(0xFFF8F9FA);   // Soft off-white
  static const Color darkBackground = Color(0xFF264653);     // Deep Slate Green
  static const Color darkSecondaryBackground = Color(0xFF2A9D8F); // Primary color for accents
  static const Color cardBackground = Colors.white;
  static const Color darkCardBackground = Color(0xFF2C5A6D); // Muted dark teal for cards

  // Text colors - high contrast for readability
  static const Color textPrimary = Color(0xFF212529);     // Near-black for light theme
  static const Color textSecondary = Color(0xFF6c757d);   // Gray for secondary text
  static const Color textLight = Colors.white;
  static const Color textDarkPrimary = Color(0xFFF8F9FA); // Off-white for dark theme
  static const Color textDarkSecondary = Color(0xFFadb5bd); // Light gray for dark theme

  // Emotion colors - Harmonized with the new theme
  static const Color joyColor = Color(0xFFF4A261);         // Using secondary color
  static const Color sadnessColor = Color(0xFF457B9D);       // Soft blue (still fits)
  static const Color angerColor = Color(0xFFE76F51);         // Using accent color
  static const Color fearColor = Color(0xFF8A7FBA);          // Lavender purple (still fits)
  static const Color calmColor = Color(0xFF2A9D8F);          // Using primary color

  // Alert & Status colors - Aligned with the new palette
  static const Color alertHigh = Color(0xFFE76F51);
  static const Color alertMedium = Color(0xFFF4A261);
  static const Color alertLow = Color(0xFF2A9D8F);
  static const Color success = Color(0xFF2A9D8F);
  static const Color info = Color(0xFF457B9D);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFE76F51);

  // Fonts
  static const String primaryFont = 'Nunito';
  static const String secondaryFont = 'OpenSans';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing scale - consistent spacing system
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Card elevations
  static const double elevationNone = 0.0;
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationLarge = 4.0;
  static const double elevationXLarge = 8.0;

  // Screen breakpoints
  static const double screenSmall = 360.0;
  static const double screenMedium = 600.0;
  static const double screenLarge = 900.0;
  static const double screenXLarge = 1200.0;

  // Text styles with better hierarchy
  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: textPrimary,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: secondaryFont,
    fontWeight: FontWeight.normal,
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: secondaryFont,
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: secondaryFont,
    fontWeight: FontWeight.normal,
    fontSize: 12,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: textLight,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: textLight,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: textLight,
    letterSpacing: 0.5,
  );

  // Card decorations - simplified and more consistent
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );
  
  static BoxDecoration darkCardDecoration = BoxDecoration(
    color: darkCardBackground,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );
  
  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      onPrimary: textLight,
      onSecondary: textPrimary, // Dark text on peachy color
      background: lightBackground,
      surface: cardBackground,
      onSurface: textPrimary,
      error: error,
      onError: textLight,
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    fontFamily: primaryFont,
    textTheme: const TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
    appBarTheme: AppBarTheme(
      color: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: primaryFont,
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: textLight,
      ),
      iconTheme: const IconThemeData(color: textLight),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return primaryColor.withOpacity(0.4);
          }
          return primaryColor;
        }),
        foregroundColor: MaterialStateProperty.all(textLight),
        elevation: MaterialStateProperty.resolveWith<double>((states) {
          if (states.contains(MaterialState.pressed)) {
            return 1.0;
          }
          return 2.0;
        }),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
        textStyle: MaterialStateProperty.all(labelLarge),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primaryColor),
        side: MaterialStateProperty.resolveWith<BorderSide>((states) {
          if (states.contains(MaterialState.disabled)) {
            return BorderSide(color: primaryColor.withOpacity(0.4), width: 2);
          }
          return const BorderSide(color: primaryColor, width: 2);
        }),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
        textStyle: MaterialStateProperty.all(labelLarge.copyWith(color: primaryColor)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primaryColor),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing8),
        ),
        textStyle: MaterialStateProperty.all(
          labelMedium.copyWith(color: primaryColor),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: alertHigh, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
      hintStyle: bodyMedium.copyWith(color: textSecondary.withOpacity(0.6)),
      errorStyle: bodySmall.copyWith(color: alertHigh),
    ),
    cardTheme: CardTheme(
      color: cardBackground,
      elevation: elevationNone, // Use decoration instead for more control
      margin: const EdgeInsets.symmetric(vertical: spacing8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
      size: 24,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: spacing24,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardBackground,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontFamily: primaryFont, 
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: primaryFont,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: Color(0xFFE0E0E0),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardBackground,
      contentTextStyle: const TextStyle(
        fontFamily: secondaryFont,
        color: textLight,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      textStyle: const TextStyle(
        color: textLight,
        fontSize: 12,
        fontFamily: secondaryFont,
      ),
    ),
    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  
  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      onPrimary: textLight,
      onSecondary: textPrimary, // Dark text on peachy color
      background: darkBackground,
      surface: darkCardBackground,
      onSurface: textDarkPrimary,
      error: error,
      onError: textLight,
    ),
    brightness: Brightness.dark,
    fontFamily: primaryFont,
    textTheme: TextTheme(
      displayLarge: displayLarge.copyWith(color: textDarkPrimary),
      displayMedium: displayMedium.copyWith(color: textDarkPrimary),
      displaySmall: displaySmall.copyWith(color: textDarkPrimary),
      headlineLarge: headlineLarge.copyWith(color: textDarkPrimary),
      headlineMedium: headlineMedium.copyWith(color: textDarkPrimary),
      headlineSmall: headlineSmall.copyWith(color: textDarkPrimary),
      bodyLarge: bodyLarge.copyWith(color: textDarkPrimary),
      bodyMedium: bodyMedium.copyWith(color: textDarkPrimary),
      bodySmall: bodySmall.copyWith(color: textDarkSecondary),
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
    appBarTheme: AppBarTheme(
      color: darkBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textDarkPrimary),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: headlineMedium.copyWith(color: textDarkPrimary),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        textStyle: labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textDarkPrimary,
        textStyle: labelMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      labelStyle: bodyMedium.copyWith(color: textDarkSecondary),
    ),
    cardTheme: CardTheme(
      color: darkCardBackground,
      elevation: elevationNone,
      margin: const EdgeInsets.symmetric(vertical: spacing8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    iconTheme: const IconThemeData(color: textDarkSecondary),
    dividerColor: const Color(0xFF495057),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkCardBackground,
      selectedItemColor: primaryColor,
      unselectedItemColor: textDarkSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: textDarkSecondary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontFamily: primaryFont, 
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: primaryFont,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: Colors.grey.shade800,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardBackground.withOpacity(0.9),
      contentTextStyle: const TextStyle(
        fontFamily: secondaryFont,
        color: textDarkPrimary,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.9),
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      textStyle: const TextStyle(
        color: textDarkPrimary,
        fontSize: 12,
        fontFamily: secondaryFont,
      ),
    ),
    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  
  // Helper methods for responsive design
  
  /// Returns appropriate font size based on screen width
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final double width = MediaQuery.of(context).size.width;
    if (width <= screenSmall) {
      return baseFontSize * 0.85;
    } else if (width <= screenMedium) {
      return baseFontSize * 0.9;
    } else if (width <= screenLarge) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1;
    }
  }
  
  /// Returns number of columns for a grid based on screen width
  static int getResponsiveGridCount(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width <= screenSmall) {
      return 1;
    } else if (width <= screenMedium) {
      return 2;
    } else if (width <= screenLarge) {
      return 3;
    } else {
      return 4;
    }
  }
  
  /// Returns appropriate spacing based on screen size
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final double width = MediaQuery.of(context).size.width;
    if (width <= screenSmall) {
      return baseSpacing * 0.75;
    } else if (width <= screenMedium) {
      return baseSpacing * 0.85;
    } else {
      return baseSpacing;
    }
  }
  
  /// Returns card decoration based on brightness
  static BoxDecoration getCardDecoration(Brightness brightness) {
    return brightness == Brightness.light ? cardDecoration : darkCardDecoration;
  }
  
  /// Returns emphasized card decoration with stronger shadow
  static BoxDecoration getEmphasizedCardDecoration(Brightness brightness) {
    return BoxDecoration(
      color: brightness == Brightness.light ? cardBackground : darkCardBackground,
      borderRadius: BorderRadius.circular(radiusLarge),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(brightness == Brightness.light ? 0.1 : 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
      ],
    );
  }
  
  /// Returns an emotion color based on type
  static Color getEmotionColor(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
        return joyColor;
      case EmotionType.sadness:
        return sadnessColor;
      case EmotionType.anger:
        return angerColor;
      case EmotionType.fear:
        return fearColor;
      case EmotionType.calm:
        return calmColor;
      default:
        return Colors.grey;
    }
  }
  
  /// Returns a linearGradient based on emotion type
  static LinearGradient getEmotionGradient(EmotionType type) {
    final baseColor = getEmotionColor(type);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withOpacity(0.7),
      ],
    );
  }
  
  /// Returns background color for an emotion with appropriate opacity
  static Color getEmotionBackgroundColor(EmotionType type, Brightness brightness) {
    final baseColor = getEmotionColor(type);
    final opacity = brightness == Brightness.light ? 0.1 : 0.2;
    return baseColor.withOpacity(opacity);
  }
  
  /// Returns an icon for an emotion type
  static IconData getEmotionIcon(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
        return Icons.sentiment_very_satisfied;
      case EmotionType.sadness:
        return Icons.sentiment_very_dissatisfied;
      case EmotionType.anger:
        return Icons.mood_bad;
      case EmotionType.fear:
        return Icons.warning_amber;
      case EmotionType.calm:
        return Icons.sentiment_satisfied;
      default:
        return Icons.emoji_emotions;
    }
  }
  
  /// Returns a color for an alert severity level
  static Color getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return alertHigh;
      case AlertSeverity.medium:
        return alertMedium;
      case AlertSeverity.low:
        return alertLow;
      default:
        return alertLow;
    }
  }
  
  /// Returns text for an alert severity level
  static String getAlertText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.low:
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  // Helper functions to get theme properties
  static bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color getTextColor(BuildContext context) => isDarkMode(context) ? textDarkPrimary : textPrimary;
  
  static Color getSecondaryTextColor(BuildContext context) => isDarkMode(context) ? textDarkSecondary : textSecondary;

  static Color getBackgroundColor(BuildContext context) => isDarkMode(context) ? darkBackground : lightBackground;

  static Color getCardColor(BuildContext context) => isDarkMode(context) ? darkCardBackground : cardBackground;
}

/// Extension on BuildContext to provide easy access to SeeAppTheme colors and styles
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get secondaryColor => SeeAppTheme.secondaryColor;
  Color get accentColor => SeeAppTheme.accentColor;
  
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  // Responsive helpers
  double responsiveSize(double value) => SeeAppTheme.getResponsiveSpacing(this, value);
  double responsiveFontSize(double value) => SeeAppTheme.getResponsiveFontSize(this, value);
  int responsiveGridCount() => SeeAppTheme.getResponsiveGridCount(this);
}

// Enums moved to emotion_data.dart to avoid conflicts