import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/screen/bookings_list_screen.dart';
import 'package:villaguest/features/cleaning/presentation/cleaning_list_screen.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../bookings/presentation/widgets/create_booking_dialog.dart';
import '../../../calendar/presentation/widgets/booking_calendar.dart';


/// Pantalla principal tras iniciar sesión. Temporal como Dashboard real
/// (la reemplazaremos más adelante), pero ya funcional: calendario,
/// creación de reservas, acceso a la lista y cerrar sesión.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCreateBookingDialog(
    BuildContext context,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    showDialog(
      context: context,
      builder: (_) => CreateBookingDialog(checkIn: checkIn, checkOut: checkOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VillaGest RD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Ver reservas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookingsListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Checklists de limpieza',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CleaningListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BookingCalendar(
          onRangeSelected: (checkIn, checkOut) =>
              _openCreateBookingDialog(context, checkIn, checkOut),
        ),
      ),
    );
  }
}