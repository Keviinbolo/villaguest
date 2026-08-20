import '../../../../core/services/firebase_service.dart';
import '../models/guest_note_model.dart';

class GuestRepository {
  static const String _collectionPath = 'guests';

  final FirebaseService _firebase = FirebaseService.instance;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  /// Stream de notas de huéspedes de [villaId].
  Stream<Map<String, GuestNoteModel>> streamGuestNotes(String villaId) {
    return _firebase
        .streamCollection(
          collectionPath: _collectionPath,
          queryBuilder: (q) => q.where('villaId', isEqualTo: villaId),
        )
        .map((snapshot) {
          final map = <String, GuestNoteModel>{};
          for (final doc in snapshot.docs) {
            map[doc.id] = GuestNoteModel.fromJson(doc.id, doc.data());
          }
          return map;
        });
  }

  Future<void> upsertGuestNote({
    required String email,
    required String notes,
    required bool isVip,
    required String villaId,
  }) {
    return _firebase.setDocument(
      collectionPath: _collectionPath,
      docId: '${villaId}_${_normalizeEmail(email)}',
      merge: true,
      data: {
        'villaId': villaId,
        'email': _normalizeEmail(email),
        'notes': notes,
        'isVip': isVip,
      },
    );
  }
}
