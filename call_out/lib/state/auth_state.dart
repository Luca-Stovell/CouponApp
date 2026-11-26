import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  final AuthService _svc;
  AuthUser? _user;
  bool _initialised = false;

  AuthState(this._svc) {
    _bootstrap();
  }

  bool get isReady => _initialised;
  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> _bootstrap() async {
    _user = await _svc.currentUser();
    _svc.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
    _initialised = true;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    await _svc.register(email: email, password: password);
  }

  Future<void> login(String email, String password) async {
    await _svc.login(email: email, password: password);
  }

  Future<void> logout() async {
    await _svc.logout();
  }
}
