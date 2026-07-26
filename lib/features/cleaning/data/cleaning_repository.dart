import 'dart:typed_data';

import 'package:villaguest/features/cleaning/data/cleaning_checklist_model.dart';
import 'package:villaguest/features/cleaning/data/cleaning_task_model.dart';

import '../../../../core/services/firebase_service.dart';


class CleaningRepository {
  static const String _collectionPath = 'cleaning_checklists';

  final FirebaseService _firebase = FirebaseService.instance;

  CleaningChecklistModel _fromDoc(String id, Map<String, dynamic> data) =>
      CleaningChecklistModel.fromJson(id, data);

  Stream<List<CleaningChecklistModel>> streamChecklists() {
    return _firebase
        .streamCollection(
          collectionPath: _collectionPath,
          queryBuilder: (q) => q.orderBy('checkOutDate', descending: true),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => _fromDoc(doc.id, doc.data())).toList());
  }

  /// Crea un checklist para una reserva, o devuelve el ID del que ya
  /// exista para esa reserva (evita duplicados si alguien toca el botón
  /// dos veces).
  Future<String> createChecklistForBooking({
    required String bookingId,
    required String guestName,
    required DateTime checkOutDate,
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

  /// Sube la foto a Storage y, solo si la subida tiene éxito, marca la
  /// tarea como completada en Firestore. Si la subida falla, la tarea
  /// se queda como estaba — nunca se marca completada sin foto real.
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

  /// Revierte una tarea a pendiente (por si se subió la foto equivocada).
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

  /// Borra el/los checklist(s) asociados a una reserva —Firestore y sus
  /// fotos en Storage—. Se llama cuando se borra la reserva, para no
  /// dejar checklists huérfanos apuntando a un bookingId que ya no
  /// existe. Normalmente hay como mucho uno (createChecklistForBooking
  /// evita duplicados), pero se borran todos los que aparezcan por si
  /// acaso.
  Future<void> deleteChecklistsForBooking(String bookingId) async {
    final matches = await _firebase.getCollection(
      collectionPath: _collectionPath,
      queryBuilder: (q) => q.where('bookingId', isEqualTo: bookingId),
    );

    for (final doc in matches.docs) {
      try {
        await _firebase.deleteFolder('cleaning_photos/${doc.id}');
      } catch (_) {
        // No bloqueamos el borrado del checklist si falla la limpieza
        // de fotos (por ejemplo, si no había ninguna foto todavía, o
        // hubo un problema de permisos puntual). En el peor caso queda
        // algún archivo huérfano en Storage — de bajo costo y fácil de
        // limpiar después. Lo importante es que el checklist sí se borre.
      }

      await _firebase.deleteDocument(
        collectionPath: _collectionPath,
        docId: doc.id,
      );
    }
  }
}