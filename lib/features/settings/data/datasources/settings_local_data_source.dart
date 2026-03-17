import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../models/user_profile_model.dart';

abstract class SettingsLocalDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<void> saveUserProfile(UserProfileModel profile);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const _kName = 'settings_profile_name';
  static const _kEmail = 'settings_profile_email';
  static const _kSignatureColor = 'settings_profile_signature_color';

  final SharedPreferences _prefs;

  const SettingsLocalDataSourceImpl(this._prefs);

  UserProfileModel _defaultProfile() {
    return const UserProfileModel(
      name: 'You',
      email: 'user@alnoortraders.com',
      signatureColorValue: AppColors.primaryValue,
    );
  }

  @override
  Future<UserProfileModel> getUserProfile() async {
    final fallback = _defaultProfile();
    return UserProfileModel.fromStorage(
      name: _prefs.getString(_kName),
      email: _prefs.getString(_kEmail),
      signatureColorValue: _prefs.getInt(_kSignatureColor),
      fallback: fallback,
    );
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _prefs.setString(_kName, profile.name);
    await _prefs.setString(_kEmail, profile.email);
    await _prefs.setInt(_kSignatureColor, profile.signatureColorValue);
  }
}

