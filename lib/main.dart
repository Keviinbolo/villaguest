import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/cleaning/providers/cleaning_provider.dart';

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
      // Aquí vas a ir agregando el resto de providers a medida que los
      // crees: PaymentProvider, GuestProvider, MaintenanceProvider, etc.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, authProvider, bookingProvider) {
            // Solo se suscribe a Firestore si hay sesión Y el rol es
            // admin. Para staff (o mientras el rol todavía está
            // resolviéndose), se queda sin suscribir — nunca intenta
            // una lectura que las reglas de Firestore van a rechazar.
            bookingProvider!.updateAuthorization(
              authProvider.isLoggedIn && authProvider.isAdmin,
            );
            return bookingProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CleaningProvider>(
          create: (_) => CleaningProvider(),
          update: (_, authProvider, cleaningProvider) {
            // Admin y staff tienen permiso sobre cleaning_checklists,
            // así que aquí basta con "¿hay sesión?".
            cleaningProvider!.updateAuthorization(authProvider.isLoggedIn);
            return cleaningProvider;
          },
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VillaGuest RD',
        home: AuthGate(),
      ),
    );
  }
}