import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:villaguest/features/maintenance/presentation/screens/maintenance_ticket_detail_screen.dart';
import 'package:villaguest/features/maintenance/presentation/widgets/create_ticket_dialog.dart';



class MaintenanceListScreen extends StatelessWidget {
  const MaintenanceListScreen({super.key});

  static Color statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Abierta';
      case 'in_progress':
        return 'En progreso';
      case 'resolved':
        return 'Resuelta';
      default:
        return status;
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return priority;
    }
  }

  static IconData priorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.build_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaintenanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Averías y mantenimiento')),
      body: _buildBody(context, provider),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Reportar avería',
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const CreateTicketDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MaintenanceProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    if (provider.tickets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay averías reportadas. Toca "+" para reportar una.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Abiertas y en progreso primero (más recientes arriba), resueltas
    // al final.
    final tickets = [...provider.tickets]..sort((a, b) {
        final aResolved = a.status == 'resolved' ? 1 : 0;
        final bResolved = b.status == 'resolved' ? 1 : 0;
        if (aResolved != bResolved) return aResolved - bResolved;
        return b.createdAt.compareTo(a.createdAt);
      });

    return ListView.separated(
      itemCount: tickets.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor(ticket.status).withValues(alpha: 0.15),
            child: Icon(priorityIcon(ticket.priority), color: statusColor(ticket.status)),
          ),
          title: Text(ticket.title),
          subtitle: Text(
            '${formatDate(ticket.createdAt)} · Prioridad ${priorityLabel(ticket.priority)}',
          ),
          trailing: Chip(
            label: Text(
              statusLabel(ticket.status),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: statusColor(ticket.status),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MaintenanceTicketDetailScreen(ticketId: ticket.id),
              ),
            );
          },
        );
      },
    );
  }
}