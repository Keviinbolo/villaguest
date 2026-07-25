import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/firebase_service.dart';

/// Estado de autenticación del administrador. No hay registro público:
/// el/los usuarios administradores se crean a mano desde la consola de
/// Firebase (Authentication → Users → Add user).
class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseService? firebaseService})
      : _firebase = firebaseService ?? FirebaseService.instance {
    _subscribe();
  }

  final FirebaseService _firebase;
  StreamSubscription<User?>? _subscription;

  User? _user;
  bool _isInitializing = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// true mientras Firebase todavía no confirma si hay una sesión
  /// guardada o no. Úsalo para mostrar un loader en vez de parpadear
  /// entre login y home al abrir la app.
  bool get isInitializing => _isInitializing;

  void _subscribe() {
    _subscription = _firebase.authStateChanges.listen((user) {
      _user = user;
      _isInitializing = false;
      notifyListeners();
    });
  }

  /// Intenta iniciar sesión. Devuelve `null` si tuvo éxito, o un mensaje
  /// de error legible en español si falló. No hace falta hacer nada más
  /// tras un login exitoso: el stream de authStateChanges se encarga de
  /// avisarle a AuthGate para que cambie de pantalla solo.
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
    _subscription?.cancel();
    super.dispose();
  }
}