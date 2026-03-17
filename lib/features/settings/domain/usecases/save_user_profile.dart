import '../entities/user_profile_entity.dart';
import '../repositories/settings_repository.dart';

class SaveUserProfile {
  final SettingsRepository _repo;

  const SaveUserProfile(this._repo);

  Future<void> call(UserProfileEntity profile) => _repo.saveUserProfile(profile);
}

