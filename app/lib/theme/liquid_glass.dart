import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'material_expressive.dart';

/// Liquid Glass Theme for iOS
///
/// Inspired by Apple's iOS 26 Liquid Glass design language:
/// - Translucent, frosted glass surfaces
/// - Soft blurs and subtle transparency
/// - Fluid, organic shapes
/// - Light-refracting, luminous aesthetic
/// - Depth through layered translucency
class LiquidGlassTheme {
  LiquidGlassTheme._();

  // ─── Color Palette ────────────────────────────────────────────────────
  // Soft, ethereal colors that complement glass effects

  static const Color _primaryLight = Color(0xFF007AFF);  // iOS blue
  static const Color _primaryDark = Color(0xFF5AC8FA);
  static const Color _secondaryLight = Color(0xFFFF2D55); // iOS pink
  static const Color _secondaryDark = Color(0xFFFF6482);
  static const Color _surfaceLight = Color(0xFFF2F2F7);  // iOS system gray 6
  static const Color _surfaceDark = Color(0xFF000000);
  static const Color _surfaceContainerLight = Color(0xFFFFFFFF);
  static const Color _surfaceContainerDark = Color(0xFF1C1C1E);
  static const Color _glassLight = Color(0xCCF8F8FC);    // Translucent white
  static const Color _glassDark = Color(0xBB2C2C2E);     // Translucent dark
  static const Color _onSurfaceLight = Color(0xFF000000);
  static const Color _onSurfaceDark = Color(0xFFFFFFFF);

  // Chat bubble colors — softer for glass aesthetic
  static const Color _sentBubbleLight = Color(0xFF007AFF);
  static const Color _sentBubbleDark = Color(0xFF0A84FF);
  static const Color _receivedBubbleLight = Color(0xFFE9E9EB);
  static const Color _receivedBubbleDark = Color(0xFF2C2C2E);

  // ─── Light Theme ──────────────────────────────────────────────────────

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: Colors.white,
      secondary: _secondaryLight,
      onSecondary: Colors.white,
      surface: _surfaceLight,
      onSurface: _onSurfaceLight,
      surfaceContainerHighest: _surfaceContainerLight,
      error: const Color(0xFFFF3B30),
      outline: const Color(0xFFC7C7CC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme, false),
      cardTheme: _cardTheme(false),
      inputDecorationTheme: _inputTheme(colorScheme, false),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      iconTheme: IconThemeData(color: _onSurfaceLight.withValues(alpha: 0.6)),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFC7C7CC),
        thickness: 0.33,
      ),
      extensions: [
        ChatBubbleTheme(
          sentColor: _sentBubbleLight,
          receivedColor: _receivedBubbleLight,
          sentTextColor: Colors.white,
          receivedTextColor: _onSurfaceLight,
        ),
        LiquidGlassColors(
          glassColor: _glassLight,
          blurSigma: 25.0,
          glassBorderColor: Colors.white.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: Colors.black,
      secondary: _secondaryDark,
      onSecondary: Colors.black,
      surface: _surfaceDark,
      onSurface: _onSurfaceDark,
      surfaceContainerHighest: _surfaceContainerDark,
      error: const Color(0xFFFF453A),
      outline: const Color(0xFF48484A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme, true),
      cardTheme: _cardTheme(true),
      inputDecorationTheme: _inputTheme(colorScheme, true),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      iconTheme: IconThemeData(color: _onSurfaceDark.withValues(alpha: 0.6)),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF48484A),
        thickness: 0.33,
      ),
      extensions: [
        ChatBubbleTheme(
          sentColor: _sentBubbleDark,
          receivedColor: _receivedBubbleDark,
          sentTextColor: Colors.white,
          receivedTextColor: _onSurfaceDark,
        ),
        LiquidGlassColors(
          glassColor: _glassDark,
          blurSigma: 30.0,
          glassBorderColor: Colors.white.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  // ─── Typography (SF Pro style via Inter) ──────────────────────────────

  static TextTheme _textTheme(ColorScheme cs) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        letterSpacing: 0.37,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        letterSpacing: 0.36,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        letterSpacing: -0.26,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
        letterSpacing: -0.41,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
        letterSpacing: -0.41,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
        letterSpacing: -0.24,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: cs.onSurface.withValues(alpha: 0.6),
        letterSpacing: -0.08,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: cs.primary,
        letterSpacing: -0.24,
      ),
    );
  }

  // ─── Component Themes ─────────────────────────────────────────────────

  static AppBarTheme _appBarTheme(ColorScheme cs, bool isDark) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark
          ? _surfaceDark.withValues(alpha: 0.85)
          : _surfaceLight.withValues(alpha: 0.85),
      foregroundColor: cs.onSurface,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
        letterSpacing: -0.41,
      ),
    );
  }

  static CardThemeData _cardTheme(bool isDark) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? _surfaceContainerDark : _surfaceContainerLight,
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme cs, bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFE5E5EA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.35),
        fontSize: 17,
        letterSpacing: -0.41,
      ),
    );
  }

  static FloatingActionButtonThemeData _fabTheme(ColorScheme cs) {
    return FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const CircleBorder(),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
      ),
    );
  }
}

/// Custom theme extension for Liquid Glass effects
class LiquidGlassColors extends ThemeExtension<LiquidGlassColors> {
  final Color glassColor;
  final double blurSigma;
  final Color glassBorderColor;

  const LiquidGlassColors({
    required this.glassColor,
    required this.blurSigma,
    required this.glassBorderColor,
  });

  @override
  LiquidGlassColors copyWith({
    Color? glassColor,
    double? blurSigma,
    Color? glassBorderColor,
  }) {
    return LiquidGlassColors(
      glassColor: glassColor ?? this.glassColor,
      blurSigma: blurSigma ?? this.blurSigma,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
    );
  }

  @override
  LiquidGlassColors lerp(ThemeExtension<LiquidGlassColors>? other, double t) {
    if (other is! LiquidGlassColors) return this;
    return LiquidGlassColors(
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      glassBorderColor:
          Color.lerp(glassBorderColor, other.glassBorderColor, t)!,
    );
  }
}
