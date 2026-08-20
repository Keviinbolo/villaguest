import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/guest_note_model.dart';
import '../../data/repositories/guest_repository.dart';

class GuestProvider extends ChangeNotifier {
  GuestProvider({GuestRepository? repository})
      : _repository = repository ?? GuestRepository();

  final GuestRepository _repository;
  StreamSubscription<Map<String, GuestNoteModel>>? _subscription;

  bool _hasAccess = false;
  String? _villaId;
  Map<String, GuestNoteModel> _notes = {};
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, GuestNoteModel> get notes => Map.unmodifiable(_notes);
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
      _notes = {};
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.streamGuestNotes(_villaId!).listen(
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
    assert(_villaId != null);
    return _repository.upsertGuestNote(
      email: email,
      notes: notes,
      isVip: isVip,
      villaId: _villaId!,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
