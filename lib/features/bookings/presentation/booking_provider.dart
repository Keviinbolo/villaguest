import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:villaguest/core/services/firebase_service.dart';
import 'package:villaguest/features/bookings/data/models/booking_model.dart';
import 'package:villaguest/features/calendar/data/repositories/availability_repository.dart';


class BookingProvider extends ChangeNotifier {
  BookingProvider({AvailabilityRepository? repository})
      : _repository = repository ?? AvailabilityRepository();

  final AvailabilityRepository _repository;
  StreamSubscription<List<BookingModel>>? _subscription;

  bool _hasAccess = false;
  String? _villaId;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const _activeStatuses = ['pending', 'confirmed', 'completed'];

  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BookingModel> get activeBookings =>
      _bookings.where((b) => _activeStatuses.contains(b.status)).toList();

  void updateAuthorization(bool hasAccess, String? villaId) {
    if (hasAccess == _hasAccess && villaId == _villaId) return;
    _hasAccess = hasAccess;
    _villaId = villaId;

    _subscription?.cancel();
    _subscription = null;

    if (hasAccess && villaId != null) {
      _isLoading = true;
      _errorMessage = null;
      _subscribe();
    } else {
      _bookings = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.streamBookings(_villaId!).listen(
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

  Future<String> createBooking(BookingModel booking) async {
    assert(_villaId != null);
    final id = await _repository.createBooking(booking, _villaId!);
    _notify(
      title: 'Nueva reserva',
      body:
          '${booking.guestName} · ${_fmtDate(booking.checkIn)} → ${_fmtDate(booking.checkOut)}',
    );
    return id;
  }

  Future<void> updateBooking(BookingModel booking) {
    assert(_villaId != null);
    return _repository.updateBooking(booking, _villaId!);
  }

  Future<void> updateStatus({
    required String bookingId,
    required String newStatus,
  }) async {
    await _repository.updateStatus(bookingId: bookingId, newStatus: newStatus);
    const labels = {
      'confirmed': 'Confirmada',
      'cancelled': 'Cancelada',
      'completed': 'Completada',
    };
    final label = labels[newStatus];
    if (label != null) {
      final guest =
          _bookings.where((b) => b.id == bookingId).firstOrNull?.guestName ?? '';
      _notify(title: 'Reserva $label', body: guest);
    }
  }

  void _notify({required String title, required String body}) {
    if (_villaId == null) return;
    FirebaseService.instance.sendNotificationToVilla(
      villaId: _villaId!,
      title: title,
      body: body,
      excludeUid: FirebaseService.instance.currentUser?.uid,
    ).ignore();
  }

  static String _fmtDate(DateTime d) => '${d.day}/${d.month}';

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
