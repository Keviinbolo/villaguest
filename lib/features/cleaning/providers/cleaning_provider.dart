import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:villaguest/features/cleaning/data/cleaning_checklist_model.dart';
import 'package:villaguest/features/cleaning/data/cleaning_repository.dart';


class CleaningProvider extends ChangeNotifier {
  CleaningProvider({CleaningRepository? repository})
      : _repository = repository ?? CleaningRepository();

  final CleaningRepository _repository;
  StreamSubscription<List<CleaningChecklistModel>>? _subscription;

  bool _hasAccess = false;
  String? _villaId;
  List<CleaningChecklistModel> _checklists = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<CleaningChecklistModel> get checklists => List.unmodifiable(_checklists);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateAuthorization(bool hasAccess, String? villaId) {
    if (hasAccess == _hasAccess && villaId == _villaId) return;
    _hasAccess = hasAccess;
    _villaId = villaId;

    _subscription?.cancel();
    _subscription = null;

    if (hasAccess && villaId != null) {
      _isLoading = true;
      _errorMessage = null;
      _subscribe();
    } else {
      _checklists = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.streamChecklists(_villaId!).listen(
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
    assert(_villaId != null);
    return _repository.createChecklistForBooking(
      bookingId: bookingId,
      guestName: guestName,
      checkOutDate: checkOutDate,
      villaId: _villaId!,
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
    if (_villaId == null) return Future.value();
    return _repository.deleteChecklistsForBooking(bookingId, _villaId!);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
