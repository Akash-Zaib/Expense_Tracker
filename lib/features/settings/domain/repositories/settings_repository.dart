import '../entities/user_profile_entity.dart';

abstract class SettingsRepository {
  Future<UserProfileEntity> getUserProfile();
  Future<void> saveUserProfile(UserProfileEntity profile);
}

