import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class ClaraTheme {
  ClaraTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ClaraColors.purple,
        primary: ClaraColors.purple,
        surface: ClaraColors.surface,
      ),
      scaffoldBackgroundColor: ClaraColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: ClaraColors.textPrimary,
        displayColor: ClaraColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ClaraColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ClaraColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: ClaraColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: ClaraColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ClaraColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ClaraColors.purple,
          foregroundColor: ClaraColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ClaraColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ClaraColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ClaraColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ClaraColors.purple, width: 1.5),
        ),
        labelStyle: const TextStyle(color: ClaraColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ClaraColors.surface,
        indicatorColor: ClaraColors.purpleLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: ClaraColors.purple,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: ClaraColors.textTertiary,
            fontSize: 11,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: ClaraColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
