import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:villaguest/features/bookings/data/models/booking_model.dart';
import 'package:villaguest/features/calendar/data/repositories/availability_repository.dart';

/// Estado de reservas para toda la app (calendario, dashboard, etc.).
///
/// Se suscribe en tiempo real a AvailabilityRepository.streamBookings()
/// y expone la lista de reservas + helpers de disponibilidad para que
/// los widgets no tengan que hablar con Firestore directamente.
class BookingProvider extends ChangeNotifier {
  BookingProvider({AvailabilityRepository? repository})
      : _repository = repository ?? AvailabilityRepository() {
    _subscribe();
  }

  final AvailabilityRepository _repository;
  StreamSubscription<List<BookingModel>>? _subscription;

  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  /// Estados que bloquean fechas en el calendario. 'cancelled' no cuenta.
  static const _activeStatuses = ['pending', 'confirmed', 'completed'];

  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BookingModel> get activeBookings =>
      _bookings.where((b) => _activeStatuses.contains(b.status)).toList();

  void _subscribe() {
    _subscription = _repository.streamBookings().listen(
      (bookings) {
        _bookings = bookings;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'No se pudieron cargar las reservas: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// true si [day] cae dentro de alguna reserva activa. Pensado para
  /// pintar el calendario día a día sin pegarle a Firestore por cada
  /// celda.
  bool isDayBooked(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return activeBookings.any((b) {
      final checkIn = DateTime(b.checkIn.year, b.checkIn.month, b.checkIn.day);
      final checkOut = DateTime(b.checkOut.year, b.checkOut.month, b.checkOut.day);
      return !date.isBefore(checkIn) && date.isBefore(checkOut);
    });
  }

  /// Comprobación rápida en cliente usando los datos ya cargados en
  /// memoria — pensada para dar feedback instantáneo en la UI (p.ej. al
  /// seleccionar un rango en el calendario). NO sustituye la
  /// revalidación real que hace AvailabilityRepository contra Firestore
  /// al crear o editar una reserva.
  bool isRangeAvailableLocally({
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) {
    return !activeBookings.any((b) {
      if (b.id == excludeBookingId) return false;
      return b.checkIn.isBefore(checkOut) && b.checkOut.isAfter(checkIn);
    });
  }

  Future<String> createBooking(BookingModel booking) {
    return _repository.createBooking(booking);
  }

  Future<void> updateBooking(BookingModel booking) {
    return _repository.updateBooking(booking);
  }

  Future<void> updateStatus({
    required String bookingId,
    required String newStatus,
  }) {
    return _repository.updateStatus(bookingId: bookingId, newStatus: newStatus);
  }

  Future<void> deleteBooking(String bookingId) {
    return _repository.deleteBooking(bookingId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}