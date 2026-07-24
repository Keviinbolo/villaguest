import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

import 'firebase_options.dart';

import 'features/calendar/presentation/widgets/booking_calendar.dart';

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
      providers: [ChangeNotifierProvider(create: (_) => BookingProvider())],
      child: const MaterialApp(home: HomeScreen()),
    );
  }
}

/// Pantalla temporal solo para verificar que el calendario pinta bien
/// con datos reales de Firestore. La reemplazaremos por tu Dashboard real más adelante.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VillaGest RD')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: BookingCalendar(),
      ),
    );
  }
}
