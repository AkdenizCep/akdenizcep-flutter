import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF135BEC);
  static const secondaryColor = Color(0xFFE8601C);
  static const backgroundLight = Color(0xFFF7F8FB);
  static const backgroundDark = Color(0xFF0D1422);

  static const _fontFamily = 'Roboto';

  static final _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE8F0FF),
        onPrimaryContainer: const Color(0xFF082B76),
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFFFE7D6),
        onSecondaryContainer: const Color(0xFF662500),
        surface: Colors.white,
        onSurface: const Color(0xFF171A22),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFFBFCFF),
        surfaceContainer: const Color(0xFFF2F5FA),
        surfaceContainerHigh: const Color(0xFFECEFF6),
        surfaceContainerHighest: const Color(0xFFE5EAF3),
        outline: const Color(0xFF7A8494),
        outlineVariant: const Color(0xFFD6DCE8),
        error: const Color(0xFFBA1A1A),
        errorContainer: const Color(0xFFFFDAD6),
      );

  static final _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF8CB2FF),
        onPrimary: const Color(0xFF002D75),
        primaryContainer: const Color(0xFF0C3D96),
        onPrimaryContainer: const Color(0xFFD9E4FF),
        secondary: const Color(0xFFFFB68A),
        onSecondary: const Color(0xFF522000),
        secondaryContainer: const Color(0xFF743200),
        onSecondaryContainer: const Color(0xFFFFDBCA),
        surface: const Color(0xFF121A29),
        onSurface: const Color(0xFFE7EAF1),
        surfaceContainerLowest: const Color(0xFF0A101B),
        surfaceContainerLow: const Color(0xFF111927),
        surfaceContainer: const Color(0xFF172132),
        surfaceContainerHigh: const Color(0xFF202B3C),
        surfaceContainerHighest: const Color(0xFF2A3547),
        outline: const Color(0xFF8B96A8),
        outlineVariant: const Color(0xFF3E4A5E),
        error: const Color(0xFFFFB4AB),
        errorContainer: const Color(0xFF93000A),
      );

  static final light = _buildTheme(
    colorScheme: _lightColorScheme,
    scaffoldBackground: backgroundLight,
  );

  static final dark = _buildTheme(
    colorScheme: _darkColorScheme,
    scaffoldBackground: backgroundDark,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
  }) {
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.62),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: selected ? 25 : 24,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.72),
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
            alpha: 0.72,
          ),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          highlightColor: colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.82),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        headerBackgroundColor: colorScheme.primary,
        headerForegroundColor: colorScheme.onPrimary,
        headerHeadlineStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
        headerHelpStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary.withValues(alpha: 0.82),
          letterSpacing: 1.2,
        ),
        weekdayStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
        dayStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        todayBorder: BorderSide(color: colorScheme.primary, width: 1.4),
        dividerColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        dialBackgroundColor: colorScheme.surfaceContainer,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final color = colorScheme.onSurface;
    final mutedColor = colorScheme.onSurfaceVariant;

    return TextTheme(
      displayLarge: TextStyle(
        color: color,
        fontSize: 48,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        color: color,
        fontSize: 42,
        height: 1.10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        color: color,
        fontSize: 36,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        color: color,
        fontSize: 32,
        height: 1.16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: color,
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        color: color,
        fontSize: 24,
        height: 1.22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: color,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: color,
        fontSize: 16,
        height: 1.32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: color,
        fontSize: 14,
        height: 1.36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: color,
        fontSize: 16,
        height: 1.52,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        color: color,
        fontSize: 14,
        height: 1.46,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        color: mutedColor,
        fontSize: 12,
        height: 1.42,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        color: color,
        fontSize: 14,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: mutedColor,
        fontSize: 12,
        height: 1.20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        color: mutedColor,
        fontSize: 11,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}
