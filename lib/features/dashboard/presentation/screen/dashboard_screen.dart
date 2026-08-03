import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';

import '../../../bookings/data/models/booking_model.dart';


/// Dashboard de ocupación e ingresos. Calcula todo en el cliente a
/// partir de las reservas ya cargadas en BookingProvider — sin queries
/// nuevas a Firestore. Funciona porque BookingProvider solo se
/// suscribe para cuentas admin (ver ChangeNotifierProxyProvider en
/// main.dart), así que este dashboard es, por construcción, invisible
/// para staff.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedYear;

  static const _monthLabels = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  _DashboardStats _computeStats(
    List<BookingModel> bookings,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    var occupiedNights = 0;
    var totalRevenue = 0.0;
    var totalCollected = 0.0;
    var bookingsCount = 0;

    for (final b in bookings) {
      // El ingreso se atribuye al periodo donde cae el check-in, para
      // no contar dos veces una estancia que cruza el límite del mes.
      if (!b.checkIn.isBefore(periodStart) && b.checkIn.isBefore(periodEnd)) {
        bookingsCount++;
        totalRevenue += b.totalPrice;
        totalCollected += b.depositPaid;
      }

      // Para ocupación sí contamos las noches que caen dentro del
      // periodo, aunque la estancia empiece antes o termine después.
      final overlapStart = b.checkIn.isAfter(periodStart) ? b.checkIn : periodStart;
      final overlapEnd = b.checkOut.isBefore(periodEnd) ? b.checkOut : periodEnd;
      if (overlapEnd.isAfter(overlapStart)) {
        occupiedNights += overlapEnd.difference(overlapStart).inDays;
      }
    }

    final totalNightsInPeriod = periodEnd.difference(periodStart).inDays;

    return _DashboardStats(
      bookingsCount: bookingsCount,
      occupiedNights: occupiedNights,
      totalNightsInPeriod: totalNightsInPeriod,
      totalRevenue: totalRevenue,
      totalCollected: totalCollected,
    );
  }

  List<double> _computeMonthlyRevenue(List<BookingModel> bookings, int year) {
    final monthly = List<double>.filled(12, 0);
    for (final b in bookings) {
      if (b.checkIn.year == year) {
        monthly[b.checkIn.month - 1] += b.totalPrice;
      }
    }
    return monthly;
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    if (bookingProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (bookingProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(child: Text(bookingProvider.errorMessage!)),
      );
    }

    // Reservas canceladas no cuentan ni para ocupación ni para
    // ingresos.
    final activeBookings =
        bookingProvider.bookings.where((b) => b.status != 'cancelled').toList();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final monthStats = _computeStats(activeBookings, monthStart, monthEnd);

    final yearStart = DateTime(_selectedYear, 1, 1);
    final yearEnd = DateTime(_selectedYear + 1, 1, 1);
    final yearStats = _computeStats(activeBookings, yearStart, yearEnd);
    final monthlyRevenue = _computeMonthlyRevenue(activeBookings, _selectedYear);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Este mes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildStatsGrid(monthStats),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Año $_selectedYear', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _selectedYear--),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _selectedYear++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatsGrid(yearStats),
          const SizedBox(height: 24),
          Text('Ingresos por mes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          _buildMonthlyBarChart(monthlyRevenue),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(_DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _statCard(
          'Ocupación',
          '${(stats.occupancyRate * 100).toStringAsFixed(0)}%',
          Icons.hotel_outlined,
          Colors.blue,
        ),
        _statCard(
          'Noches ocupadas',
          '${stats.occupiedNights}/${stats.totalNightsInPeriod}',
          Icons.nights_stay_outlined,
          Colors.indigo,
        ),
        _statCard(
          'Ingresos',
          '\$${stats.totalRevenue.toStringAsFixed(0)}',
          Icons.attach_money,
          Colors.green,
        ),
        _statCard(
          'Pendiente por cobrar',
          '\$${stats.pendingBalance.toStringAsFixed(0)}',
          Icons.hourglass_bottom_outlined,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<double> monthlyRevenue) {
    final maxValue = monthlyRevenue.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final value = monthlyRevenue[i];
          final heightFraction = maxValue == 0 ? 0.0 : value / maxValue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value > 0)
                    Text(
                      value >= 1000
                          ? '${(value / 1000).toStringAsFixed(1)}k'
                          : value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 9),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100 * heightFraction,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade300,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_monthLabels[i], style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    required this.bookingsCount,
    required this.occupiedNights,
    required this.totalNightsInPeriod,
    required this.totalRevenue,
    required this.totalCollected,
  });

  final int bookingsCount;
  final int occupiedNights;
  final int totalNightsInPeriod;
  final double totalRevenue;
  final double totalCollected;

  double get occupancyRate =>
      totalNightsInPeriod == 0 ? 0 : occupiedNights / totalNightsInPeriod;
  double get pendingBalance => totalRevenue - totalCollected;
}