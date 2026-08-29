import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:villaguest/core/utils/date_utils.dart';

import '../providers/cleaning_provider.dart';
import '../data/cleaning_checklist_model.dart';
import 'cleaning_checklist_screen.dart';

class CleaningListScreen extends StatelessWidget {
  const CleaningListScreen({super.key});

  static Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return AppTheme.lime;
      case 'completed':   return AppTheme.teal;
      default:            return const Color(0xFF6B7A99);
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending':     return 'Sin empezar';
      case 'in_progress': return 'En progreso';
      case 'completed':   return 'Completado';
      default:            return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleaningProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surfacePage,
      appBar: const GradientAppBar(title: 'Limpieza'),
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
      return _emptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: provider.checklists.length,
      itemBuilder: (context, index) => _CleaningCard(
        checklist: provider.checklists[index],
        statusColor: _statusColor(provider.checklists[index].status),
        statusLabel: _statusLabel(provider.checklists[index].status),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CleaningChecklistScreen(checklistId: provider.checklists[index].id),
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
                color: AppTheme.sage.withValues(alpha: 0.30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cleaning_services_outlined,
                  size: 32, color: AppTheme.teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin checklists',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Se crean desde el detalle de una reserva confirmada.',
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

class _CleaningCard extends StatelessWidget {
  const _CleaningCard({
    required this.checklist,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  final CleaningChecklistModel checklist;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = checklist.totalTasks > 0
        ? checklist.completedTasksCount / checklist.totalTasks
        : 0.0;

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
              // Icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.28),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.cleaning_services_outlined,
                    color: statusColor, size: 20),
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
                            checklist.guestName,
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
                          'Salida: ${formatDate(checklist.checkOutDate)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7A99)),
                        ),
                      ],
                    ),
                    if (checklist.totalTasks > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor:
                                    statusColor.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${checklist.completedTasksCount}/${checklist.totalTasks}',
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
