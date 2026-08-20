import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/data/models/booking_model.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

/// Diálogo para registrar un pago parcial o total sobre una reserva.
/// Permite ingresar el monto recibido y lo suma al depósito ya pagado,
/// sin permitir superar el precio total.
class RegisterPaymentDialog extends StatefulWidget {
  const RegisterPaymentDialog({super.key, required this.booking});

  final BookingModel booking;

  @override
  State<RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<RegisterPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  double get _balanceDue =>
      widget.booking.totalPrice - widget.booking.depositPaid;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Número inválido';
    if (parsed <= 0) return 'Debe ser mayor a cero';
    if (parsed > _balanceDue) {
      return 'No puede superar el saldo pendiente (RD\$ ${_balanceDue.toStringAsFixed(2)})';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    setState(() => _isSubmitting = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<BookingProvider>();
    final booking = widget.booking;
    final willComplete =
        booking.depositPaid + amount >= booking.totalPrice &&
        booking.status != 'completed';

    try {
      await provider.registerPayment(
        bookingId: booking.id,
        currentDeposit: booking.depositPaid,
        amount: amount,
      );

      if (willComplete) {
        await provider.updateStatus(
          bookingId: booking.id,
          newStatus: 'completed',
        );
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            willComplete
                ? 'Pago registrado. Reserva marcada como completada.'
                : 'Pago de RD\$ ${amount.toStringAsFixed(2)} registrado.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo registrar el pago: $e')),
      );
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow('Precio total', widget.booking.totalPrice),
            _summaryRow('Ya pagado', widget.booking.depositPaid),
            _summaryRow('Saldo pendiente', _balanceDue, bold: true),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monto recibido (RD\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validateAmount,
            ),
          ],
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
              : const Text('Registrar'),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            'RD\$ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
