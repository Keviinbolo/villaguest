import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:villaguest/features/bookings/data/models/booking_model.dart';
import 'package:villaguest/features/calendar/data/repositories/availability_repository.dart';


/// Estado de reservas para toda la app (calendario, dashboard, etc.).
///
/// A diferencia de la primera versión, YA NO se suscribe a Firestore en
/// el constructor. Se suscribe/desuscribe explícitamente a través de
/// [updateAuthorization], que llama el ChangeNotifierProxyProvider de
/// main.dart cada vez que cambia el rol de la sesión. Así, una cuenta
/// de staff (que no tiene permiso de lectura sobre `bookings` según las
/// reglas de Firestore) nunca intenta siquiera abrir el stream, en vez
/// de intentarlo y fallar con permission-denied.
class BookingProvider extends ChangeNotifier {
  BookingProvider({AvailabilityRepository? repository})
      : _repository = repository ?? AvailabilityRepository();

  final AvailabilityRepository _repository;
  StreamSubscription<List<BookingModel>>? _subscription;

  bool _hasAccess = false;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const _activeStatuses = ['pending', 'confirmed', 'completed'];

  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BookingModel> get activeBookings =>
      _bookings.where((b) => _activeStatuses.contains(b.status)).toList();

  /// Llamado por el ChangeNotifierProxyProvider cada vez que cambia el
  /// rol de la sesión actual (login, logout, o resolución del rol tras
  /// el login). Si [hasAccess] es true y todavía no estábamos
  /// suscritos, se suscribe. Si es false, se desuscribe y limpia el
  /// estado (por si había datos de una sesión de admin anterior en el
  /// mismo navegador).
  void updateAuthorization(bool hasAccess) {
    if (hasAccess == _hasAccess) return;
    _hasAccess = hasAccess;

    if (hasAccess) {
      _isLoading = true;
      _errorMessage = null;
      _subscribe();
    } else {
      _subscription?.cancel();
      _subscription = null;
      _bookings = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

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

  bool isDayBooked(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return activeBookings.any((b) {
      final checkIn = DateTime(b.checkIn.year, b.checkIn.month, b.checkIn.day);
      final checkOut = DateTime(b.checkOut.year, b.checkOut.month, b.checkOut.day);
      return !date.isBefore(checkIn) && date.isBefore(checkOut);
    });
  }

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

  Future<void> registerPayment({
    required String bookingId,
    required double currentDeposit,
    required double amount,
  }) {
    return _repository.registerPayment(
      bookingId: bookingId,
      currentDeposit: currentDeposit,
      amount: amount,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}