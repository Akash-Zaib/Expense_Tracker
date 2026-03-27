import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/user_profile_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _local;
  final SettingsRemoteDataSource _remote;

  const SettingsRepositoryImpl(this._local, this._remote);

  @override
  Future<UserProfileEntity> getUserProfile() async {
    final localProfile = await _local.getUserProfile();
    try {
      final remoteProfile = await _remote.getUserProfile();
      if (remoteProfile != null) {
        await _local.saveUserProfile(remoteProfile);
        return remoteProfile;
      }
    } catch (_) {
      // Fallback to local cache.
    }
    return localProfile;
  }

  @override
  Future<void> saveUserProfile(UserProfileEntity profile) async {
    final model = UserProfileModel(
      name: profile.name,
      email: profile.email,
      signatureColorValue: profile.signatureColorValue,
    );
    try {
      await _remote.saveUserProfile(model);
    } on SignatureColorTakenException {
      rethrow;
    } catch (_) {
      // Still persist local cache for offline behavior.
    }
    await _local.saveUserProfile(model);
  }
}
