import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:villaguest/features/cleaning/data/cleaning_checklist_model.dart';
import 'package:villaguest/features/cleaning/data/cleaning_repository.dart';



class CleaningProvider extends ChangeNotifier {
  CleaningProvider({CleaningRepository? repository})
      : _repository = repository ?? CleaningRepository() {
    _subscribe();
  }

  final CleaningRepository _repository;
  StreamSubscription<List<CleaningChecklistModel>>? _subscription;

  List<CleaningChecklistModel> _checklists = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<CleaningChecklistModel> get checklists => List.unmodifiable(_checklists);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _subscribe() {
    _subscription = _repository.streamChecklists().listen(
      (data) {
        _checklists = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'No se pudieron cargar los checklists: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<String> createChecklistForBooking({
    required String bookingId,
    required String guestName,
    required DateTime checkOutDate,
  }) {
    return _repository.createChecklistForBooking(
      bookingId: bookingId,
      guestName: guestName,
      checkOutDate: checkOutDate,
    );
  }

  Future<void> completeTaskWithPhoto({
    required String checklistId,
    required String taskId,
    required Uint8List photoBytes,
  }) {
    return _repository.completeTaskWithPhoto(
      checklistId: checklistId,
      taskId: taskId,
      photoBytes: photoBytes,
    );
  }

  Future<void> resetTask({
    required String checklistId,
    required String taskId,
  }) {
    return _repository.resetTask(checklistId: checklistId, taskId: taskId);
  }

  Future<void> markChecklistCompleted(String checklistId) {
    return _repository.markChecklistCompleted(checklistId);
  }

  Future<void> deleteChecklistsForBooking(String bookingId) {
    return _repository.deleteChecklistsForBooking(bookingId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}