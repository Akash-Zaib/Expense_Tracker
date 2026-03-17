import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';
import '../models/user_profile_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _local;

  const SettingsRepositoryImpl(this._local);

  @override
  Future<UserProfileEntity> getUserProfile() => _local.getUserProfile();

  @override
  Future<void> saveUserProfile(UserProfileEntity profile) {
    return _local.saveUserProfile(
      UserProfileModel(
        name: profile.name,
        email: profile.email,
        signatureColorValue: profile.signatureColorValue,
      ),
    );
  }
}

