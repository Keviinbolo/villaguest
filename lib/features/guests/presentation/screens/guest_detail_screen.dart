import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/bookings/presentation/screen/booking_detail_screen.dart';
import 'package:villaguest/features/bookings/presentation/screen/bookings_list_screen.dart';

import '../../domain/guest_profile.dart';
import '../providers/guest_provider.dart';

/// Ficha de un huésped: contacto, historial de estancias, y notas
/// editables por el anfitrión (con marca VIP opcional).
class GuestDetailScreen extends StatefulWidget {
  const GuestDetailScreen({super.key, required this.email});

  final String email;

  @override
  State<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  final _notesController = TextEditingController();
  bool _isVip = false;
  bool _isSaving = false;

  // Los controles de edición solo se inicializan UNA vez con los datos
  // guardados. Si los reinicializáramos en cada build, cualquier cambio
  // en BookingProvider/GuestProvider (p.ej. una reserva nueva de OTRO
  // huésped) borraría lo que el usuario esté escribiendo en ese momento.
  bool _controllerInitialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(GuestProvider guestProvider, String realEmail) async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await guestProvider.upsertGuestNote(
        email: realEmail,
        notes: _notesController.text.trim(),
        isVip: _isVip,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Guardado.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final guestProvider = context.watch<GuestProvider>();

    final profiles =
        GuestProfile.fromBookings(bookingProvider.bookings, guestProvider.notes);

    GuestProfile? matchingProfile;
    for (final p in profiles) {
      if (p.email == widget.email) {
        matchingProfile = p;
        break;
      }
    }

    if (matchingProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Huésped')),
        body: const Center(child: Text('Este huésped ya no tiene reservas.')),
      );
    }

    final profile = matchingProfile;

    if (!_controllerInitialized) {
      _notesController.text = profile.note?.notes ?? '';
      _isVip = profile.isVip;
      _controllerInitialized = true;
    }

    final realEmail = profile.bookings.first.guestEmail;

    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Contacto', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(realEmail),
          Text(profile.phone),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('${profile.stayCount} ${profile.stayCount == 1 ? 'estancia' : 'estancias'}'),
              const SizedBox(width: 16),
              Text('\$${profile.totalSpent.toStringAsFixed(2)} en total'),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Huésped VIP'),
            value: _isVip,
            onChanged: (value) => setState(() => _isVip = value),
          ),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notas',
              hintText: 'Preferencias, incidencias, alergias...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : () => _save(guestProvider, realEmail),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar notas'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Historial de reservas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...profile.bookings.map(
            (booking) => Card(
              child: ListTile(
                title: Text(
                  '${formatDate(booking.checkIn)} → ${formatDate(booking.checkOut)}',
                ),
                subtitle: Text(
                  'Estado: ${BookingsListScreen.statusLabel(booking.status)}',
                ),
                trailing: Text('\$${booking.totalPrice.toStringAsFixed(0)}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(bookingId: booking.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}