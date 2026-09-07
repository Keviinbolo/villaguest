import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/config/supabase_config.dart';
import 'package:villaguest/core/services/notification_service.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/widgets/connectivity_banner.dart';
import 'package:villaguest/features/auth/presentation/screens/splash_screen.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/cleaning/providers/cleaning_provider.dart';
import 'package:villaguest/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:villaguest/features/guests/presentation/providers/guest_provider.dart';
import 'package:villaguest/features/settings/presentation/providers/villa_settings_provider.dart';

import 'firebase_options.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Must be registered before runApp for background message handling.
  FirebaseMessaging.onBackgroundMessage(onFirebaseBackgroundMessage);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final Future<void> _init = Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    ),
    Future.delayed(const Duration(seconds: 3)),
  ]).then((_) => _initCrashlytics());

  // Crashlytics no soporta Flutter Web; en el resto de plataformas
  // capturamos errores de framework y de zonas no atrapados.
  static Future<void> _initCrashlytics() async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snapshot) {
        // Firebase inicializando → splash sin providers (no se necesitan aún)
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const SplashScreen(),
          );
        }

        // Error al conectar con Firebase
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No se pudo conectar con el servidor.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        // Firebase listo: MultiProvider envuelve al MaterialApp completo
        // para que todas las rutas navegadas tengan acceso a los providers.
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
              create: (_) => BookingProvider(),
              update: (_, auth, provider) {
                provider!.updateAuthorization(
                  auth.isLoggedIn && auth.isAdmin && auth.hasVilla,
                  auth.villaId,
                );
                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, CleaningProvider>(
              create: (_) => CleaningProvider(),
              update: (_, auth, provider) {
                provider!.updateAuthorization(
                  auth.isLoggedIn && auth.hasVilla,
                  auth.villaId,
                );
                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, MaintenanceProvider>(
              create: (_) => MaintenanceProvider(),
              update: (_, auth, provider) {
                provider!.updateAuthorization(
                  auth.isLoggedIn && auth.hasVilla,
                  auth.villaId,
                );
                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, GuestProvider>(
              create: (_) => GuestProvider(),
              update: (_, auth, provider) {
                provider!.updateAuthorization(
                  auth.isLoggedIn && auth.isAdmin && auth.hasVilla,
                  auth.villaId,
                );
                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, VillaSettingsProvider>(
              create: (_) => VillaSettingsProvider(),
              update: (_, auth, provider) {
                provider!.updateAuthorization(
                  auth.isLoggedIn && auth.isAdmin && auth.hasVilla,
                  auth.villaId,
                );
                return provider;
              },
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'VillaGuestRD',
            theme: AppTheme.light,
            navigatorKey: navigatorKey,
            builder: (context, child) =>
                ConnectivityBanner(child: child!),
            home: const AuthGate(),
          ),
        );
      },
    );
  }
}
