import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
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
      backgroundColor: AppTheme.surfacePage,
      appBar: const GradientAppBar(title: 'Huéspedes'),
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
      return _emptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _GuestCard(
          profile: profile,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GuestDetailScreen(email: profile.email),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.sage.withValues(alpha: 0.30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline,
                  size: 32, color: AppTheme.teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin huéspedes aún',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Se generan automáticamente desde las reservas.',
              style: TextStyle(color: Color(0xFF6B7A99), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.profile, required this.onTap});

  final GuestProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVip = profile.isVip;
    final avatarBg = isVip
        ? AppTheme.lime.withValues(alpha: 0.15)
        : AppTheme.sage.withValues(alpha: 0.30);
    final avatarBorder = isVip
        ? AppTheme.lime.withValues(alpha: 0.40)
        : AppTheme.teal.withValues(alpha: 0.25);
    final avatarFg = isVip ? AppTheme.lime : AppTheme.teal;
    final initial = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with initial
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarBorder, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: avatarFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVip) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.lime.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.lime.withValues(alpha: 0.40)),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.lime,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.email,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7A99)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.hotel_outlined,
                            size: 12, color: Color(0xFF6B7A99)),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.stayCount} ${profile.stayCount == 1 ? 'estancia' : 'estancias'}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7A99)),
                        ),
                        const Spacer(),
                        Text(
                          'RD\$ ${profile.totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFBBC3D8), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
