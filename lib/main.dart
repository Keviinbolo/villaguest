import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/cleaning/providers/cleaning_provider.dart';
import 'package:villaguest/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:villaguest/features/guests/presentation/providers/guest_provider.dart';

import 'firebase_options.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_gate.dart';

Future<void> main() async {
  // Necesario porque vamos a hacer trabajo async (Firebase.initializeApp)
  // antes de runApp().
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // IMPORTANTE: ningún provider que dependa de Firestore debe
      // suscribirse en su propio constructor. Todos se conectan a
      // AuthProvider vía ChangeNotifierProxyProvider y solo se
      // suscriben cuando updateAuthorization(true) se los confirma.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, authProvider, bookingProvider) {
            // Solo admin tiene permiso sobre bookings.
            bookingProvider!.updateAuthorization(
              authProvider.isLoggedIn && authProvider.isAdmin,
            );
            return bookingProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CleaningProvider>(
          create: (_) => CleaningProvider(),
          update: (_, authProvider, cleaningProvider) {
            // Admin y staff tienen permiso sobre cleaning_checklists.
            cleaningProvider!.updateAuthorization(authProvider.isLoggedIn);
            return cleaningProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, MaintenanceProvider>(
          create: (_) => MaintenanceProvider(),
          update: (_, authProvider, maintenanceProvider) {
            // Admin y staff tienen permiso sobre maintenance_tickets.
            maintenanceProvider!.updateAuthorization(authProvider.isLoggedIn);
            return maintenanceProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, GuestProvider>(
          create: (_) => GuestProvider(),
          update: (_, authProvider, guestProvider) {
            // Solo admin: guests depende de bookings, que también es
            // admin-only.
            guestProvider!.updateAuthorization(
              authProvider.isLoggedIn && authProvider.isAdmin,
            );
            return guestProvider;
          },
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VillaGuestRD',
        home: AuthGate(),
      ),
    );
  }
}