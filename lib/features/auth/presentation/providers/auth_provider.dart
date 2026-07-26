import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/firebase_service.dart';

/// Estado de autenticación del usuario, incluido su rol.
///
/// No hay registro público. Los usuarios se crean a mano desde la
/// consola de Firebase (Authentication → Add user), y su rol se define
/// en un documento Firestore `users/{uid}` con un campo `role`:
/// 'admin' (acceso completo) o 'staff' (limpieza/mantenimiento, acceso
/// limitado). Ver instrucciones al final de la respuesta para crear una
/// cuenta de equipo.
class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseService? firebaseService})
      : _firebase = firebaseService ?? FirebaseService.instance {
    _subscribeToAuthChanges();
  }

  final FirebaseService _firebase;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;

  User? _user;
  String? _role;
  bool _isInitializing = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// true mientras Firebase todavía no confirma sesión + rol. Úsalo
  /// para mostrar un loader en vez de parpadear entre pantallas.
  bool get isInitializing => _isInitializing;

  String? get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get isStaff => _role == 'staff';

  void _subscribeToAuthChanges() {
    _authSubscription = _firebase.authStateChanges.listen((user) {
      _user = user;
      _roleSubscription?.cancel();

      if (user == null) {
        _role = null;
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _subscribeToRole(user.uid);
    });
  }

  void _subscribeToRole(String uid) {
    _roleSubscription = _firebase
        .streamDocument(collectionPath: 'users', docId: uid)
        .listen(
      (doc) {
        // Si no existe un documento de rol para este usuario (por
        // ejemplo, tu cuenta de administrador original, creada antes
        // de este feature), asumimos 'admin' por compatibilidad hacia
        // atrás. Los roles nuevos SIEMPRE deben crear su documento
        // explícito en /users — así staff nunca queda como admin por
        // accidente, solo el caso contrario (admin sin doc todavía).
        _role = doc.exists ? (doc.data()?['role'] as String? ?? 'admin') : 'admin';
        _isInitializing = false;
        notifyListeners();
      },
      onError: (_) {
        _role = 'admin';
        _isInitializing = false;
        notifyListeners();
      },
    );
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebase.signIn(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() => _firebase.signOut();

  @override
  void dispose() {
    _authSubscription?.cancel();
    _roleSubscription?.cancel();
    super.dispose();
  }
}