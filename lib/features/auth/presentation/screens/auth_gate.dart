import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/auth/presentation/screens/home_screen.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Decide qué mostrar según el estado de sesión: un loader mientras
/// Firebase confirma si hay sesión guardada, LoginScreen si no hay
/// nadie logueado, o HomeScreen si sí. Se pone como `home` del
/// MaterialApp en vez de HomeScreen directamente.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
