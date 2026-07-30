import 'dart:typed_data';

import '../../../../core/services/firebase_service.dart';
import '../models/maintenance_ticket_model.dart';

class MaintenanceRepository {
  static const String _collectionPath = 'maintenance_tickets';

  final FirebaseService _firebase = FirebaseService.instance;

  MaintenanceTicketModel _fromDoc(String id, Map<String, dynamic> data) =>
      MaintenanceTicketModel.fromJson(id, data);

  Stream<List<MaintenanceTicketModel>> streamTickets() {
    return _firebase
        .streamCollection(
          collectionPath: _collectionPath,
          queryBuilder: (q) => q.orderBy('createdAt', descending: true),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList());
  }

  /// La foto es opcional a propósito (a diferencia del checklist de
  /// limpieza) — no toda avería tiene algo fotografiable de inmediato.
  Future<String> createTicket({
    required String title,
    required String description,
    required String priority,
    required String reportedBy,
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
    // 'resolvedAt' se llena al resolver y se limpia si se reabre.
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
    } catch (_) {
      // Mejor esfuerzo, igual que en cleaning: si no había foto o falla
      // el borrado en Storage, no bloqueamos el borrado del ticket.
    }

    await _firebase.deleteDocument(
      collectionPath: _collectionPath,
      docId: ticketId,
    );
  }
}