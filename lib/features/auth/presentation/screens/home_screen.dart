import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/screen/bookings_list_screen.dart';
import 'package:villaguest/features/cleaning/presentation/cleaning_list_screen.dart';
import 'package:villaguest/features/dashboard/presentation/screen/dashboard_screen.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/widgets/create_booking_dialog.dart';
import '../../../calendar/presentation/widgets/booking_calendar.dart';
import '../../../guests/presentation/screens/guest_list_screen.dart';
import '../../../maintenance/presentation/screens/maintenance_list_screen.dart';

/// Pantalla principal tras iniciar sesión como admin.
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

  Future<void> _confirmSignOut(BuildContext context) async {
    // Cerramos el drawer antes de mostrar el diálogo.
    Navigator.of(context).pop();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().signOut();
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // cierra el drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VillaGuestRD')),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BookingCalendar(
          onRangeSelected: (checkIn, checkOut) =>
              _openCreateBookingDialog(context, checkIn, checkOut),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.villa_outlined, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text(
                  'VillaGuestRD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.read<AuthProvider>().user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Dashboard'),
            onTap: () => _navigate(context, const DashboardScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('Reservas'),
            onTap: () => _navigate(context, const BookingsListScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Huéspedes'),
            onTap: () => _navigate(context, const GuestListScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Limpieza'),
            onTap: () => _navigate(context, const CleaningListScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('Mantenimiento'),
            onTap: () => _navigate(context, const MaintenanceListScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}
