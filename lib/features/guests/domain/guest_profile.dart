import '../../bookings/data/models/booking_model.dart';
import '../data/models/guest_note_model.dart';

/// Perfil de huésped calculado en el cliente: agrupa todas las reservas
/// con el mismo email y les suma la nota/VIP opcional guardada en
/// Firestore. NO se persiste tal cual — se recalcula cada vez que
/// cambian las reservas o las notas, así que siempre está al día sin
/// necesidad de sincronizar nada manualmente.
class GuestProfile {
  const GuestProfile({
    required this.email,
    required this.name,
    required this.phone,
    required this.bookings,
    this.note,
  });

  final String email;
  final String name;
  final String phone;
  final List<BookingModel> bookings;
  final GuestNoteModel? note;

  bool get isVip => note?.isVip ?? false;

  List<BookingModel> get activeBookings =>
      bookings.where((b) => b.status != 'cancelled').toList();

  int get stayCount => activeBookings.length;

  double get totalSpent =>
      activeBookings.fold(0.0, (sum, b) => sum + b.totalPrice);

  DateTime? get lastCheckIn => bookings.isEmpty
      ? null
      : bookings.map((b) => b.checkIn).reduce((a, b) => a.isAfter(b) ? a : b);

  /// Agrupa una lista de reservas por email normalizado (minúsculas,
  /// sin espacios) y arma un GuestProfile por cada huésped único.
  static List<GuestProfile> fromBookings(
    List<BookingModel> bookings,
    Map<String, GuestNoteModel> notes,
  ) {
    final grouped = <String, List<BookingModel>>{};
    for (final booking in bookings) {
      final key = booking.guestEmail.trim().toLowerCase();
      grouped.putIfAbsent(key, () => []).add(booking);
    }

    return grouped.entries.map((entry) {
      final guestBookings = entry.value
        ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
      final mostRecent = guestBookings.first;

      return GuestProfile(
        email: entry.key,
        name: mostRecent.guestName,
        phone: mostRecent.guestPhone,
        bookings: guestBookings,
        note: notes[entry.key],
      );
    }).toList();
  }
}