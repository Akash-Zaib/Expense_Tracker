import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> signup(String name, String email, String password);
  Future<UserEntity?> loginWithGoogle();
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}
