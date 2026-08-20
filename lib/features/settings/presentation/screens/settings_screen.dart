import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/services/firebase_service.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:villaguest/features/auth/presentation/providers/auth_provider.dart';
import 'package:villaguest/features/settings/data/models/villa_settings_model.dart';
import 'package:villaguest/features/settings/presentation/providers/villa_settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Rellena los campos la primera vez que llegan los settings desde Firestore.
  void _initControllers(VillaSettingsModel settings) {
    if (_initialized) return;
    _initialized = true;
    _displayNameController.text = settings.displayName;
    _phoneController.text = settings.contactPhone ?? '';
    _emailController.text = settings.contactEmail ?? '';
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    await context.read<VillaSettingsProvider>().uploadLogo(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo actualizado.')),
      );
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VillaSettingsProvider>();
    final current = provider.settings;
    if (current == null) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final updated = current.copyWith(
        displayName: _displayNameController.text.trim(),
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );
      await provider.updateSettings(updated);
      messenger.showSnackBar(
        const SnackBar(content: Text('Ajustes guardados.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudieron guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = context.read<AuthProvider>().user?.email;
    if (email == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseService.instance.sendPasswordResetEmail(email);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Se envió un correo de restablecimiento a $email.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VillaSettingsProvider>();
    final settings = provider.settings;

    if (settings != null) _initControllers(settings);

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Ajustes',
        actions: [
          if (!provider.isLoading)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Guardar',
                    onPressed: _save,
                  ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildLogoHeader(context, provider, settings),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(context, 'Tu villa'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre visible',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.villa_outlined),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono de contacto',
                            hintText: '+1 809 000 0000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo de contacto',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 32),
                        _sectionLabel(context, 'Cuenta'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.lock_reset_outlined),
                            label: const Text('Cambiar contraseña'),
                            onPressed: _sendPasswordReset,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogoHeader(
    BuildContext context,
    VillaSettingsProvider provider,
    VillaSettingsModel? settings,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.teal, AppTheme.navy],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: provider.isUploadingLogo ? null : _pickLogo,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                  child: ClipOval(
                    child: provider.isUploadingLogo
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : settings?.logoUrl != null
                            ? Image.network(
                                settings!.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.villa_outlined,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.villa_outlined,
                                size: 44,
                                color: Colors.white,
                              ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.lime,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 14, color: AppTheme.navy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            settings?.displayName ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca el logo para cambiarlo',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
