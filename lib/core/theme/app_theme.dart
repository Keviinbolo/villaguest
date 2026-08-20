import 'package:flutter/material.dart';

/// Paleta de colores y tema principal de VillaGuestRD.
///
/// Colores de marca:
///   teal  #17BA8D — verde azulado  → primary (AppBar, botones, FAB)
///   navy  #092AC9 — azul profundo  → secondary (acciones secundarias)
///   lime  #A0D916 — verde lima     → tertiary (acentos, badges)
///   sage  #8CC7AB — verde salvia   → primaryContainer
///   cyan  #5AFBE5 — cian suave     → secondaryContainer
class AppTheme {
  AppTheme._();

  // ── Colores de marca ────────────────────────────────────────────────
  static const Color navy = Color(0xFF092AC9);
  static const Color teal = Color(0xFF17BA8D);
  static const Color lime = Color(0xFFA0D916);
  static const Color sage = Color(0xFF8CC7AB);
  static const Color cyan = Color(0xFF5AFBE5);

  // ── Tema claro ──────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFD0D8F5),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,

          // Primary — teal verde (AppBar, botones principales, FAB)
          primary: teal,
          onPrimary: Color(0xFF002A18), // verde muy oscuro — contraste 8:1
          primaryContainer: sage,
          onPrimaryContainer: Color(0xFF002A18),

          // Secondary — azul profundo (acciones secundarias, links)
          secondary: navy,
          onSecondary: Colors.white,
          secondaryContainer: cyan,
          onSecondaryContainer: Color(0xFF00105A),

          // Tertiary — verde lima (acentos, badges)
          tertiary: lime,
          onTertiary: Color(0xFF1A2800),
          tertiaryContainer: Color(0xFFD8F097),
          onTertiaryContainer: Color(0xFF1A2800),

          // Error
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),

          // Surface
          surface: Color(0xFFF6FBF6),
          onSurface: Color(0xFF191C19),
          surfaceContainerHighest: Color(0xFFDEE8DE),
          onSurfaceVariant: Color(0xFF3F4F3F),

          // Outline
          outline: Color(0xFF6F7F6F),
          outlineVariant: Color(0xFFBECEBE),
          shadow: Colors.black,
          scrim: Colors.black,

          // Inversos
          inverseSurface: Color(0xFF2D312D),
          onInverseSurface: Color(0xFFECF2EC),
          inversePrimary: cyan,
        ),
      );
}
