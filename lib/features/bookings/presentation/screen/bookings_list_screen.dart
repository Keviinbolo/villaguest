import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

import '../../data/models/booking_model.dart';
import 'booking_detail_screen.dart';

/// Lista de reservas con búsqueda por nombre/email y filtro por estado.
class BookingsListScreen extends StatefulWidget {
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

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';
  // null = todas
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
      appBar: AppBar(title: const Text('Reservas')),
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
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchText = '');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          isDense: true,
        ),
        onChanged: (value) => setState(() => _searchText = value),
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
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt.label),
              selected: selected,
              onSelected: (_) => setState(() => _statusFilter = opt.value),
              selectedColor: opt.value == null
                  ? Theme.of(context).colorScheme.primaryContainer
                  : BookingsListScreen.statusColor(opt.value!).withValues(alpha: 0.25),
              checkmarkColor: opt.value == null
                  ? Theme.of(context).colorScheme.primary
                  : BookingsListScreen.statusColor(opt.value!),
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
      return const Center(child: Text('Todavía no hay reservas.'));
    }

    if (bookings.isEmpty) {
      return const Center(child: Text('No hay reservas que coincidan con el filtro.'));
    }

    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final balanceDue = booking.totalPrice - booking.depositPaid;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                BookingsListScreen.statusColor(booking.status).withValues(alpha: 0.15),
            child: Icon(
              Icons.event,
              color: BookingsListScreen.statusColor(booking.status),
            ),
          ),
          title: Text(booking.guestName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${formatDate(booking.checkIn)} → ${formatDate(booking.checkOut)}'),
              if (balanceDue > 0 && booking.status != 'cancelled')
                Text(
                  'Pendiente: RD\$ ${balanceDue.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          trailing: Chip(
            label: Text(
              BookingsListScreen.statusLabel(booking.status),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: BookingsListScreen.statusColor(booking.status),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(bookingId: booking.id),
            ),
          ),
        );
      },
    );
  }
}
