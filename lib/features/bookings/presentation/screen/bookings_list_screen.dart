import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

import 'booking_detail_screen.dart';

/// Lista de todas las reservas (pasadas, presentes y futuras), ordenadas
/// por fecha de check-in. Cada fila muestra el estado con un color y
/// lleva al detalle al tocarla.
class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({super.key});

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, BookingProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    // Mostramos TODAS las reservas, incluidas canceladas, para que el
    // anfitrión tenga el historial completo. El calendario, en cambio,
    // solo bloquea fechas con las activas.
    final bookings = [...provider.bookings]
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    if (bookings.isEmpty) {
      return const Center(child: Text('Todavía no hay reservas.'));
    }

    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor(booking.status).withValues(alpha: 0.15),
            child: Icon(Icons.event, color: statusColor(booking.status)),
          ),
          title: Text(booking.guestName),
          subtitle: Text(
            '${formatDate(booking.checkIn)} → ${formatDate(booking.checkOut)}',
          ),
          trailing: Chip(
            label: Text(
              statusLabel(booking.status),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: statusColor(booking.status),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(bookingId: booking.id),
              ),
            );
          },
        );
      },
    );
  }
}