import 'dart:typed_data';

import 'package:villaguest/core/services/firebase_service.dart';
import '../models/villa_settings_model.dart';

class VillaSettingsRepository {
  static const String _collection = 'villas';

  final FirebaseService _firebase = FirebaseService.instance;

  Stream<VillaSettingsModel> streamSettings(String villaId) {
    return _firebase
        .streamDocument(collectionPath: _collection, docId: villaId)
        .map((doc) => doc.exists && doc.data() != null
            ? VillaSettingsModel.fromJson(villaId, doc.data()!)
            : VillaSettingsModel.initial(villaId));
  }

  Future<void> updateSettings(VillaSettingsModel settings) {
    return _firebase.setDocument(
      collectionPath: _collection,
      docId: settings.villaId,
      data: settings.toJson(),
      merge: true,
    );
  }

  Future<String> uploadLogo(String villaId, Uint8List bytes) async {
    final url = await _firebase.uploadBytes(
      storagePath: 'villa_logos/$villaId.jpg',
      data: bytes,
      contentType: 'image/jpeg',
    );
    // Guardar la URL en el documento de la villa inmediatamente.
    await _firebase.setDocument(
      collectionPath: _collection,
      docId: villaId,
      data: {'logoUrl': url},
      merge: true,
    );
    return url;
  }
}
