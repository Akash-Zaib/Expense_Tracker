import 'dart:async';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> signup(String name, String email, String password);
  Future<UserModel?> loginWithGoogle();
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

// Mock Implementation for UI testing
class MockAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  UserModel? _currentUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (email == 'test@test.com' && password == 'password') {
      _currentUser = UserModel(id: '1', name: 'You', email: email);
      return _currentUser;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<UserModel?> signup(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = UserModel(id: '1', name: name, email: email);
    return _currentUser;
  }

  @override
  Future<UserModel?> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = UserModel(id: '1', name: 'You (Google)', email: 'google@test.com');
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }
}
