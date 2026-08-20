import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
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

  static const _monthNames = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

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
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final pendingCount =
        bookingProvider.bookings.where((b) => b.status == 'pending').length;
    final activeCount = bookingProvider.activeBookings.length;

    return Scaffold(
      appBar: const GradientAppBar(title: 'VillaGuestRD'),
      drawer: _buildDrawer(context, pendingCount: pendingCount),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: BookingCalendar(
                onRangeSelected: (checkIn, checkOut) =>
                    _openCreateBookingDialog(context, checkIn, checkOut),
                onBookedDayTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookingsListScreen()),
                ),
              ),
            ),
          ),
          _buildBanner(context, pendingCount: pendingCount, activeCount: activeCount),
        ],
      ),
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required int pendingCount,
    required int activeCount,
  }) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day} de ${_monthNames[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.teal, AppTheme.navy],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.villa_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Resumen de reservas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _bannerChip(
                icon: Icons.event_available_outlined,
                label: '$activeCount activas',
              ),
              const SizedBox(width: 8),
              _bannerChip(
                icon: Icons.schedule_outlined,
                label: '$pendingCount pendientes',
                highlight: pendingCount > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerChip({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.lime.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? AppTheme.navy : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? AppTheme.navy : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, {required int pendingCount}) {
    final auth = context.read<AuthProvider>();
    final email = auth.user?.email ?? '';
    final villa = auth.villaId ?? '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.teal, AppTheme.navy],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.villa_outlined, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'VillaGuestRD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.lime.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    villa,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Dashboard'),
            onTap: () => _navigate(context, const DashboardScreen()),
          ),
          ListTile(
            leading: Badge(
              label: Text('$pendingCount'),
              isLabelVisible: pendingCount > 0,
              child: const Icon(Icons.list_alt_outlined),
            ),
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
