import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class FirebaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;

  const FirebaseAuthRemoteDataSourceImpl(this._auth);

  @override
  Future<UserModel?> signup(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return null;

    if (name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }

    final updated = _auth.currentUser;
    return UserModel(
      id: (updated ?? user).uid,
      name: (updated ?? user).displayName ?? name,
      email: (updated ?? user).email ?? email,
    );
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) return null;

    return UserModel(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? email,
    );
  }

  @override
  Future<UserModel?> loginWithGoogle() async {
    throw UnimplementedError('Google sign-in not implemented yet.');
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
    );
  }
}

