import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

/// Servicio central de Firebase para VillaGuestRD.
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
      // 'invalid-credential' cubre credenciales incorrectas (email o contraseña)
      // en el SDK moderno de Firebase Auth. 'wrong-password' y 'user-not-found'
      // ya no se emiten por separado para evitar enumerar usuarios existentes.
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
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
  // STORAGE — proxied through Supabase Edge Function (storage-proxy)
  // Firebase ID token is verified server-side before any write is allowed.
  // ---------------------------------------------------------------------

  static final Uri _proxyUri =
      Uri.parse('${SupabaseConfig.url}/functions/v1/storage-proxy');

  Future<String> _firebaseIdToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated Firebase user');
    return await user.getIdToken() ?? (throw Exception('Could not retrieve Firebase ID token'));
  }

  Map<String, String> _baseHeaders(String idToken) => {
        'Authorization': 'Bearer $idToken',
        'apikey': SupabaseConfig.anonKey,
      };

  Future<String> uploadBytes({
    required String storagePath,
    required Uint8List data,
    String? contentType,
  }) async {
    final idToken = await _firebaseIdToken();
    final response = await http.post(
      _proxyUri,
      headers: {
        ..._baseHeaders(idToken),
        'Content-Type': contentType ?? 'image/jpeg',
        'x-storage-path': storagePath,
      },
      body: data,
    );

    if (response.statusCode != 200) {
      throw Exception('Upload failed (${response.statusCode}): ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  Future<void> deleteFile(String storagePath) async {
    final idToken = await _firebaseIdToken();
    await http.delete(
      _proxyUri,
      headers: {
        ..._baseHeaders(idToken),
        'x-storage-path': storagePath,
      },
    );
  }

  Future<void> deleteFolder(String storagePath) async {
    final idToken = await _firebaseIdToken();
    await http.delete(
      _proxyUri,
      headers: {
        ..._baseHeaders(idToken),
        'x-storage-path': storagePath,
        'x-is-folder': 'true',
      },
    );
  }
}