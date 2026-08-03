import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/cleaning/presentation/cleaning_list_screen.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../maintenance/presentation/screens/maintenance_list_screen.dart';

/// Pantalla principal para cuentas de equipo (limpieza/mantenimiento).
/// Acceso limitado a propósito: solo checklists y averías, nada de
/// calendario, reservas, ni datos de pago.
class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VillaGest RD — Equipo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().signOut(),
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