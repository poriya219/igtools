import 'package:igtools/models/user.dart';

class Authenticator {
  static const Map<String, User> _users = {};

  static const _passwords = {};

  User? findByEmailAndPassword({
    required String email,
    required String password,
  }) {
    final user = _users[email];

    if (user != null && _passwords[email] == password) {
      return user;
    }

    return null;
  }

  User? verifyToken(String email) {
    return _users[email];
  }
}
