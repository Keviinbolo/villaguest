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
  final _priceController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initControllers(VillaSettingsModel settings) {
    if (_initialized) return;
    _initialized = true;
    _displayNameController.text = settings.displayName;
    _phoneController.text = settings.contactPhone ?? '';
    _emailController.text = settings.contactEmail ?? '';
    _priceController.text = settings.pricePerNight != null
        ? settings.pricePerNight!.toStringAsFixed(0)
        : '';
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Logo actualizado.')));
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
      final updated = VillaSettingsModel(
        villaId: current.villaId,
        displayName: _displayNameController.text.trim(),
        logoUrl: current.logoUrl,
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        pricePerNight: double.tryParse(_priceController.text.trim()),
      );
      await provider.updateSettings(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Ajustes guardados.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudieron guardar: $e')));
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
        SnackBar(content: Text('Correo enviado a $email.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VillaSettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final settings = provider.settings;

    if (settings != null) _initControllers(settings);

    return Scaffold(
      backgroundColor: AppTheme.surfacePage,
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
                          strokeWidth: 2, color: Colors.white),
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
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // ── Hero: logo + nombre de villa ────────────────────────
                  _buildHeroHeader(provider, settings),
                  const SizedBox(height: 20),

                  // ── Tu villa ────────────────────────────────────────────
                  _buildSectionCard(
                    label: 'Tu villa',
                    children: [
                      _field(
                        controller: _displayNameController,
                        label: 'Nombre visible',
                        icon: Icons.villa_outlined,
                        capitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _phoneController,
                        label: 'Teléfono de contacto',
                        hint: '+1 809 000 0000',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _emailController,
                        label: 'Correo de contacto',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),

                  // ── Precios ─────────────────────────────────────────────
                  _buildSectionCard(
                    label: 'Precios',
                    children: [
                      _field(
                        controller: _priceController,
                        label: 'Precio por noche (RD\$)',
                        hint: 'Ej. 5000',
                        icon: Icons.nights_stay_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (double.tryParse(v.trim()) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  // ── Cuenta ──────────────────────────────────────────────
                  _buildSectionCard(
                    label: 'Cuenta',
                    children: [
                      // Email info row (read-only)
                      _infoRow(
                        icon: Icons.account_circle_outlined,
                        label: 'Usuario',
                        value: auth.user?.email ?? '—',
                      ),
                      const Divider(height: 20),
                      _infoRow(
                        icon: Icons.villa_outlined,
                        label: 'Villa',
                        value: auth.villaId ?? '—',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.lock_reset_outlined),
                          label: const Text('Cambiar contraseña'),
                          onPressed: _sendPasswordReset,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // ── Hero header ──────────────────────────────────────────────────────────

  Widget _buildHeroHeader(
      VillaSettingsProvider provider, VillaSettingsModel? settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.navy, AppTheme.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lime.withValues(alpha: 0.10),
              ),
            ),
          ),

          Column(
            children: [
              // Logo
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
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2),
                      ),
                      child: ClipOval(
                        child: provider.isUploadingLogo
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              )
                            : settings?.logoUrl != null
                                ? Image.network(
                                    settings!.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Image.asset(
                                      'assets/icon/icon.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset('assets/icon/icon.png',
                                    fit: BoxFit.cover),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.lime,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: AppTheme.navy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                settings?.displayName ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Toca el logo para cambiarlo',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section card ─────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String label,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.teal,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // ── Field helper ─────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      validator: validator,
    );
  }

  // ── Info row (read-only) ─────────────────────────────────────────────────

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7A99)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A99)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
      ],
    );
  }
}
