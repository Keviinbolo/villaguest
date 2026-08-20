import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/features/auth/presentation/screens/splash_screen.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/cleaning/providers/cleaning_provider.dart';
import 'package:villaguest/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:villaguest/features/guests/presentation/providers/guest_provider.dart';

import 'firebase_options.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // Espera a que Firebase esté listo Y a que pase al menos 1 segundo,
  // para que la splash siempre sea visible aunque el servidor responda rápido.
  static final Future<void> _init = Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Future.delayed(const Duration(seconds: 3)),
  ]);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VillaGuestRD',
      theme: AppTheme.light,
      home: FutureBuilder<void>(
        future: _init,
        builder: (context, snapshot) {
          // Firebase aún inicializando → splash
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }

          // Error al conectar con Firebase
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No se pudo conectar con el servidor.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          // Firebase listo → montar providers y puerta de auth
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
                create: (_) => BookingProvider(),
                update: (_, authProvider, bookingProvider) {
                  bookingProvider!.updateAuthorization(
                    authProvider.isLoggedIn && authProvider.isAdmin,
                  );
                  return bookingProvider;
                },
              ),
              ChangeNotifierProxyProvider<AuthProvider, CleaningProvider>(
                create: (_) => CleaningProvider(),
                update: (_, authProvider, cleaningProvider) {
                  cleaningProvider!.updateAuthorization(authProvider.isLoggedIn);
                  return cleaningProvider;
                },
              ),
              ChangeNotifierProxyProvider<AuthProvider, MaintenanceProvider>(
                create: (_) => MaintenanceProvider(),
                update: (_, authProvider, maintenanceProvider) {
                  maintenanceProvider!.updateAuthorization(authProvider.isLoggedIn);
                  return maintenanceProvider;
                },
              ),
              ChangeNotifierProxyProvider<AuthProvider, GuestProvider>(
                create: (_) => GuestProvider(),
                update: (_, authProvider, guestProvider) {
                  guestProvider!.updateAuthorization(
                    authProvider.isLoggedIn && authProvider.isAdmin,
                  );
                  return guestProvider;
                },
              ),
            ],
            child: const AuthGate(),
          );
        },
      ),
    );
  }
}
