import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';

/// Diálogo para reportar una nueva avería. Disponible tanto para admin
/// como para staff — cualquiera puede reportar un problema que
/// encuentre.
class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _priority = 'medium';
  XFile? _photo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file != null) setState(() => _photo = file);
  }

  void _showPhotoSourceSheet() {
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
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final maintenanceProvider = context.read<MaintenanceProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      Uint8List? photoBytes;
      if (_photo != null) {
        photoBytes = await _photo!.readAsBytes();
      }

      await maintenanceProvider.createTicket(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        reportedBy: authProvider.user?.email ?? 'Desconocido',
        photoBytes: photoBytes,
      );

      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Avería reportada.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo reportar: $e')));
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reportar avería'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título breve'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Baja')),
                  DropdownMenuItem(value: 'medium', child: Text('Media')),
                  DropdownMenuItem(value: 'high', child: Text('Alta')),
                ],
                onChanged: (value) => setState(() => _priority = value ?? 'medium'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: Icon(_photo == null ? Icons.add_a_photo_outlined : Icons.check),
                label: Text(_photo == null ? 'Adjuntar foto (opcional)' : 'Foto adjuntada'),
                onPressed: _showPhotoSourceSheet,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reportar'),
        ),
      ],
    );
  }
}