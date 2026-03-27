import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/firebase/users_directory_data_source.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class FirebaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final UsersDirectoryDataSource _usersDirectory;

  const FirebaseAuthRemoteDataSourceImpl(this._auth, this._usersDirectory);

  static const List<int> _signupPalette = [
    0xFFEC4899,
    0xFFF97316,
    0xFF8B5CF6,
    0xFF22C55E,
    0xFF3B82F6,
    0xFFEF4444,
    0xFFA855F7,
    0xFF94A3B8,
  ];

  @override
  Future<UserModel?> signup(String name, String email, String password) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Name is required.');
    }
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
    final uid = (updated ?? user).uid;
    final profileName = (updated ?? user).displayName?.trim().isNotEmpty == true
        ? (updated ?? user).displayName!.trim()
        : name.trim();
    final profileEmail = (updated ?? user).email ?? email;

    int color =
        await _usersDirectory.firstAvailableColor(_signupPalette) ??
        AppColors.primaryValue;
    final fallbackTaken = await _usersDirectory.isSignatureColorTaken(
      signatureColorValue: color,
      excludeUid: uid,
    );
    if (fallbackTaken) {
      color = 0xFF000000 | (uid.hashCode & 0x00FFFFFF);
      var attempts = 0;
      while (attempts < 8 &&
          await _usersDirectory.isSignatureColorTaken(
            signatureColorValue: color,
            excludeUid: uid,
          )) {
        color = 0xFF000000 | ((color + 0x00112233) & 0x00FFFFFF);
        attempts++;
      }
    }
    await _usersDirectory.upsertUserProfile(
      uid: uid,
      name: profileName,
      email: profileEmail,
      signatureColorValue: color,
    );

    return UserModel(id: uid, name: profileName, email: profileEmail);
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
