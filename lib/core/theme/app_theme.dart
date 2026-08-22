import 'package:flutter/material.dart';

/// Paleta y tema principal de VillaGuestRD — Selva & Oro.
///
/// Colores de marca:
///   teal  #1B4332 — verde selva oscuro  → primary (AppBar, botones, FAB)
///   navy  #0D2218 — selva muy oscuro    → headers, texto fuerte
///   lime  #D4A017 — dorado              → acento (badges, alertas)
///   sage  #B7DECA — salvia claro        → primaryContainer
///   cyan  #FDEEC2 — dorado claro        → secondaryContainer
class AppTheme {
  AppTheme._();

  // ── Colores de marca ────────────────────────────────────────────────
  static const Color teal = Color(0xFF1B4332);   // verde selva (primario)
  static const Color navy = Color(0xFF0D2218);   // selva oscuro (headers, texto)
  static const Color lime = Color(0xFFD4A017);   // dorado (acento)
  static const Color sage = Color(0xFFB7DECA);   // salvia claro (primaryContainer)
  static const Color cyan = Color(0xFFFDEEC2);   // dorado claro (secondaryContainer)
  static const Color mint = Color(0xFF52B788);   // menta (tertiary)

  // ── Superficies ─────────────────────────────────────────────────────
  static const Color surfacePage  = Color(0xFFF4F8F5);  // fondo página
  static const Color surfaceCard  = Colors.white;
  static const Color borderSubtle = Color(0xFFCDD9D2);  // borde sutil verde-gris

  // ── Tema claro ──────────────────────────────────────────────────────
  static ThemeData get light {
    const borderRadius12 = BorderRadius.all(Radius.circular(12));
    const borderRadius16 = BorderRadius.all(Radius.circular(16));

    const borderSideDefault      = BorderSide(color: Color(0xFFC0D3C9));
    const borderSideFocused      = BorderSide(color: teal, width: 2);
    const borderSideError        = BorderSide(color: Color(0xFFBA1A1A));
    const borderSideErrorFocused = BorderSide(color: Color(0xFFBA1A1A), width: 2);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfacePage,

      // ── ColorScheme ─────────────────────────────────────────────────
      colorScheme: const ColorScheme(
        brightness: Brightness.light,

        // Primary — verde selva (AppBar, botones, FAB)
        primary: teal,
        onPrimary: Colors.white,
        primaryContainer: sage,
        onPrimaryContainer: navy,

        // Secondary — dorado (acento, badges)
        secondary: lime,
        onSecondary: navy,
        secondaryContainer: cyan,
        onSecondaryContainer: Color(0xFF3D2800),

        // Tertiary — menta (variación de acento)
        tertiary: mint,
        onTertiary: navy,
        tertiaryContainer: Color(0xFFCDF0D8),
        onTertiaryContainer: navy,

        // Error
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),

        // Surface
        surface: Color(0xFFF8FCF9),
        onSurface: Color(0xFF141F17),
        surfaceContainerHighest: Color(0xFFD2E8DA),
        onSurfaceVariant: Color(0xFF3D5244),

        // Outline
        outline: Color(0xFF6D8874),
        outlineVariant: Color(0xFFBDD0C4),
        shadow: Colors.black,
        scrim: Colors.black,

        // Inversos
        inverseSurface: Color(0xFF2A3C2F),
        onInverseSurface: Color(0xFFEEF2ED),
        inversePrimary: mint,
      ),

      // ── Cards ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius16,
          side: const BorderSide(color: borderSubtle),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),

      // ── Inputs ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF6FAF7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: borderRadius12,
          borderSide: borderSideDefault,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius12,
          borderSide: borderSideDefault,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius12,
          borderSide: borderSideFocused,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius12,
          borderSide: borderSideError,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius12,
          borderSide: borderSideErrorFocused,
        ),
        labelStyle: const TextStyle(color: Color(0xFF5A7568)),
        hintStyle: const TextStyle(color: Color(0xFF9AB5AA)),
      ),

      // ── Botones ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius12),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius12),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: borderSubtle),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius12),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // ── Dividers ─────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        space: 1,
        thickness: 1,
      ),

      // ── Drawer ───────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }
}
