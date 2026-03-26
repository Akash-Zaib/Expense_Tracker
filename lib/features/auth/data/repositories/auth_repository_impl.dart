import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  const AuthRepositoryImpl(this._remote);

  @override
  Future<UserEntity?> login(String email, String password) async {
    final UserModel? user = await _remote.login(email, password);
    return user;
  }

  @override
  Future<UserEntity?> signup(String name, String email, String password) async {
    final UserModel? user = await _remote.signup(name, email, password);
    return user;
  }

  @override
  Future<UserEntity?> loginWithGoogle() async {
    final UserModel? user = await _remote.loginWithGoogle();
    return user;
  }

  @override
  Future<void> logout() => _remote.logout();

  @override
  Future<UserEntity?> getCurrentUser() => _remote.getCurrentUser();
}

