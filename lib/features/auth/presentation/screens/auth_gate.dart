import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/auth/presentation/screens/home_screen.dart';
import 'package:villaguest/features/auth/presentation/screens/splash_screen.dart';
import 'package:villaguest/features/auth/presentation/screens/staff_home_screen.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Decide qué mostrar según sesión y rol:
/// - Sin sesión → LoginScreen
/// - Sesión + rol 'admin' → HomeScreen (acceso completo)
/// - Sesión + rol 'staff' → StaffHomeScreen (limpieza y mantenimiento)
/// - Sesión + sin rol en Firestore → pantalla de acceso denegado
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return const SplashScreen();
    }

    if (!auth.isLoggedIn) return const LoginScreen();

    if (auth.isAdmin) return const HomeScreen();
    if (auth.isStaff) return const StaffHomeScreen();

    // Usuario autenticado en Firebase pero sin documento /users/{uid}
    // o con un rol desconocido. Mostramos error y opción de cerrar sesión.
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