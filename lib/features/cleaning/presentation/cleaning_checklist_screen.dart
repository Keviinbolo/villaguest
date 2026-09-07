import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/cleaning/data/cleaning_checklist_model.dart';
import 'package:villaguest/features/cleaning/data/cleaning_task_model.dart';

import '../providers/cleaning_provider.dart';

class CleaningChecklistScreen extends StatefulWidget {
  const CleaningChecklistScreen({super.key, required this.checklistId});

  final String checklistId;

  @override
  State<CleaningChecklistScreen> createState() => _CleaningChecklistScreenState();
}

class _CleaningChecklistScreenState extends State<CleaningChecklistScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _uploadingTaskId;

  Future<void> _pickAndUploadPhoto(
    CleaningProvider provider,
    String taskId,
    ImageSource source,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;
      setState(() => _uploadingTaskId = taskId);
      final bytes = await file.readAsBytes();
      await provider.completeTaskWithPhoto(
        checklistId: widget.checklistId,
        taskId: taskId,
        photoBytes: bytes,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo subir la foto: $e')));
    } finally {
      if (mounted) setState(() => _uploadingTaskId = null);
    }
  }

  void _showPhotoSourceSheet(CleaningProvider provider, String taskId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadPhoto(provider, taskId, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadPhoto(provider, taskId, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF6B7A99)),
              title: const Text('Marcar sin foto'),
              subtitle: const Text('Solo si no es posible tomar una'),
              onTap: () {
                Navigator.of(ctx).pop();
                provider.completeTaskWithoutPhoto(
                  checklistId: widget.checklistId,
                  taskId: taskId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markChecklistCompleted(CleaningProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.markChecklistCompleted(widget.checklistId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Checklist marcado como completado.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo completar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleaningProvider>();

    CleaningChecklistModel? checklist;
    for (final c in provider.checklists) {
      if (c.id == widget.checklistId) {
        checklist = c;
        break;
      }
    }

    if (checklist == null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Checklist'),
        body: const Center(child: Text('Este checklist ya no existe.')),
      );
    }

    final tasks = checklist.orderedTasks;
    final isCompleted = checklist.status == 'completed';

    return Scaffold(
      backgroundColor: AppTheme.surfacePage,
      appBar: GradientAppBar(title: 'Limpieza — ${checklist.guestName}'),
      body: Column(
        children: [
          _ProgressHeader(checklist: checklist),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: tasks.length,
              itemBuilder: (context, index) =>
                  _TaskCard(
                    task: tasks[index],
                    isUploading: _uploadingTaskId == tasks[index].id,
                    onUpload: () => _showPhotoSourceSheet(provider, tasks[index].id),
                    onReset: () => provider.resetTask(
                      checklistId: widget.checklistId,
                      taskId: tasks[index].id,
                    ),
                  ),
            ),
          ),
          if (!isCompleted)
            _CompleteButton(
              checklist: checklist,
              onComplete: () => _markChecklistCompleted(provider),
            ),
        ],
      ),
    );
  }
}

// ── Progress header ───────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.checklist});
  final CleaningChecklistModel checklist;

  @override
  Widget build(BuildContext context) {
    final progress = checklist.totalTasks == 0
        ? 0.0
        : checklist.completedTasksCount / checklist.totalTasks;
    final color = checklist.status == 'completed'
        ? AppTheme.teal
        : checklist.completedTasksCount > 0
            ? AppTheme.lime
            : const Color(0xFF6B7A99);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: const Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${checklist.completedTasksCount} de ${checklist.totalTasks} tareas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isUploading,
    required this.onUpload,
    required this.onReset,
  });

  final CleaningTaskModel task;
  final bool isUploading;
  final VoidCallback onUpload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    final color = done ? AppTheme.teal : const Color(0xFF6B7A99);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Foto / ícono ─────────────────────────────────────────
            if (done && task.photoUrl != null)
              GestureDetector(
                onTap: () => _showFullPhoto(context, task.photoUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    task.photoUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.28),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_circle_outline : Icons.camera_alt_outlined,
                  color: color,
                  size: 22,
                ),
              ),
            const SizedBox(width: 12),

            // ── Título + estado ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: done ? AppTheme.navy : const Color(0xFF3D4A5C),
                      decoration: done ? TextDecoration.none : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.30)),
                        ),
                        child: Text(
                          done ? 'Completada' : 'Pendiente de foto',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Acción ──────────────────────────────────────────────
            if (isUploading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (done)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Rehacer',
                color: const Color(0xFF6B7A99),
                onPressed: onReset,
              )
            else
              IconButton(
                icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                tooltip: 'Subir foto',
                color: AppTheme.teal,
                onPressed: onUpload,
              ),
          ],
        ),
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ── Complete button ───────────────────────────────────────────────────────────

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.checklist, required this.onComplete});
  final CleaningChecklistModel checklist;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final ready = checklist.isFullyComplete;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: FilledButton.icon(
        icon: Icon(ready ? Icons.check_circle_outline : Icons.lock_outline, size: 18),
        label: Text(
          ready
              ? 'Marcar checklist como completado'
              : 'Faltan ${checklist.totalTasks - checklist.completedTasksCount} tareas con foto',
        ),
        onPressed: ready ? onComplete : null,
      ),
    );
  }
}
