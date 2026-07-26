import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Servicio central de Firebase para VillaGest RD.
///
/// Envuelve Firestore, Auth y Storage para que ningún repositorio de
/// features (bookings, payments, guests, maintenance...) hable
/// directamente con los SDKs de Firebase. Así, si mañana cambias de
/// backend (p.ej. Supabase), solo tocas este archivo.
class FirebaseService {
  FirebaseService._internal();
  static final FirebaseService instance = FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------------------------------------------------
  // AUTH — login de administrador (no hay registro público en esta app)
  // ---------------------------------------------------------------------

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  // ---------------------------------------------------------------------
  // FIRESTORE — operaciones genéricas reutilizables por cualquier feature
  // ---------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _db.collection(path);

  /// Crea un documento con ID autogenerado y devuelve ese ID.
  Future<String> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final docRef = await _db.collection(collectionPath).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Crea o sobrescribe un documento con ID conocido.
  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await _db.collection(collectionPath).doc(docId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: merge));
  }

  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(collectionPath).doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    await _db.collection(collectionPath).doc(docId).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collectionPath,
    required String docId,
  }) {
    return _db.collection(collectionPath).doc(docId).get();
  }

  /// Stream de un documento (útil para pantallas de detalle en vivo).
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument({
    required String collectionPath,
    required String docId,
  }) {
    return _db.collection(collectionPath).doc(docId).snapshots();
  }

  /// Stream de una colección con query opcional.
  ///
  /// Ejemplo de uso desde availability_repository.dart:
  /// ```dart
  /// FirebaseService.instance.streamCollection(
  ///   collectionPath: 'bookings',
  ///   queryBuilder: (q) => q
  ///       .where('checkOut', isGreaterThanOrEqualTo: fromDate)
  ///       .orderBy('checkOut'),
  /// );
  /// ```
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(
      Query<Map<String, dynamic>> query,
    )?
        queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(
      Query<Map<String, dynamic>> query,
    )?
        queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.get();
  }

  /// Ejecuta varias escrituras de forma atómica.
  /// Útil, por ejemplo, para crear una reserva y descontar disponibilidad
  /// en la misma operación.
  Future<void> runBatch(
    void Function(WriteBatch batch) buildBatch,
  ) async {
    final batch = _db.batch();
    buildBatch(batch);
    await batch.commit();
  }

  /// Transacción para operaciones que necesitan leer antes de escribir
  /// (p.ej. comprobar disponibilidad justo antes de confirmar la reserva
  /// y evitar dobles reservas por condición de carrera).
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) {
    return _db.runTransaction(action);
  }

  // ---------------------------------------------------------------------
  // STORAGE — fotos de checklist de limpieza, documentos, contratos, etc.
  // ---------------------------------------------------------------------

  /// Sube bytes (útil en Flutter Web, donde no siempre hay File del
  /// sistema de archivos) y devuelve la URL pública de descarga.
  Future<String> uploadBytes({
    required String storagePath,
    required Uint8List data,
    String? contentType,
  }) async {
    final ref = _storage.ref(storagePath);
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;
    await ref.putData(data, metadata);
    return ref.getDownloadURL();
  }

  Future<void> deleteFile(String storagePath) async {
    await _storage.ref(storagePath).delete();
  }

  /// Elimina todos los archivos dentro de una "carpeta" de Storage
  /// (Storage no tiene carpetas reales; esto simula la jerarquía por
  /// prefijo de ruta usando listAll). Pensado para limpiar archivos
  /// huérfanos cuando se borra el documento padre — por ejemplo, todas
  /// las fotos de un checklist de limpieza cuando se borra la reserva
  /// asociada.
  Future<void> deleteFolder(String storagePath) async {
    final ref = _storage.ref(storagePath);
    final result = await ref.listAll().timeout(const Duration(seconds: 3));
    await Future.wait(
      result.items.map((item) => item.delete()),
    ).timeout(const Duration(seconds: 3));
  }

  Future<String> getDownloadUrl(String storagePath) {
    return _storage.ref(storagePath).getDownloadURL();
  }
}