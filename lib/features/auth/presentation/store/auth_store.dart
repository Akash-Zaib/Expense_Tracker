import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/signup_with_email.dart';

class AuthStore extends ChangeNotifier {
  final SignupWithEmail signupWithEmail;
  final LoginWithEmail loginWithEmail;
  final Logout logoutUsecase;

  AuthStore({
    required this.signupWithEmail,
    required this.loginWithEmail,
    required this.logoutUsecase,
  });

  bool _loading = false;
  String? _error;
  UserEntity? _currentUser;

  bool get loading => _loading;
  String? get error => _error;
  UserEntity? get currentUser => _currentUser;

  Future<UserEntity?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final user = await signupWithEmail(
        name: name,
        email: email,
        password: password,
      );
      _currentUser = user;

      // Never log the password.
      debugPrint('[Auth] signup success: email=$email');
      return user;
    } catch (e) {
      _error = _friendlyAuthMessage(e);
      debugPrint('[Auth] signup failed: email=$email error=$e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserEntity?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final user = await loginWithEmail(email: email, password: password);
      _currentUser = user;
      debugPrint('[Auth] login success: email=$email');
      return user;
    } catch (e) {
      _error = _friendlyAuthMessage(e);
      debugPrint('[Auth] login failed: email=$email error=$e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _error = null;
    notifyListeners();
    try {
      await logoutUsecase();
      _currentUser = null;
      debugPrint('[Auth] logout success');
    } catch (e) {
      _error = _friendlyAuthMessage(e);
      debugPrint('[Auth] logout failed: error=$e');
    } finally {
      _setLoading(false);
    }
  }

  String _friendlyAuthMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found for this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'weak-password':
          return 'Password is too weak (use at least 6 characters).';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'channel-error':
          return 'Firebase plugin not connected. Fully restart the app (stop, uninstall, flutter clean, run again).';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }

    final raw = e.toString();
    if (raw.contains('firebase_auth/channel-error') || raw.contains('PlatformException(channel-error')) {
      return 'Firebase plugin not connected. Fully restart the app (stop, uninstall, flutter clean, run again).';
    }
    return 'Authentication failed. Please try again.';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

