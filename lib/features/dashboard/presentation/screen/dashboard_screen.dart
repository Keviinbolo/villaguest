import 'package:flutter/material.dart';
import 'package:villaguest/core/services/invoice_service.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:villaguest/features/bookings/presentation/screen/invoice_preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:pdf/pdf.dart';

import '../../../bookings/data/models/booking_model.dart';

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
      if (!b.checkIn.isBefore(periodStart) && b.checkIn.isBefore(periodEnd)) {
        bookingsCount++;
        totalRevenue += b.totalPrice;
        totalCollected += b.depositPaid;
      }

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
        appBar: const GradientAppBar(title: 'Dashboard'),
        body: Center(child: Text(bookingProvider.errorMessage!)),
      );
    }

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

    final todayCheckIns = activeBookings.where((b) {
      final ci = b.checkIn;
      return ci.year == now.year && ci.month == now.month && ci.day == now.day;
    }).toList();

    final todayCheckOuts = activeBookings.where((b) {
      final co = b.checkOut;
      return co.year == now.year && co.month == now.month && co.day == now.day;
    }).toList();

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar reporte $_selectedYear',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoicePreviewScreen(
                  title: 'Reporte $_selectedYear',
                  filename: 'reporte_$_selectedYear.pdf',
                  buildBytes: (PdfPageFormat format) =>
                      InvoiceService.buildYearReportBytes(
                    format,
                    _selectedYear,
                    activeBookings,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (todayCheckIns.isNotEmpty || todayCheckOuts.isNotEmpty) ...[
            _buildTodaySection(todayCheckIns, todayCheckOuts),
            const SizedBox(height: 24),
          ],
          Text('Este mes', style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.navy, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 10),
          _buildStatsGrid(monthStats),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Año $_selectedYear', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.navy, fontWeight: FontWeight.w700,
              )),
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
          Text('Ingresos por mes', style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.navy, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 12),
          _buildMonthlyBarChart(monthlyRevenue),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTodaySection(
    List<BookingModel> checkIns,
    List<BookingModel> checkOuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hoy', style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.navy, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 8),
        if (checkIns.isNotEmpty) ...[
          _todayCard(
            label: 'Check-in hoy',
            bookings: checkIns,
            icon: Icons.login_outlined,
            color: AppTheme.teal,
            bgColor: AppTheme.sage.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 8),
        ],
        if (checkOuts.isNotEmpty)
          _todayCard(
            label: 'Check-out hoy',
            bookings: checkOuts,
            icon: Icons.logout_outlined,
            color: AppTheme.lime,
            bgColor: AppTheme.cyan.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  Widget _todayCard({
    required String label,
    required List<BookingModel> bookings,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  '$label (${bookings.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final b in bookings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.guestName,
                        style: const TextStyle(color: Color(0xFF1A2E20), fontWeight: FontWeight.w500)),
                    Text(
                      'RD\$ ${b.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF5A7568), fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(_DashboardStats stats) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _statCard(
              'Ocupación',
              '${(stats.occupancyRate * 100).toStringAsFixed(0)}%',
              Icons.hotel_outlined,
              AppTheme.teal,
              AppTheme.sage.withValues(alpha: 0.45),
            ),
            _statCard(
              'Noches ocupadas',
              '${stats.occupiedNights}/${stats.totalNightsInPeriod}',
              Icons.nights_stay_outlined,
              AppTheme.mint,
              const Color(0xFFCDF0D8),
            ),
            _statCard(
              'Ingresos',
              'RD\$ ${_compact(stats.totalRevenue)}',
              Icons.payments_outlined,
              AppTheme.teal,
              AppTheme.sage.withValues(alpha: 0.45),
            ),
            _statCard(
              'Pendiente',
              'RD\$ ${_compact(stats.pendingBalance)}',
              Icons.hourglass_bottom_outlined,
              AppTheme.lime,
              AppTheme.cyan.withValues(alpha: 0.6),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _statCardWide(
          'Reservas en el período',
          '${stats.bookingsCount}',
          Icons.event_note_outlined,
          AppTheme.navy,
          AppTheme.sage.withValues(alpha: 0.30),
        ),
      ],
    );
  }

  String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color iconBg,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF5A7568),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCardWide(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color iconBg,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5A7568)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<double> monthlyRevenue) {
    final maxValue = monthlyRevenue.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();
    final currentMonthIndex = _selectedYear == now.year ? now.month - 1 : -1;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final value = monthlyRevenue[i];
          final heightFraction = maxValue == 0 ? 0.0 : value / maxValue;
          final isCurrent = i == currentMonthIndex;

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
                      style: TextStyle(
                        fontSize: 9,
                        color: isCurrent ? AppTheme.lime : const Color(0xFF5A7568),
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100 * heightFraction,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.lime
                          : AppTheme.teal.withValues(alpha: 0.55),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _monthLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                      color: isCurrent ? AppTheme.teal : const Color(0xFF6B7A99),
                    ),
                  ),
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
