import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

import '../../data/models/booking_model.dart';


/// Diálogo para crear una reserva a partir de un rango de fechas ya
/// seleccionado en el calendario. Pide los datos del huésped y el
/// desglose de precio, valida, y llama a BookingProvider.createBooking().
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

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
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

    final booking = BookingModel(
      id: '', // el repositorio genera el ID real antes de escribir en Firestore
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

    // IMPORTANTE: capturamos Navigator, ScaffoldMessenger y el provider
    // ANTES del await. Si los pedimos DESPUÉS del await (como estaba
    // antes), el BuildContext puede haber quedado obsoleto —por
    // ejemplo porque BookingProvider notificó un cambio del stream de
    // Firestore mientras esperábamos y algo por encima se reconstruyó—
    // y Navigator.of(context).pop() deja de funcionar en silencio: la
    // reserva SÍ se crea (por eso la veías en rojo) pero el diálogo
    // nunca se cierra y el botón se queda girando.
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
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo crear la reserva: $e')),
      );
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva reserva'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatDate(widget.checkIn)} → ${_formatDate(widget.checkOut)}'
                ' ($_nights ${_nights == 1 ? 'noche' : 'noches'})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del huésped'),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Requerido';
                  if (!_emailRegex.hasMatch(value.trim())) return 'Email inválido';
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
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalPriceController,
                      decoration: const InputDecoration(labelText: 'Precio total (USD)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatePositiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depositController,
                      decoration: const InputDecoration(labelText: 'Señal (USD)'),
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
              : const Text('Crear reserva'),
        ),
      ],
    );
  }
}