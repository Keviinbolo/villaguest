import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/maintenance/data/models/maintenance_ticket_model.dart';
import 'package:villaguest/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:villaguest/features/maintenance/presentation/screens/maintenance_ticket_detail_screen.dart';
import 'package:villaguest/features/maintenance/presentation/widgets/create_ticket_dialog.dart';

class MaintenanceListScreen extends StatelessWidget {
  const MaintenanceListScreen({super.key});

  static Color statusColor(String status) {
    switch (status) {
      case 'open':        return const Color(0xFFE07B00);
      case 'in_progress': return AppTheme.lime;
      case 'resolved':    return AppTheme.teal;
      default:            return const Color(0xFF6B7A99);
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'open':        return 'Abierta';
      case 'in_progress': return 'En progreso';
      case 'resolved':    return 'Resuelta';
      default:            return status;
    }
  }

  static Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':   return const Color(0xFFE07B00);
      case 'medium': return AppTheme.lime;
      default:       return const Color(0xFF6B7A99);
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'high':   return 'Alta';
      case 'medium': return 'Media';
      case 'low':    return 'Baja';
      default:       return priority;
    }
  }

  static IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'high': return Icons.priority_high_rounded;
      case 'low':  return Icons.low_priority_rounded;
      default:     return Icons.build_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaintenanceProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surfacePage,
      appBar: const GradientAppBar(title: 'Mantenimiento'),
      body: _buildBody(context, provider),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Reportar avería',
        backgroundColor: AppTheme.teal,
        foregroundColor: Colors.white,
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
      return _emptyState();
    }

    final tickets = [...provider.tickets]..sort((a, b) {
        final aResolved = a.status == 'resolved' ? 1 : 0;
        final bResolved = b.status == 'resolved' ? 1 : 0;
        if (aResolved != bResolved) return aResolved - bResolved;
        return b.createdAt.compareTo(a.createdAt);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: tickets.length,
      itemBuilder: (context, index) => _TicketCard(
        ticket: tickets[index],
        statusColor: statusColor(tickets[index].status),
        statusLabel: statusLabel(tickets[index].status),
        priorityColor: _priorityColor(tickets[index].priority),
        priorityLabel: priorityLabel(tickets[index].priority),
        priorityIcon: _priorityIcon(tickets[index].priority),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                MaintenanceTicketDetailScreen(ticketId: tickets[index].id),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_outlined, size: 32, color: AppTheme.navy),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin averías reportadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toca "+" para reportar una incidencia.',
              style: TextStyle(color: Color(0xFF6B7A99), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.statusColor,
    required this.statusLabel,
    required this.priorityColor,
    required this.priorityLabel,
    required this.priorityIcon,
    required this.onTap,
  });

  final MaintenanceTicketModel ticket;
  final Color statusColor;
  final String statusLabel;
  final Color priorityColor;
  final String priorityLabel;
  final IconData priorityIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Priority bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.28),
                    width: 1.5,
                  ),
                ),
                child: Icon(priorityIcon, color: priorityColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Badge(label: statusLabel, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Color(0xFF6B7A99)),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(ticket.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7A99)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: priorityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ticket.reportedBy.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Reportado por ${ticket.reportedBy}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7A99)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFBBC3D8), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
