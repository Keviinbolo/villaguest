import 'package:flutter/material.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/cleaning/presentation/cleaning_list_screen.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../maintenance/presentation/screens/maintenance_list_screen.dart';

/// Pantalla principal para cuentas de equipo (limpieza/mantenimiento).
/// Acceso limitado a propósito: solo checklists y averías, nada de
/// calendario, reservas, ni datos de pago.
class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final villa = context.read<AuthProvider>().villaId ?? 'Equipo';
    return Scaffold(
      appBar: GradientAppBar(
        title: 'VillaGuestRD — $villa',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Checklists de limpieza'),
              subtitle: const Text('Ver tareas pendientes y subir fotos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CleaningListScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.build_outlined),
              title: const Text('Averías y mantenimiento'),
              subtitle: const Text('Reportar problemas y ver el estado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MaintenanceListScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}