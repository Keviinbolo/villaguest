import 'package:villaguest/features/bookings/data/models/booking_model.dart';
import '../../../../core/services/firebase_service.dart';


/// Repositorio de disponibilidad y reservas.

class AvailabilityRepository {
  static const String _collectionPath = 'bookings';

  /// Estados que "ocupan" el calendario. Una reserva cancelada no bloquea
  /// fechas.
  static const List<String> _activeStatuses = ['pending', 'confirmed', 'completed'];

  final FirebaseService _firebase = FirebaseService.instance;

  BookingModel _fromDoc(String id, Map<String, dynamic> data) {
    return BookingModel.fromJson({...data, 'id': id});
  }

  // ---------------------------------------------------------------------
  // LECTURA
  // ---------------------------------------------------------------------

  /// Stream en vivo de todas las reservas activas, ordenadas por check-in.
  /// Úsalo para pintar el calendario y que se actualice solo si reservas
  /// desde otro dispositivo (o si automatizas creación vía WhatsApp/Stripe).
  Stream<List<BookingModel>> streamBookings() {
    return _firebase
        .streamCollection(
          collectionPath: _collectionPath,
          queryBuilder: (q) => q.orderBy('checkIn'),
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromDoc(doc.id, doc.data()))
            .toList());
  }

  /// Reservas que se solapan con [from]-[to] (incluye solapamientos
  /// parciales). Firestore no permite filtrar dos rangos en la misma
  /// query, así que acotamos por checkIn en el servidor y filtramos
  /// checkOut en el cliente.
  Future<List<BookingModel>> getOverlappingBookings({
    required DateTime from,
    required DateTime to,
    String? excludeBookingId,
  }) async {
    final snapshot = await _firebase.getCollection(
      collectionPath: _collectionPath,
      queryBuilder: (q) => q
          .where('status', whereIn: _activeStatuses)
          .where('checkIn', isLessThan: to.toIso8601String()),
    );

    return snapshot.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .where((b) => b.id != excludeBookingId && b.checkOut.isAfter(from))
        .toList();
  }

  /// true si el rango está libre de reservas activas.
  Future<bool> isRangeAvailable({
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) async {
    final overlapping = await getOverlappingBookings(
      from: checkIn,
      to: checkOut,
      excludeBookingId: excludeBookingId,
    );
    return overlapping.isEmpty;
  }

  // ---------------------------------------------------------------------
  // ESCRITURA
  // ---------------------------------------------------------------------

  /// Crea una reserva tras revalidar disponibilidad.
  ///
  /// El ID se genera ANTES de escribir (en vez de dejar que
  /// `addDocument` lo autogenere) para que el campo `id` guardado dentro
  /// del documento sea siempre el mismo que el ID real del documento en
  /// Firestore. Usamos `setDocument` en lugar de `addDocument` para que
  /// `createdAt` se guarde tal cual lo define el modelo (String ISO) y
  /// no lo pise el `serverTimestamp()` que añade `addDocument`.
  ///
  /// Nota importante: Firestore no permite ejecutar queries arbitrarias
  /// dentro de una transacción, así que esto NO es 100% atómico a nivel
  /// de base de datos (dos escrituras simultáneas en el mismo
  /// milisegundo, en teoría, podrían colarse). Para una sola villa con
  /// reservas gestionadas por ti, el riesgo real es prácticamente nulo.
  /// Si en el futuro automatizas la creación de reservas (p.ej. checkout
  /// público sin pasar por ti), lo correcto es mover esta validación a
  /// una Cloud Function con un documento "lock" por rango de fechas.
  Future<String> createBooking(BookingModel booking) async {
    final available = await isRangeAvailable(
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
    );

    if (!available) {
      throw StateError('Las fechas seleccionadas ya no están disponibles.');
    }

    final docRef = _firebase.collection(_collectionPath).doc();
    final bookingWithId = booking.copyWith(id: docRef.id);

    await _firebase.setDocument(
      collectionPath: _collectionPath,
      docId: docRef.id,
      data: bookingWithId.toJson(),
      merge: false,
    );

    return docRef.id;
  }

  /// Actualiza una reserva existente. Si cambian las fechas, revalida
  /// disponibilidad excluyendo la propia reserva (para no chocar contra
  /// sí misma).
  Future<void> updateBooking(BookingModel booking) async {
    final available = await isRangeAvailable(
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
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
}