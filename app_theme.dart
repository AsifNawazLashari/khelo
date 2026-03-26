// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Brand
  static const Color primary = Color(0xFF00D4A0);       // Emerald Cricket Green
  static const Color primaryDark = Color(0xFF00A87E);
  static const Color primaryLight = Color(0xFF4DFFCC);

  // Secondary
  static const Color secondary = Color(0xFFFFB800);     // Gold accent
  static const Color secondaryDark = Color(0xFFCC9200);

  // Backgrounds
  static const Color bgDark = Color(0xFF0A0F1E);        // Deep navy
  static const Color bgCard = Color(0xFF111827);        // Card surface
  static const Color bgElevated = Color(0xFF1A2235);    // Elevated surface
  static const Color bgInput = Color(0xFF1E293B);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color textOnPrimary = Color(0xFF0A0F1E);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Special
  static const Color live = Color(0xFFEF4444);
  static const Color wicket = Color(0xFFEF4444);
  static const Color boundary = Color(0xFF3B82F6);
  static const Color six = Color(0xFFFFB800);
  static const Color four = Color(0xFF3B82F6);

  // Dividers
  static const Color divider = Color(0xFF1E293B);
  static const Color border = Color(0xFF2D3748);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4A0), Color(0xFF0088CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0F1E), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2235), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.bgCard,
        background: AppColors.bgDark,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      tabBarTheme: _buildTabBarTheme(),
      chipTheme: _buildChipTheme(),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      dialogTheme: _buildDialogTheme(),
      snackBarTheme: _buildSnackBarTheme(),
      floatingActionButtonTheme: _buildFABTheme(),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.rajdhani(
        fontSize: 57, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.rajdhani(
        fontSize: 45, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.rajdhani(
        fontSize: 36, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.rajdhani(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: 0.5,
      ),
      headlineMedium: GoogleFonts.rajdhani(
        fontSize: 28, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.3,
      ),
      headlineSmall: GoogleFonts.rajdhani(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.rajdhani(
        fontSize: 22, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textMuted, height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: AppColors.textMuted, letterSpacing: 0.5,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() => AppBarTheme(
    backgroundColor: AppColors.bgCard,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.rajdhani(
      fontSize: 22, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: 0.5,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
    surfaceTintColor: Colors.transparent,
  );

  static CardTheme _buildCardTheme() => CardTheme(
    color: AppColors.bgCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border, width: 1),
    ),
    margin: EdgeInsets.zero,
  );

  static ElevatedButtonThemeData _buildElevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
      );

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5,
          ),
        ),
      );

  static TextButtonThemeData _buildTextButtonTheme() => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      textStyle: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3,
      ),
    ),
  );

  static InputDecorationTheme _buildInputDecorationTheme() => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgInput,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.inter(
      fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w400,
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: GoogleFonts.inter(
      fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600,
    ),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
  );

  static TabBarTheme _buildTabBarTheme() => TabBarTheme(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.textMuted,
    indicatorColor: AppColors.primary,
    indicatorSize: TabBarIndicatorSize.tab,
    labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
    unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
  );

  static ChipThemeData _buildChipTheme() => ChipThemeData(
    backgroundColor: AppColors.bgElevated,
    selectedColor: AppColors.primary.withOpacity(0.2),
    disabledColor: AppColors.bgInput,
    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  );

  static BottomNavigationBarThemeData _buildBottomNavTheme() =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      );

  static DialogTheme _buildDialogTheme() => DialogTheme(
    backgroundColor: AppColors.bgCard,
    elevation: 24,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: GoogleFonts.rajdhani(
      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    ),
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14, color: AppColors.textSecondary,
    ),
  );

  static SnackBarThemeData _buildSnackBarTheme() => SnackBarThemeData(
    backgroundColor: AppColors.bgElevated,
    contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
    elevation: 8,
  );

  static FloatingActionButtonThemeData _buildFABTheme() =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 8,
        shape: CircleBorder(),
      );
}
