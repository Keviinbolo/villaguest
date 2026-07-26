import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cleaning_provider.dart';
import 'cleaning_checklist_screen.dart';

class CleaningListScreen extends StatelessWidget {
  const CleaningListScreen({super.key});

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Sin empezar';
      case 'in_progress':
        return 'En progreso';
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleaningProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checklists de limpieza')),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, CleaningProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    if (provider.checklists.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay checklists. Se crean desde el detalle de una reserva confirmada.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: provider.checklists.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final checklist = provider.checklists[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _statusColor(checklist.status).withValues(alpha: 0.15),
            child: Icon(Icons.cleaning_services, color: _statusColor(checklist.status)),
          ),
          title: Text(checklist.guestName),
          subtitle: Text(
            'Salida: ${_formatDate(checklist.checkOutDate)} · '
            '${checklist.completedTasksCount}/${checklist.totalTasks} tareas',
          ),
          trailing: Chip(
            label: Text(
              _statusLabel(checklist.status),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: _statusColor(checklist.status),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CleaningChecklistScreen(checklistId: checklist.id),
              ),
            );
          },
        );
      },
    );
  }
}