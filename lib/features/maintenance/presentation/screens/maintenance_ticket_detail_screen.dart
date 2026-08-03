import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/maintenance_ticket_model.dart';
import '../providers/maintenance_provider.dart';
import 'maintenance_list_screen.dart' show MaintenanceListScreen;

/// Detalle de un ticket, con acciones para mover su estado. Se
/// suscribe en vivo al provider (mismo patrón que BookingDetailScreen)
/// para no tener que salir y volver a entrar tras cada cambio.
class MaintenanceTicketDetailScreen extends StatelessWidget {
  const MaintenanceTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  String _formatDateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $hh:$mm';
  }

  Future<void> _updateStatus(
    BuildContext context,
    MaintenanceProvider provider,
    String newStatus,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.updateStatus(ticketId: ticketId, newStatus: newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Avería actualizada a "${MaintenanceListScreen.statusLabel(newStatus)}".',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MaintenanceProvider provider,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar avería'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.deleteTicket(ticketId);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Avería eliminada.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaintenanceProvider>();
    final authProvider = context.watch<AuthProvider>();

    MaintenanceTicketModel? matchingTicket;
    for (final t in provider.tickets) {
      if (t.id == ticketId) {
        matchingTicket = t;
        break;
      }
    }

    if (matchingTicket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Avería')),
        body: const Center(child: Text('Esta avería ya no existe.')),
      );
    }

    // Variable `final` no-nula, a propósito: la promoción de tipo de
    // `matchingTicket` (declarada en un for) no sobrevive dentro de los
    // closures de los botones de más abajo. Mismo bug que ya arreglamos
    // en BookingDetailScreen.
    final ticket = matchingTicket;

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.title),
        actions: [
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _confirmDelete(context, provider),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ticket.photoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ticket.photoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(
                  MaintenanceListScreen.statusLabel(ticket.status),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: MaintenanceListScreen.statusColor(ticket.status),
              ),
              Chip(
                label: Text(
                  'Prioridad ${MaintenanceListScreen.priorityLabel(ticket.priority)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Descripción', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(ticket.description),
          const SizedBox(height: 16),
          Text('Reportado por', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(ticket.reportedBy),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(ticket.createdAt),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ..._buildActions(context, provider, ticket),
        ],
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    MaintenanceProvider provider,
    MaintenanceTicketModel ticket,
  ) {
    switch (ticket.status) {
      case 'open':
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _updateStatus(context, provider, 'in_progress'),
              child: const Text('Marcar en progreso'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _updateStatus(context, provider, 'resolved'),
              child: const Text('Marcar resuelta'),
            ),
          ),
        ];
      case 'in_progress':
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _updateStatus(context, provider, 'resolved'),
              child: const Text('Marcar resuelta'),
            ),
          ),
        ];
      case 'resolved':
        return [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _updateStatus(context, provider, 'open'),
              child: const Text('Reabrir'),
            ),
          ),
        ];
      default:
        return [];
    }
  }
}