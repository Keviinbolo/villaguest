import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/auth/presentation/screens/home_screen.dart';
import 'package:villaguest/features/auth/presentation/screens/staff_home_screen.dart';


import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Decide qué mostrar según sesión y rol:
/// - Sin sesión → LoginScreen
/// - Sesión + rol 'staff' → StaffHomeScreen (acceso limitado: limpieza,
///   y más adelante mantenimiento)
/// - Sesión + rol 'admin' (o sin rol asignado aún, por compatibilidad)
///   → HomeScreen (acceso completo)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    return authProvider.isStaff ? const StaffHomeScreen() : const HomeScreen();
  }
}