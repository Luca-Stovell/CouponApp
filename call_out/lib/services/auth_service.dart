import 'dart:async';

class AuthUser {
  final String uid;
  final String email;
  const AuthUser({required this.uid, required this.email});
}

/// Simple interface so you can swap implementations (e.g., FirebaseAuth).
abstract class AuthService {
  Future<AuthUser?> currentUser();
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser> register({required String email, required String password});
  Future<AuthUser> login({required String email, required String password});
  Future<void> logout();
}

/// In‑memory demo impl (do NOT use in production). Replace with Firebase later.
class InMemoryAuthService implements AuthService {
  final _controller = StreamController<AuthUser?>.broadcast();
  final Map<String, String> _users = {}; // email -> password
  AuthUser? _user;

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_users.containsKey(email)) {
      throw AuthException('An account already exists for that email.');
    }
    _users[email] = password;
    _user = AuthUser(uid: email.hashCode.toString(), email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final stored = _users[email];
    if (stored == null || stored != password) {
      throw AuthException('Invalid email or password.');
    }
    _user = AuthUser(uid: email.hashCode.toString(), email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _user = null;
    _controller.add(null);
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
