import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/guest_note_model.dart';
import '../../data/repositories/guest_repository.dart';

/// Mismo patrón que los demás providers: NO se suscribe en el
/// constructor. Se conecta a AuthProvider vía ChangeNotifierProxyProvider
/// en main.dart.
class GuestProvider extends ChangeNotifier {
  GuestProvider({GuestRepository? repository})
      : _repository = repository ?? GuestRepository();

  final GuestRepository _repository;
  StreamSubscription<Map<String, GuestNoteModel>>? _subscription;

  bool _hasAccess = false;
  Map<String, GuestNoteModel> _notes = {};
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, GuestNoteModel> get notes => Map.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Solo admin tiene permiso sobre `guests` (misma regla que
  /// `bookings`, del cual este feature depende).
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
      _notes = {};
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.streamGuestNotes().listen(
      (data) {
        _notes = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'No se pudieron cargar los datos de huéspedes: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> upsertGuestNote({
    required String email,
    required String notes,
    required bool isVip,
  }) {
    return _repository.upsertGuestNote(email: email, notes: notes, isVip: isVip);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}