import 'package:villaguest/features/bookings/data/models/booking_model.dart';

import '../../../../core/services/firebase_service.dart';

class AvailabilityRepository {
  static const String _collectionPath = 'bookings';

  static const List<String> _activeStatuses = [
    'pending',
    'confirmed',
    'completed',
  ];

  final FirebaseService _firebase = FirebaseService.instance;

  BookingModel _fromDoc(String id, Map<String, dynamic> data) {
    return BookingModel.fromJson({...data, 'id': id});
  }

  // ---------------------------------------------------------------------
  // LECTURA
  // ---------------------------------------------------------------------

  /// Stream en vivo de las reservas de [villaId], ordenadas por check-in
  /// en cliente (equality filter sin orderBy evita índice compuesto).
  Stream<List<BookingModel>> streamBookings(String villaId) {
    return _firebase
        .streamCollection(
          collectionPath: _collectionPath,
          queryBuilder: (q) => q.where('villaId', isEqualTo: villaId),
        )
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => _fromDoc(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => a.checkIn.compareTo(b.checkIn));
          return list;
        });
  }

  /// Reservas de [villaId] que se solapan con [from]-[to].
  ///
  /// El filtro por checkIn se hace en Firestore (índice de un solo campo);
  /// villaId, status y checkOut se filtran en cliente para evitar un
  /// índice compuesto. El filtro de villaId en cliente es esencial:
  /// sin él, reservas de otras villas bloquearían fechas incorrectamente.
  Future<List<BookingModel>> getOverlappingBookings({
    required DateTime from,
    required DateTime to,
    required String villaId,
    String? excludeBookingId,
  }) async {
    final snapshot = await _firebase.getCollection(
      collectionPath: _collectionPath,
      queryBuilder: (q) => q.where('checkIn', isLessThan: to.toIso8601String()),
    );

    return snapshot.docs
        .where((doc) => doc.data()['villaId'] == villaId)
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .where(
          (b) =>
              b.id != excludeBookingId &&
              _activeStatuses.contains(b.status) &&
              b.checkOut.isAfter(from),
        )
        .toList();
  }

  Future<bool> isRangeAvailable({
    required DateTime checkIn,
    required DateTime checkOut,
    required String villaId,
    String? excludeBookingId,
  }) async {
    final overlapping = await getOverlappingBookings(
      from: checkIn,
      to: checkOut,
      villaId: villaId,
      excludeBookingId: excludeBookingId,
    );
    return overlapping.isEmpty;
  }

  // ---------------------------------------------------------------------
  // ESCRITURA
  // ---------------------------------------------------------------------

  Future<String> createBooking(BookingModel booking, String villaId) async {
    final available = await isRangeAvailable(
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      villaId: villaId,
    );

    if (!available) {
      throw StateError('Las fechas seleccionadas ya no están disponibles.');
    }

    final docRef = _firebase.collection(_collectionPath).doc();
    final bookingWithId = booking.copyWith(id: docRef.id);

    await _firebase.setDocument(
      collectionPath: _collectionPath,
      docId: docRef.id,
      data: {...bookingWithId.toJson(), 'villaId': villaId},
      merge: false,
    );

    return docRef.id;
  }

  Future<void> updateBooking(BookingModel booking, String villaId) async {
    final available = await isRangeAvailable(
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      villaId: villaId,
      excludeBookingId: booking.id,
    );

    if (!available) {
      throw StateError('Las nuevas fechas chocan con otra reserva.');
    }

    await _firebase.updateDocument(
      collectionPath: _collectionPath,
      docId: booking.id,
      data: booking.toJson(),
    );
  }

  Future<void> updateStatus({
    required String bookingId,
    required String newStatus,
  }) {
    return _firebase.updateDocument(
      collectionPath: _collectionPath,
      docId: bookingId,
      data: {'status': newStatus},
    );
  }

  Future<void> deleteBooking(String bookingId) {
    return _firebase.deleteDocument(
      collectionPath: _collectionPath,
      docId: bookingId,
    );
  }

  Future<void> registerPayment({
    required String bookingId,
    required double currentDeposit,
    required double amount,
  }) {
    return _firebase.updateDocument(
      collectionPath: _collectionPath,
      docId: bookingId,
      data: {'depositPaid': currentDeposit + amount},
    );
  }
}
