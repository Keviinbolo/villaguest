import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/settings/presentation/providers/villa_settings_provider.dart';

import '../../data/models/booking_model.dart';

/// Diálogo para crear una reserva a partir de un rango de fechas ya
/// seleccionado en el calendario.
class CreateBookingDialog extends StatefulWidget {
  const CreateBookingDialog({
    super.key,
    required this.checkIn,
    required this.checkOut,
  });

  final DateTime checkIn;
  final DateTime checkOut;

  @override
  State<CreateBookingDialog> createState() => _CreateBookingDialogState();
}

class _CreateBookingDialogState extends State<CreateBookingDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _depositController = TextEditingController();

  bool _isSubmitting = false;
  bool _priceInitialized = false;
  double? _pricePerNight;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied')) {
      return 'Sin permisos para crear reservas. Contacta al administrador.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    if (msg.contains('ya no están disponibles') ||
        msg.contains('disponibles')) {
      return 'Las fechas seleccionadas ya están ocupadas por otra reserva.';
    }
    return 'No se pudo crear la reserva. Intenta de nuevo.';
  }

  int get _nights => widget.checkOut.difference(widget.checkIn).inDays;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _totalPriceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Número inválido';
    if (parsed < 0) return 'Debe ser positivo';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final totalPrice = double.parse(_totalPriceController.text.trim());
    final depositPaid = double.parse(_depositController.text.trim());

    if (depositPaid > totalPrice) {
      setState(() =>
          _errorMessage = 'La señal no puede superar el precio total (RD\$ ${totalPrice.toStringAsFixed(0)}).');
      return;
    }

    setState(() => _isSubmitting = true);

    final booking = BookingModel(
      id: '',
      guestName: _nameController.text.trim(),
      guestEmail: _emailController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      totalPrice: totalPrice,
      depositPaid: depositPaid,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bookingProvider = context.read<BookingProvider>();

    try {
      await bookingProvider.createBooking(booking);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Reserva creada para ${booking.guestName}.')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-rellena el precio total con pricePerNight × noches en el primer build.
    if (!_priceInitialized) {
      _priceInitialized = true;
      _pricePerNight =
          context.read<VillaSettingsProvider>().settings?.pricePerNight;
      if (_pricePerNight != null && _pricePerNight! > 0) {
        _totalPriceController.text =
            (_pricePerNight! * _nights).toStringAsFixed(0);
      }
    }

    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Nueva reserva'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Rango de fechas ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range_outlined,
                        size: 16, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${formatDate(widget.checkIn)} → ${formatDate(widget.checkOut)}'
                        '  ·  $_nights ${_nights == 1 ? 'noche' : 'noches'}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Datos del huésped ───────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del huésped',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!_emailRegex.hasMatch(v.trim())) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (WhatsApp)',
                  hintText: '+1 809 000 0000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // ── Precio ──────────────────────────────────────────────
              TextFormField(
                controller: _totalPriceController,
                decoration: InputDecoration(
                  labelText: 'Precio total (RD\$)',
                  border: const OutlineInputBorder(),
                  helperText: _pricePerNight != null && _pricePerNight! > 0
                      ? 'RD\$ ${_pricePerNight!.toStringAsFixed(0)}/noche × $_nights noches'
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validatePositiveNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _depositController,
                decoration: const InputDecoration(
                  labelText: 'Señal / depósito (RD\$)',
                  border: OutlineInputBorder(),
                  helperText: 'Puede ser 0 si no se cobra señal',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validatePositiveNumber,
              ),

              // ── Error inline ─────────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              : const Text('Crear reserva'),
        ),
      ],
    );
  }
}
