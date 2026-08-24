import 'package:flutter/material.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

import '../../data/models/booking_model.dart';
import 'booking_detail_screen.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':   return const Color(0xFFE07B00);
      case 'confirmed': return const Color(0xFF0F7B40);
      case 'completed': return const Color(0xFF1250B2);
      case 'cancelled': return const Color(0xFF6B7A99);
      default:          return const Color(0xFF6B7A99);
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'pending':   return 'Pendiente';
      case 'confirmed': return 'Confirmada';
      case 'completed': return 'Completada';
      case 'cancelled': return 'Cancelada';
      default:          return status;
    }
  }

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';
  String? _statusFilter;

  static const _filterOptions = [
    (label: 'Todas', value: null),
    (label: 'Pendiente', value: 'pending'),
    (label: 'Confirmada', value: 'confirmed'),
    (label: 'Completada', value: 'completed'),
    (label: 'Cancelada', value: 'cancelled'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookingModel> _applyFilters(List<BookingModel> all) {
    var result = [...all]..sort((a, b) => b.checkIn.compareTo(a.checkIn));
    if (_statusFilter != null) {
      result = result.where((b) => b.status == _statusFilter).toList();
    }
    final query = _searchText.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((b) {
        return b.guestName.toLowerCase().contains(query) ||
            b.guestEmail.toLowerCase().contains(query) ||
            b.guestPhone.contains(query);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    return Scaffold(
      appBar: const GradientAppBar(title: 'Reservas'),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(child: _buildList(provider)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o teléfono…',
          prefixIcon: const Icon(Icons.search_outlined),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchText = '');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _searchText = v),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _filterOptions.map((opt) {
          final selected = _statusFilter == opt.value;
          final color = opt.value == null
              ? Theme.of(context).colorScheme.primary
              : BookingsListScreen.statusColor(opt.value!);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt.label),
              selected: selected,
              onSelected: (_) =>
                  setState(() => _statusFilter = opt.value),
              selectedColor: color.withValues(alpha: 0.12),
              checkmarkColor: color,
              side: BorderSide(
                color: selected
                    ? color.withValues(alpha: 0.5)
                    : const Color(0xFFE2E7F2),
              ),
              labelStyle: TextStyle(
                color: selected ? color : const Color(0xFF6B7A99),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(BookingProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    final bookings = _applyFilters(provider.bookings);

    if (provider.bookings.isEmpty) {
      return _emptyState(
        icon: Icons.event_note_outlined,
        message: 'Todavía no hay reservas.',
        sub: 'Selecciona un rango en el calendario para crear una.',
      );
    }
    if (bookings.isEmpty) {
      return _emptyState(
        icon: Icons.filter_list_off,
        message: 'Sin resultados',
        sub: 'Prueba con otro filtro o búsqueda.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _BookingCard(
        booking: bookings[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                BookingDetailScreen(bookingId: bookings[index].id),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String message,
      required String sub}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFBBC3D8)),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568))),
            const SizedBox(height: 6),
            Text(sub,
                style: const TextStyle(
                    color: Color(0xFF6B7A99), fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Booking Card ───────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = BookingsListScreen.statusColor(booking.status);
    final statusLabel = BookingsListScreen.statusLabel(booking.status);
    final balanceDue = booking.totalPrice - booking.depositPaid;
    final nights =
        booking.checkOut.difference(booking.checkIn).inDays;

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
              // ── Avatar con inicial ─────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.28),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    booking.guestName.isNotEmpty
                        ? booking.guestName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Contenido ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + estado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.guestName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(label: statusLabel, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Fechas y noches
                    Row(
                      children: [
                        const Icon(Icons.date_range_outlined,
                            size: 13, color: Color(0xFF6B7A99)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${formatDate(booking.checkIn)} → ${formatDate(booking.checkOut)}'
                            '  ·  $nights ${nights == 1 ? 'noche' : 'noches'}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7A99)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Balance pendiente
                    if (balanceDue > 0 && booking.status != 'cancelled') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 13, color: Color(0xFFE07B00)),
                          const SizedBox(width: 4),
                          Text(
                            'Pendiente: RD\$ ${balanceDue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE07B00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Flecha ─────────────────────────────────────────────
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFFBBC3D8), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
