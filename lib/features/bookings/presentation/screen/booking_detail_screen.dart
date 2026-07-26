import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/cleaning/presentation/cleaning_checklist_screen.dart';
import 'package:villaguest/features/cleaning/providers/cleaning_provider.dart';


import '../../data/models/booking_model.dart';

import 'bookings_list_screen.dart' show BookingsListScreen;

/// Detalle de una reserva: datos del huésped, desglose de pago, y
/// acciones para mover el estado (pending → confirmed → completed, o
/// cancelled en cualquier punto), además de eliminarla.
///
/// Se suscribe al BookingProvider en vivo (en vez de recibir el
/// BookingModel como parámetro fijo) para que, si cambias el estado,
/// la pantalla se actualice sola sin tener que volver atrás y re-entrar.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _updateStatus(
    BuildContext context,
    BookingProvider provider,
    String newStatus,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.updateStatus(bookingId: bookingId, newStatus: newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reserva actualizada a "${BookingsListScreen.statusLabel(newStatus)}".',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BookingProvider provider,
  ) async {
    // Capturamos Navigator, ScaffoldMessenger y CleaningProvider antes
    // de cualquier await, por la misma razón que en otros lados: evita
    // que el context quede obsoleto tras una operación async.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cleaningProvider = context.read<CleaningProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar reserva'),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Seguro que quieres eliminar esta reserva? '
          'También se eliminará su checklist de limpieza, si tiene uno.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // El borrado del checklist es "mejor esfuerzo": si falla (rules
      // no desplegadas, problema de red puntual, etc.), NO debe impedir
      // que se borre la reserva, que es la acción que el usuario pidió
      // explícitamente. En el peor caso queda un checklist huérfano,
      // que es un problema menor y recuperable — bloquear el borrado
      // de la reserva por esto sería peor.
      try {
        await cleaningProvider.deleteChecklistsForBooking(bookingId);
      } catch (_) {
        // Ignorado a propósito: ver comentario arriba.
      }

      await provider.deleteBooking(bookingId);

      navigator.pop(); // vuelve a la lista de reservas
      messenger.showSnackBar(const SnackBar(content: Text('Reserva eliminada.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  Future<void> _openCleaningChecklist(
    BuildContext context,
    BookingModel booking,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cleaningProvider = context.read<CleaningProvider>();

    try {
      final checklistId = await cleaningProvider.createChecklistForBooking(
        bookingId: booking.id,
        guestName: booking.guestName,
        checkOutDate: booking.checkOut,
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => CleaningChecklistScreen(checklistId: checklistId),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo abrir el checklist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    BookingModel? matchingBooking;
    for (final b in provider.bookings) {
      if (b.id == bookingId) {
        matchingBooking = b;
        break;
      }
    }

    if (matchingBooking == null) {
      // Puede pasar si la eliminaste desde otro dispositivo/pestaña
      // mientras estabas viendo esta pantalla.
      return Scaffold(
        appBar: AppBar(title: const Text('Reserva')),
        body: const Center(child: Text('Esta reserva ya no existe.')),
      );
    }

    // IMPORTANTE: guardamos la reserva en una variable `final`. La
    // variable de arriba (`matchingBooking`) se reasigna dentro de un
    // `for`, así que el analizador de Dart no la considera "efectivamente
    // final" — y sin eso, la promoción de BookingModel? a BookingModel
    // (que logramos con el chequeo `if (... == null) return`) NO
    // sobrevive dentro de un closure, como los `onPressed: () => ...`
    // de más abajo. Con esta copia final, sí sobrevive.
    final booking = matchingBooking;

    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final balanceDue = booking.totalPrice - booking.depositPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text(booking.guestName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar reserva',
            onPressed: () => _confirmDelete(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, 'Fechas'),
          _infoRow(
            'Check-in → Check-out',
            '${_formatDate(booking.checkIn)} → ${_formatDate(booking.checkOut)}',
          ),
          _infoRow('Noches', '$nights'),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Huésped'),
          _infoRow('Nombre', booking.guestName),
          _infoRow('Email', booking.guestEmail),
          _infoRow('Teléfono', booking.guestPhone),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Pago'),
          _infoRow('Precio total', '\$${booking.totalPrice.toStringAsFixed(2)}'),
          _infoRow('Señal pagada', '\$${booking.depositPaid.toStringAsFixed(2)}'),
          _infoRow('Saldo pendiente', '\$${balanceDue.toStringAsFixed(2)}'),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Estado'),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                BookingsListScreen.statusLabel(booking.status),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: BookingsListScreen.statusColor(booking.status),
            ),
          ),
          const SizedBox(height: 24),
          _buildActions(context, provider, booking),
          if (booking.status == 'confirmed' || booking.status == 'completed') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('Checklist de limpieza'),
                onPressed: () => _openCleaningChecklist(context, booking),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Botones disponibles según el estado actual. Solo se permiten
  /// transiciones que tienen sentido de negocio:
  /// pending → confirmed → completed, o cancelled desde pending/confirmed.
  /// 'completed' es un estado final sin acciones adicionales.
  Widget _buildActions(
    BuildContext context,
    BookingProvider provider,
    BookingModel booking,
  ) {
    final buttons = <Widget>[];

    switch (booking.status) {
      case 'pending':
        buttons.add(FilledButton(
          onPressed: () => _updateStatus(context, provider, 'confirmed'),
          child: const Text('Confirmar reserva'),
        ));
        buttons.add(OutlinedButton(
          onPressed: () => _updateStatus(context, provider, 'cancelled'),
          child: const Text('Cancelar reserva'),
        ));
        break;
      case 'confirmed':
        buttons.add(FilledButton(
          onPressed: () => _updateStatus(context, provider, 'completed'),
          child: const Text('Marcar como completada'),
        ));
        buttons.add(OutlinedButton(
          onPressed: () => _updateStatus(context, provider, 'cancelled'),
          child: const Text('Cancelar reserva'),
        ));
        break;
      case 'cancelled':
        buttons.add(OutlinedButton(
          onPressed: () => _updateStatus(context, provider, 'pending'),
          child: const Text('Reactivar como pendiente'),
        ));
        break;
      case 'completed':
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final button in buttons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: button,
          ),
      ],
    );
  }
}