import 'dart:typed_data';

import 'package:villaguest/features/cleaning/data/cleaning_checklist_model.dart';
import 'package:villaguest/features/cleaning/data/cleaning_task_model.dart';

import '../../../../core/services/firebase_service.dart';


class CleaningRepository {
  static const String _collectionPath = 'cleaning_checklists';

  final FirebaseService _firebase = FirebaseService.instance;

  CleaningChecklistModel _fromDoc(String id, Map<String, dynamic> data) =>
      CleaningChecklistModel.fromJson(id, data);

  /// Stream de checklists de [villaId], ordenados por checkOutDate en cliente.
  Stream<List<CleaningChecklistModel>> streamChecklists(String villaId) {
    return _firebase
        .streamCollection(
          collectionPath: _collectionPath,
          queryBuilder: (q) => q.where('villaId', isEqualTo: villaId),
        )
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => _fromDoc(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.checkOutDate.compareTo(a.checkOutDate));
          return list;
        });
  }

  /// Crea un checklist para una reserva, o devuelve el ID del que ya
  /// exista (evita duplicados si se toca el botón dos veces).
  Future<String> createChecklistForBooking({
    required String bookingId,
    required String guestName,
    required DateTime checkOutDate,
    required String villaId,
  }) async {
    final existing = await _firebase.getCollection(
      collectionPath: _collectionPath,
      queryBuilder: (q) => q.where('bookingId', isEqualTo: bookingId),
    );

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final docRef = _firebase.collection(_collectionPath).doc();

    final tasks = <String, dynamic>{};
    for (var i = 0; i < DefaultCleaningTasks.titles.length; i++) {
      final taskId = 'task_${i.toString().padLeft(2, '0')}';
      tasks[taskId] =
          CleaningTaskModel(id: taskId, title: DefaultCleaningTasks.titles[i]).toJson();
    }

    await _firebase.setDocument(
      collectionPath: _collectionPath,
      docId: docRef.id,
      merge: false,
      data: {
        'villaId': villaId,
        'bookingId': bookingId,
        'guestName': guestName,
        'checkOutDate': checkOutDate.toIso8601String(),
        'status': 'pending',
        'tasks': tasks,
        'createdAt': DateTime.now().toIso8601String(),
        'completedAt': null,
      },
    );

    return docRef.id;
  }

  Future<void> completeTaskWithPhoto({
    required String checklistId,
    required String taskId,
    required Uint8List photoBytes,
  }) async {
    final storagePath =
        'cleaning_photos/$checklistId/$taskId-${DateTime.now().millisecondsSinceEpoch}.jpg';

    final photoUrl = await _firebase.uploadBytes(
      storagePath: storagePath,
      data: photoBytes,
      contentType: 'image/jpeg',
    );

    await _firebase.updateDocument(
      collectionPath: _collectionPath,
      docId: checklistId,
      data: {
        'tasks.$taskId.isCompleted': true,
        'tasks.$taskId.photoUrl': photoUrl,
        'tasks.$taskId.completedAt': DateTime.now().toIso8601String(),
        'status': 'in_progress',
      },
    );
  }

  Future<void> resetTask({
    required String checklistId,
    required String taskId,
  }) {
    return _firebase.updateDocument(
      collectionPath: _collectionPath,
      docId: checklistId,
      data: {
        'tasks.$taskId.isCompleted': false,
        'tasks.$taskId.photoUrl': null,
        'tasks.$taskId.completedAt': null,
      },
    );
  }

  Future<void> markChecklistCompleted(String checklistId) {
    return _firebase.updateDocument(
      collectionPath: _collectionPath,
      docId: checklistId,
      data: {
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> deleteChecklistsForBooking(String bookingId, String villaId) async {
    final matches = await _firebase.getCollection(
      collectionPath: _collectionPath,
      queryBuilder: (q) => q
          .where('villaId', isEqualTo: villaId)
          .where('bookingId', isEqualTo: bookingId),
    );

    for (final doc in matches.docs) {
      try {
        await _firebase.deleteFolder('cleaning_photos/${doc.id}');
      } catch (_) {}

      await _firebase.deleteDocument(
        collectionPath: _collectionPath,
        docId: doc.id,
      );
    }
  }
}
