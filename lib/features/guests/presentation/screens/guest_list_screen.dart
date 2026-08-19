import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/guests/domain/guest_profile.dart';

import '../providers/guest_provider.dart';
import 'guest_detail_screen.dart';

class GuestListScreen extends StatelessWidget {
  const GuestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final guestProvider = context.watch<GuestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Huéspedes')),
      body: _buildBody(context, bookingProvider, guestProvider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookingProvider bookingProvider,
    GuestProvider guestProvider,
  ) {
    if (bookingProvider.isLoading || guestProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookingProvider.errorMessage != null) {
      return Center(child: Text(bookingProvider.errorMessage!));
    }
    if (guestProvider.errorMessage != null) {
      return Center(child: Text(guestProvider.errorMessage!));
    }

    final profiles =
        GuestProfile.fromBookings(bookingProvider.bookings, guestProvider.notes)
          ..sort((a, b) {
            final aDate = a.lastCheckIn;
            final bDate = b.lastCheckIn;
            if (bDate == null && aDate == null) return 0;
            if (bDate == null) return -1;
            if (aDate == null) return 1;
            return bDate.compareTo(aDate);
          });

    if (profiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay huéspedes. Se generan automáticamente a partir de las reservas.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                profile.isVip ? Colors.amber.shade100 : Colors.grey.shade200,
            child: Icon(
              profile.isVip ? Icons.star : Icons.person_outline,
              color: profile.isVip ? Colors.amber.shade800 : Colors.grey.shade600,
            ),
          ),
          title: Text(profile.name),
          subtitle: Text(
            '${profile.email} · ${profile.stayCount} ${profile.stayCount == 1 ? 'estancia' : 'estancias'}',
          ),
          trailing: Text(
            '\$${profile.totalSpent.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GuestDetailScreen(email: profile.email),
              ),
            );
          },
        );
      },
    );
  }
}