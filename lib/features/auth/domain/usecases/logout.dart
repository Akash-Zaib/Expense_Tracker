import '../repositories/auth_repository.dart';

class Logout {
  final AuthRepository _repo;

  const Logout(this._repo);

  Future<void> call() => _repo.logout();
}

