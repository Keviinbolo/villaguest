import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/cleaning/presentation/cleaning_list_screen.dart';

import '../../../auth/presentation/providers/auth_provider.dart';


/// Pantalla principal para cuentas de equipo (limpieza/mantenimiento).
/// A propósito NO tiene acceso al calendario, creación de reservas, ni
/// datos de pago — solo a las tareas operativas que le corresponden.
/// Cuando construyamos "Registro de averías", su tarjeta va aquí.
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
          // Próximamente: tarjeta de "Registro de averías / mantenimiento".
        ],
      ),
    );
  }
}