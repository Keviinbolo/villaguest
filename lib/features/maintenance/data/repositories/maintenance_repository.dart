import 'dart:typed_data';

import '../../../../core/services/firebase_service.dart';
import '../models/maintenance_ticket_model.dart';

class MaintenanceRepository {
  static const String _collectionPath = 'maintenance_tickets';

  final FirebaseService _firebase = FirebaseService.instance;

  MaintenanceTicketModel _fromDoc(String id, Map<String, dynamic> data) =>
      MaintenanceTicketModel.fromJson(id, data);

  /// Stream de tickets de [villaId], ordenados por createdAt en cliente.
  Stream<List<MaintenanceTicketModel>> streamTickets(String villaId) {
    return _firebase
        .streamCollection(
          collectionPath: _collectionPath,
          queryBuilder: (q) => q.where('villaId', isEqualTo: villaId),
        )
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => _fromDoc(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<String> createTicket({
    required String title,
    required String description,
    required String priority,
    required String reportedBy,
    required String villaId,
    Uint8List? photoBytes,
  }) async {
    final docRef = _firebase.collection(_collectionPath).doc();

    String? photoUrl;
    if (photoBytes != null) {
      photoUrl = await _firebase.uploadBytes(
        storagePath: 'maintenance_photos/${docRef.id}.jpg',
        data: photoBytes,
        contentType: 'image/jpeg',
      );
    }

    await _firebase.setDocument(
      collectionPath: _collectionPath,
      docId: docRef.id,
      merge: false,
      data: {
        'villaId': villaId,
        'title': title,
        'description': description,
        'priority': priority,
        'status': 'open',
        'reportedBy': reportedBy,
        'createdAt': DateTime.now().toIso8601String(),
        'photoUrl': photoUrl,
        'resolvedAt': null,
      },
    );

    return docRef.id;
  }

  Future<void> updateStatus({
    required String ticketId,
    required String newStatus,
  }) {
    final data = <String, dynamic>{'status': newStatus};
    data['resolvedAt'] = newStatus == 'resolved'
        ? DateTime.now().toIso8601String()
        : null;

    return _firebase.updateDocument(
      collectionPath: _collectionPath,
      docId: ticketId,
      data: data,
    );
  }

  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firebase.deleteFile('maintenance_photos/$ticketId.jpg');
    } catch (_) {}

    await _firebase.deleteDocument(
      collectionPath: _collectionPath,
      docId: ticketId,
    );
  }
}
