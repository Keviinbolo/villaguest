import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../data/models/villa_settings_model.dart';
import '../../data/repositories/villa_settings_repository.dart';

class VillaSettingsProvider extends ChangeNotifier {
  VillaSettingsProvider({VillaSettingsRepository? repository})
      : _repository = repository ?? VillaSettingsRepository();

  final VillaSettingsRepository _repository;
  StreamSubscription<VillaSettingsModel>? _subscription;

  bool _hasAccess = false;
  String? _villaId;

  VillaSettingsModel? _settings;
  bool _isLoading = true;
  bool _isUploadingLogo = false;

  VillaSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isUploadingLogo => _isUploadingLogo;

  void updateAuthorization(bool hasAccess, String? villaId) {
    if (hasAccess == _hasAccess && villaId == _villaId) return;
    _hasAccess = hasAccess;
    _villaId = villaId;

    _subscription?.cancel();
    _subscription = null;

    if (hasAccess && villaId != null) {
      _isLoading = true;
      _subscribe();
    } else {
      _settings = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.streamSettings(_villaId!).listen(
      (settings) {
        _settings = settings;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateSettings(VillaSettingsModel settings) async {
    await _repository.updateSettings(settings);
  }

  Future<void> uploadLogo(Uint8List bytes) async {
    if (_villaId == null) return;
    _isUploadingLogo = true;
    notifyListeners();
    try {
      await _repository.uploadLogo(_villaId!, bytes);
    } finally {
      _isUploadingLogo = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
