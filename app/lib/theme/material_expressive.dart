import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material Expressive Theme for Android
///
/// Inspired by Material 3 Expressive design guidelines:
/// - Vibrant, expressive color palettes
/// - Rounded shapes with large corner radii
/// - Dynamic motion and emphasis
/// - Personalized, joyful aesthetic
class MaterialExpressiveTheme {
  MaterialExpressiveTheme._();

  // ─── Color Palette ────────────────────────────────────────────────────
  // Instagram-inspired gradient with Material Expressive vibrancy

  static const Color _primaryLight = Color(0xFF6C5CE7);  // Vibrant purple
  static const Color _primaryDark = Color(0xFFAB8DF8);
  static const Color _secondaryLight = Color(0xFFFD79A8); // Instagram pink
  static const Color _secondaryDark = Color(0xFFFFB1C8);
  static const Color _tertiaryLight = Color(0xFF00B894);  // Fresh teal
  static const Color _tertiaryDark = Color(0xFF55EFC4);
  static const Color _surfaceLight = Color(0xFFFAF9FE);
  static const Color _surfaceDark = Color(0xFF121212);
  static const Color _surfaceContainerLight = Color(0xFFFFFFFF);
  static const Color _surfaceContainerDark = Color(0xFF1E1E2E);
  static const Color _onSurfaceLight = Color(0xFF1A1A2E);
  static const Color _onSurfaceDark = Color(0xFFE8E8F0);
  static const Color _sentBubbleLight = Color(0xFF6C5CE7);
  static const Color _sentBubbleDark = Color(0xFF5A4BD1);
  static const Color _receivedBubbleLight = Color(0xFFF0EFFE);
  static const Color _receivedBubbleDark = Color(0xFF2A2A3E);

  // ─── Light Theme ──────────────────────────────────────────────────────

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: Colors.white,
      secondary: _secondaryLight,
      onSecondary: Colors.white,
      tertiary: _tertiaryLight,
      surface: _surfaceLight,
      onSurface: _onSurfaceLight,
      surfaceContainerHighest: _surfaceContainerLight,
      error: const Color(0xFFE74C3C),
      outline: Colors.grey.shade300,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme, false),
      cardTheme: _cardTheme(false),
      inputDecorationTheme: _inputTheme(colorScheme, false),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      bottomNavigationBarTheme: _bottomNavTheme(colorScheme, false),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      iconTheme: IconThemeData(color: _onSurfaceLight.withValues(alpha: 0.7)),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 0.5),
      extensions: [
        ChatBubbleTheme(
          sentColor: _sentBubbleLight,
          receivedColor: _receivedBubbleLight,
          sentTextColor: Colors.white,
          receivedTextColor: _onSurfaceLight,
        ),
      ],
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: const Color(0xFF1A1A2E),
      secondary: _secondaryDark,
      onSecondary: const Color(0xFF1A1A2E),
      tertiary: _tertiaryDark,
      surface: _surfaceDark,
      onSurface: _onSurfaceDark,
      surfaceContainerHighest: _surfaceContainerDark,
      error: const Color(0xFFFF6B6B),
      outline: Colors.grey.shade800,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme, true),
      cardTheme: _cardTheme(true),
      inputDecorationTheme: _inputTheme(colorScheme, true),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      bottomNavigationBarTheme: _bottomNavTheme(colorScheme, true),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      iconTheme: IconThemeData(color: _onSurfaceDark.withValues(alpha: 0.7)),
      dividerTheme: DividerThemeData(color: Colors.grey.shade800, thickness: 0.5),
      extensions: [
        ChatBubbleTheme(
          sentColor: _sentBubbleDark,
          receivedColor: _receivedBubbleDark,
          sentTextColor: Colors.white,
          receivedTextColor: _onSurfaceDark,
        ),
      ],
    );
  }

  // ─── Typography ───────────────────────────────────────────────────────

  static TextTheme _textTheme(ColorScheme cs) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
        letterSpacing: -1.0,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: cs.onSurface.withValues(alpha: 0.6),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    );
  }

  // ─── Component Themes ─────────────────────────────────────────────────

  static AppBarTheme _appBarTheme(ColorScheme cs, bool isDark) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: isDark ? _surfaceContainerDark : _surfaceContainerLight,
      foregroundColor: cs.onSurface,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }

  static CardThemeData _cardTheme(bool isDark) {
    return CardThemeData(
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Expressive large radius
      ),
      color: isDark ? _surfaceContainerDark : _surfaceContainerLight,
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme cs, bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28), // Pill-shaped
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      hintStyle: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  static FloatingActionButtonThemeData _fabTheme(ColorScheme cs) {
    return FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  static BottomNavigationBarThemeData _bottomNavTheme(
      ColorScheme cs, bool isDark) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? _surfaceContainerDark : _surfaceContainerLight,
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.onSurface.withValues(alpha: 0.5),
      elevation: 0,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Custom theme extension for chat bubble colors
class ChatBubbleTheme extends ThemeExtension<ChatBubbleTheme> {
  final Color sentColor;
  final Color receivedColor;
  final Color sentTextColor;
  final Color receivedTextColor;

  const ChatBubbleTheme({
    required this.sentColor,
    required this.receivedColor,
    required this.sentTextColor,
    required this.receivedTextColor,
  });

  @override
  ChatBubbleTheme copyWith({
    Color? sentColor,
    Color? receivedColor,
    Color? sentTextColor,
    Color? receivedTextColor,
  }) {
    return ChatBubbleTheme(
      sentColor: sentColor ?? this.sentColor,
      receivedColor: receivedColor ?? this.receivedColor,
      sentTextColor: sentTextColor ?? this.sentTextColor,
      receivedTextColor: receivedTextColor ?? this.receivedTextColor,
    );
  }

  @override
  ChatBubbleTheme lerp(ThemeExtension<ChatBubbleTheme>? other, double t) {
    if (other is! ChatBubbleTheme) return this;
    return ChatBubbleTheme(
      sentColor: Color.lerp(sentColor, other.sentColor, t)!,
      receivedColor: Color.lerp(receivedColor, other.receivedColor, t)!,
      sentTextColor: Color.lerp(sentTextColor, other.sentTextColor, t)!,
      receivedTextColor:
          Color.lerp(receivedTextColor, other.receivedTextColor, t)!,
    );
  }
}
