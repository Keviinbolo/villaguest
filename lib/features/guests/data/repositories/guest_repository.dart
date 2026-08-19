import '../../../../core/services/firebase_service.dart';
import '../models/guest_note_model.dart';

class GuestRepository {
  static const String _collectionPath = 'guests';

  final FirebaseService _firebase = FirebaseService.instance;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Stream<Map<String, GuestNoteModel>> streamGuestNotes() {
    return _firebase.streamCollection(collectionPath: _collectionPath).map((snapshot) {
      final map = <String, GuestNoteModel>{};
      for (final doc in snapshot.docs) {
        map[doc.id] = GuestNoteModel.fromJson(doc.id, doc.data());
      }
      return map;
    });
  }

  /// Crea o actualiza la nota/VIP de un huésped. Usa `merge: true`
  /// porque este documento puede no existir todavía (la mayoría de
  /// huéspedes nunca tendrán notas, y eso está bien).
  Future<void> upsertGuestNote({
    required String email,
    required String notes,
    required bool isVip,
  }) {
    // FirebaseService.setDocument ya añade 'updatedAt' con serverTimestamp().
    return _firebase.setDocument(
      collectionPath: _collectionPath,
      docId: _normalizeEmail(email),
      merge: true,
      data: {
        'notes': notes,
        'isVip': isVip,
      },
    );
  }
}