import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

import '../../data/models/booking_model.dart';

/// Diálogo para editar una reserva existente.
/// Permite cambiar datos del huésped, fechas y precios.
/// Las fechas se seleccionan con el date picker nativo.
class EditBookingDialog extends StatefulWidget {
  const EditBookingDialog({super.key, required this.booking});

  final BookingModel booking;

  @override
  State<EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends State<EditBookingDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _depositController;

  late DateTime _checkIn;
  late DateTime _checkOut;

  bool _isSubmitting = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _checkIn = widget.booking.checkIn;
    _checkOut = widget.booking.checkOut;
    _nameController = TextEditingController(text: widget.booking.guestName);
    _emailController = TextEditingController(text: widget.booking.guestEmail);
    _phoneController = TextEditingController(text: widget.booking.guestPhone);
    _totalPriceController = TextEditingController(
      text: widget.booking.totalPrice.toStringAsFixed(2),
    );
    _depositController = TextEditingController(
      text: widget.booking.depositPaid.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _totalPriceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;

  Future<void> _pickCheckIn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar Check-in',
    );
    if (picked == null) return;

    setState(() {
      _checkIn = picked;
      // Si el nuevo check-in es igual o posterior al check-out, lo ajustamos.
      if (!_checkOut.isAfter(_checkIn)) {
        _checkOut = _checkIn.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickCheckOut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOut.isAfter(_checkIn) ? _checkOut : _checkIn.add(const Duration(days: 1)),
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar Check-out',
    );
    if (picked == null) return;
    setState(() => _checkOut = picked);
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Número inválido';
    if (parsed < 0) return 'Debe ser positivo';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final totalPrice = double.parse(_totalPriceController.text.trim());
    final depositPaid = double.parse(_depositController.text.trim());

    if (depositPaid > totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La señal no puede ser mayor al precio total.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final updated = widget.booking.copyWith(
      guestName: _nameController.text.trim(),
      guestEmail: _emailController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      checkIn: _checkIn,
      checkOut: _checkOut,
      totalPrice: totalPrice,
      depositPaid: depositPaid,
    );

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<BookingProvider>();

    try {
      await provider.updateBooking(updated);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Reserva actualizada.')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Editar reserva'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Selector de fechas ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Check-in',
                      date: _checkIn,
                      onTap: _isSubmitting ? null : _pickCheckIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateButton(
                      label: 'Check-out',
                      date: _checkOut,
                      onTap: _isSubmitting ? null : _pickCheckOut,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '$_nights ${_nights == 1 ? 'noche' : 'noches'}',
                  style: TextStyle(color: colorScheme.primary, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),

              // ── Datos del huésped ───────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del huésped'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
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
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // ── Precios ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalPriceController,
                      decoration: const InputDecoration(labelText: 'Precio total (RD\$)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatePositiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depositController,
                      decoration: const InputDecoration(labelText: 'Señal (RD\$)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatePositiveNumber,
                    ),
                  ),
                ],
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
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }
}

/// Botón que muestra una fecha formateada y abre el date picker al tocarlo.
class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(formatDate(date)),
      ),
    );
  }
}
