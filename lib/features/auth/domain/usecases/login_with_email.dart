import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmail {
  final AuthRepository _repo;

  const LoginWithEmail(this._repo);

  Future<UserEntity?> call({
    required String email,
    required String password,
  }) {
    return _repo.login(email, password);
  }
}

