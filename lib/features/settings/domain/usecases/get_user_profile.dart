import '../entities/user_profile_entity.dart';
import '../repositories/settings_repository.dart';

class GetUserProfile {
  final SettingsRepository _repo;

  const GetUserProfile(this._repo);

  Future<UserProfileEntity> call() => _repo.getUserProfile();
}

