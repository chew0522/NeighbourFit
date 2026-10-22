import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/utils/ids.dart';
import 'local_repositories.dart';
import 'local_store.dart';

class AuthAccount {
  const AuthAccount({
    required this.email,
    required this.salt,
    required this.hash,
    required this.userId,
  });

  final String email;
  final String salt;
  final String hash;
  final String userId;

  Map<String, dynamic> toJson() => {
    'email': email,
    'salt': salt,
    'hash': hash,
    'userId': userId,
  };

  factory AuthAccount.fromJson(Map<String, dynamic> j) => AuthAccount(
    email: j['email'] as String? ?? '',
    salt: j['salt'] as String? ?? '',
    hash: j['hash'] as String? ?? '',
    userId: j['userId'] as String? ?? '',
  );
}

/// Local email and password accounts. MOCK: this is a prototype, so the data
/// stays on the device and the hash is a salted SHA-256, not a production
/// password scheme. A real backend would replace this class.
class AuthRepository {
  AuthRepository(this._store);

  final LocalStore _store;

  List<AuthAccount> _all() =>
      _store.readList(StoreKeys.auth).map(AuthAccount.fromJson).toList();

  static String normalise(String email) => email.trim().toLowerCase();

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  bool emailTaken(String email) =>
      _all().any((a) => a.email == normalise(email));

  Future<void> register({
    required String email,
    required String password,
    required String userId,
  }) async {
    final salt = newId();
    final list = _all()
      ..add(
        AuthAccount(
          email: normalise(email),
          salt: salt,
          hash: _hash(salt, password),
          userId: userId,
        ),
      );
    await _store.writeList(
      StoreKeys.auth,
      list.map((a) => a.toJson()).toList(),
    );
  }

  /// The user id for these credentials, or null if they do not match.
  String? login(String email, String password) {
    for (final a in _all()) {
      if (a.email == normalise(email) && a.hash == _hash(a.salt, password)) {
        return a.userId;
      }
    }
    return null;
  }
}
