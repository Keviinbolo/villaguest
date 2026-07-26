import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/cleaning/data/cleaning_checklist_model.dart';
import 'package:villaguest/features/cleaning/data/cleaning_task_model.dart';


import '../providers/cleaning_provider.dart';

/// Detalle de un checklist: una tarea por fila, cada una requiere una
/// foto para poder marcarse como completada. Se suscribe al
/// CleaningProvider en vivo (igual que BookingDetailScreen) para que la
/// pantalla se actualice sola cuando sube una foto.
class CleaningChecklistScreen extends StatefulWidget {
  const CleaningChecklistScreen({super.key, required this.checklistId});

  final String checklistId;

  @override
  State<CleaningChecklistScreen> createState() => _CleaningChecklistScreenState();
}

class _CleaningChecklistScreenState extends State<CleaningChecklistScreen> {
  final ImagePicker _picker = ImagePicker();

  /// taskId de la tarea que está subiendo foto en este momento (para
  /// mostrar un loader solo en esa fila, no en toda la pantalla).
  String? _uploadingTaskId;

  Future<void> _pickAndUploadPhoto(
    CleaningProvider provider,
    String taskId,
    ImageSource source,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return; // el usuario canceló

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
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndUploadPhoto(provider, taskId, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndUploadPhoto(provider, taskId, ImageSource.gallery);
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
        appBar: AppBar(title: const Text('Checklist')),
        body: const Center(child: Text('Este checklist ya no existe.')),
      );
    }

    final tasks = checklist.orderedTasks;

    return Scaffold(
      appBar: AppBar(title: Text('Limpieza — ${checklist.guestName}')),
      body: Column(
        children: [
          _buildProgressHeader(checklist),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _buildTaskTile(provider, tasks[index]),
            ),
          ),
          if (checklist.status != 'completed')
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: checklist.isFullyComplete
                      ? () => _markChecklistCompleted(provider)
                      : null,
                  child: Text(
                    checklist.isFullyComplete
                        ? 'Marcar checklist como completado'
                        : 'Faltan ${checklist.totalTasks - checklist.completedTasksCount} tareas con foto',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(CleaningChecklistModel checklist) {
    final progress =
        checklist.totalTasks == 0 ? 0.0 : checklist.completedTasksCount / checklist.totalTasks;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${checklist.completedTasksCount} de ${checklist.totalTasks} tareas'),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(CleaningProvider provider, CleaningTaskModel task) {
    final isUploading = _uploadingTaskId == task.id;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: task.isCompleted && task.photoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  task.photoUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
              ),
        title: Text(task.title),
        subtitle: task.isCompleted
            ? const Text('Completada', style: TextStyle(color: Colors.green))
            : const Text('Pendiente de foto'),
        trailing: isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : task.isCompleted
                ? IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Rehacer',
                    onPressed: () => provider.resetTask(
                      checklistId: widget.checklistId,
                      taskId: task.id,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    tooltip: 'Subir foto',
                    onPressed: () => _showPhotoSourceSheet(provider, task.id),
                  ),
      ),
    );
  }
}