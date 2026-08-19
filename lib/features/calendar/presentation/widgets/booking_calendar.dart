import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';


/// Calendario mensual de disponibilidad de la villa.
///
/// - Verde: día libre
/// - Rojo: día con reserva activa (pending/confirmed/completed)
/// - Gris: día pasado (no seleccionable)
/// - Azul: rango seleccionado actualmente
///
/// Selección de rango: primer tap = check-in, segundo tap = check-out.
/// Al completar un rango válido, llama a [onRangeSelected] para que la
/// pantalla que lo use abra el flujo de creación de reserva.
///
/// No usa ningún paquete de calendario externo (table_calendar,
/// timetide, etc.) para evitar depender de una API que aún no
/// confirmamos que tengas instalada. Si más adelante quieres migrar a
/// uno de esos paquetes por temas de UX (swipe entre meses, rangos
/// multi-mes, etc.), esta clase se puede reemplazar sin tocar el
/// provider ni el repositorio.
class BookingCalendar extends StatefulWidget {
  const BookingCalendar({super.key, this.onRangeSelected});

  final void Function(DateTime checkIn, DateTime checkOut)? onRangeSelected;

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _visibleMonth;
  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
    });
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  bool _isPast(DateTime day) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return day.isBefore(todayDate);
  }

  void _handleDayTap(DateTime day, BookingProvider bookingProvider) {
    setState(() {
      final noSelectionOrRangeAlreadyComplete =
          _selectedCheckIn == null || _selectedCheckOut != null;

      if (noSelectionOrRangeAlreadyComplete) {
        _selectedCheckIn = day;
        _selectedCheckOut = null;
        return;
      }

      if (!day.isAfter(_selectedCheckIn!)) {
        // Tocaron una fecha igual o anterior al check-in: reinicia desde ahí.
        _selectedCheckIn = day;
        _selectedCheckOut = null;
        return;
      }

      final available = bookingProvider.isRangeAvailableLocally(
        checkIn: _selectedCheckIn!,
        checkOut: day,
      );

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ese rango incluye días ya reservados.'),
          ),
        );
        _selectedCheckIn = day;
        _selectedCheckOut = null;
        return;
      }

      _selectedCheckOut = day;
      widget.onRangeSelected?.call(_selectedCheckIn!, _selectedCheckOut!);
    });
  }

  bool _isInSelectedRange(DateTime day) {
    if (_selectedCheckIn == null) return false;
    if (_selectedCheckOut == null) {
      return day.isAtSameMomentAs(_selectedCheckIn!);
    }
    return !day.isBefore(_selectedCheckIn!) && !day.isAfter(_selectedCheckOut!);
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    if (bookingProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (bookingProvider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          bookingProvider.errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        _buildWeekdayLabels(),
        const SizedBox(height: 4),
        _buildMonthGrid(bookingProvider),
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _visibleMonth.year == now.year && _visibleMonth.month == now.month;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _goToPreviousMonth,
        ),
        Expanded(
          child: Center(
            child: Text(
              '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (!isCurrentMonth)
          TextButton(
            onPressed: _goToToday,
            child: const Text('Hoy'),
          )
        else
          const SizedBox(width: 48),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _goToNextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    return Row(
      children: _weekdayLabels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthGrid(BookingProvider bookingProvider) {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    // weekday: 1 = lunes ... 7 = domingo.
    final leadingEmptyCells = firstDayOfMonth.weekday - 1;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayNumber = index - leadingEmptyCells + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
        return _buildDayCell(day, bookingProvider);
      },
    );
  }

  Widget _buildDayCell(DateTime day, BookingProvider bookingProvider) {
    final isPast = _isPast(day);
    final isBooked = bookingProvider.isDayBooked(day);
    final isSelected = _isInSelectedRange(day);
    final isToday = _isToday(day);
    final isDisabled = isPast || isBooked;

    Color backgroundColor;
    Color textColor = Colors.black87;
    Border? border;

    if (isSelected) {
      backgroundColor = Colors.green.shade600;
      textColor = Colors.white;
    } else if (isBooked) {
      backgroundColor = Colors.orange.shade200;
      textColor = Colors.brown.shade800;
    } else if (isPast) {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade500;
    } else {
      backgroundColor = Colors.green.shade100;
    }

    if (isToday && !isSelected) {
      border = Border.all(
        color: Colors.green.shade700,
        width: 2,
      );
    }

    return GestureDetector(
      onTap: isDisabled ? null : () => _handleDayTap(day, bookingProvider),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    Widget legendItem(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        legendItem(Colors.green.shade100, 'Libre'),
        legendItem(Colors.orange.shade200, 'Reservado'),
        legendItem(Colors.green.shade600, 'Selección'),
        legendItem(Colors.grey.shade200, 'Pasado'),
      ],
    );
  }
}