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
import '../../../settings/presentation/providers/villa_settings_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

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
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().signOut();
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final pendingCount =
        bookingProvider.bookings.where((b) => b.status == 'pending').length;
    final activeCount = bookingProvider.activeBookings.length;
    final logoUrl =
        context.watch<VillaSettingsProvider>().settings?.logoUrl;

    return Scaffold(
      appBar: const GradientAppBar(title: 'VillaGuestRD'),
      drawer: _buildDrawer(context,
          pendingCount: pendingCount, logoUrl: logoUrl),
      body: Column(
        children: [
          _buildStatsBar(context,
              pendingCount: pendingCount, activeCount: activeCount),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: BookingCalendar(
                onRangeSelected: (checkIn, checkOut) =>
                    _openCreateBookingDialog(context, checkIn, checkOut),
                onBookedDayTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const BookingsListScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats bar ──────────────────────────────────────────────────────────
  Widget _buildStatsBar(
    BuildContext context, {
    required int pendingCount,
    required int activeCount,
  }) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day} de ${_monthNames[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Color(0xFF6B7A99)),
              const SizedBox(width: 5),
              Text(
                dateLabel,
                style: const TextStyle(
                    color: Color(0xFF6B7A99), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.event_available_outlined,
                  value: '$activeCount',
                  label: 'Reservas activas',
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.schedule_outlined,
                  value: '$pendingCount',
                  label: 'Pendientes',
                  color: pendingCount > 0
                      ? const Color(0xFFE07B00)
                      : const Color(0xFF6B7A99),
                  highlighted: pendingCount > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────
  Widget _buildDrawer(
    BuildContext context, {
    required int pendingCount,
    String? logoUrl,
  }) {
    final auth = context.read<AuthProvider>();
    final email = auth.user?.email ?? '';
    final villa = auth.villaId ?? '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            height: 172,
            color: AppTheme.navy,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: ClipOval(
                    child: logoUrl != null
                        ? Image.network(logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                                'assets/icon/icon.png',
                                fit: BoxFit.cover))
                        : Image.asset('assets/icon/icon.png',
                            fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'VillaGuestRD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.lime,
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

          // ── Items ──────────────────────────────────────────────────────
          _DrawerItem(
            icon: Icons.bar_chart_outlined,
            label: 'Dashboard',
            onTap: () => _navigate(context, const DashboardScreen()),
          ),
          _DrawerItem(
            icon: Icons.list_alt_outlined,
            label: 'Reservas',
            badge: pendingCount > 0 ? pendingCount : null,
            onTap: () => _navigate(context, const BookingsListScreen()),
          ),
          _DrawerItem(
            icon: Icons.people_outline,
            label: 'Huéspedes',
            onTap: () => _navigate(context, const GuestListScreen()),
          ),
          _DrawerItem(
            icon: Icons.cleaning_services_outlined,
            label: 'Limpieza',
            onTap: () => _navigate(context, const CleaningListScreen()),
          ),
          _DrawerItem(
            icon: Icons.build_outlined,
            label: 'Mantenimiento',
            onTap: () =>
                _navigate(context, const MaintenanceListScreen()),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),

          _DrawerItem(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            onTap: () => _navigate(context, const SettingsScreen()),
          ),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            isDestructive: true,
            onTap: () => _confirmSignOut(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.highlighted = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlighted ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: highlighted ? 0.30 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7A99),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Badge(
        isLabelVisible: badge != null && badge! > 0,
        label: Text('$badge'),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}
