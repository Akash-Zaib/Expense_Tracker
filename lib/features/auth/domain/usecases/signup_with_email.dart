import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignupWithEmail {
  final AuthRepository _repo;

  const SignupWithEmail(this._repo);

  Future<UserEntity?> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repo.signup(name, email, password);
  }
}

