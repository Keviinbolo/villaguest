import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/auth/presentation/screens/home_screen.dart';
import 'package:villaguest/features/auth/presentation/screens/splash_screen.dart';
import 'package:villaguest/features/auth/presentation/screens/staff_home_screen.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Decide qué mostrar según sesión, rol y villa asignada:
/// - Sin sesión              → LoginScreen
/// - Inicializando           → SplashScreen
/// - Sesión + sin villa      → pantalla "Sin villa asignada"
/// - Sesión + admin + villa  → HomeScreen
/// - Sesión + staff + villa  → StaffHomeScreen
/// - Sesión + sin rol válido → pantalla "Sin acceso"
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) return const SplashScreen();

    if (!auth.isLoggedIn) return const LoginScreen();

    // Tiene sesión pero no tiene villa asignada en Firestore
    if (!auth.hasVilla) {
      return _noVillaScreen(context, auth);
    }

    if (auth.isAdmin) return const HomeScreen();
    if (auth.isStaff) return const StaffHomeScreen();

    // Tiene sesión + villa pero sin rol reconocido
    return _noAccessScreen(context, auth);
  }

  Widget _noVillaScreen(BuildContext context, AuthProvider auth) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.villa_outlined, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Sin villa asignada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'La cuenta ${auth.user?.email ?? ''} no tiene una villa asignada.\n'
                'Un administrador debe añadir el campo "villa" al documento '
                'del usuario en Firestore.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noAccessScreen(BuildContext context, AuthProvider auth) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Sin acceso',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'La cuenta ${auth.user?.email ?? ''} no tiene un rol asignado.\n'
                'Contacta al administrador.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
