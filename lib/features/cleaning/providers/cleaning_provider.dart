import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:villaguest/features/cleaning/data/cleaning_checklist_model.dart';
import 'package:villaguest/features/cleaning/data/cleaning_repository.dart';



/// Igual que BookingProvider: NO se suscribe a Firestore en el
/// constructor. Se suscribe/desuscribe a través de [updateAuthorization],
/// llamado por el ChangeNotifierProxyProvider de main.dart cada vez que
/// cambia el estado de sesión. Esto evita el bug de suscribirse antes
/// de que termine el login (cuando request.auth todavía es null para
/// las reglas de Firestore) y quedar con un error "pegado" para
/// siempre, ya que un stream rechazado por permisos no se reintenta
/// solo cuando después sí hay sesión válida.
class CleaningProvider extends ChangeNotifier {
  CleaningProvider({CleaningRepository? repository})
      : _repository = repository ?? CleaningRepository();

  final CleaningRepository _repository;
  StreamSubscription<List<CleaningChecklistModel>>? _subscription;

  bool _hasAccess = false;
  List<CleaningChecklistModel> _checklists = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<CleaningChecklistModel> get checklists => List.unmodifiable(_checklists);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Llamado por el ChangeNotifierProxyProvider cada vez que cambia el
  /// estado de sesión. Tanto admin como staff tienen permiso de lectura
  /// sobre cleaning_checklists según las reglas de Firestore, así que
  /// aquí basta con "¿hay sesión?", sin distinguir rol.
  void updateAuthorization(bool hasAccess) {
    if (hasAccess == _hasAccess) return;
    _hasAccess = hasAccess;

    if (hasAccess) {
      _isLoading = true;
      _errorMessage = null;
      _subscribe();
    } else {
      _subscription?.cancel();
      _subscription = null;
      _checklists = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

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