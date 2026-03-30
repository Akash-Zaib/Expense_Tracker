import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/firebase/current_user_context.dart';
import '../models/user_profile_model.dart';

abstract class SettingsLocalDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<void> saveUserProfile(UserProfileModel profile);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const _kNameBase = 'settings_profile_name';
  static const _kEmailBase = 'settings_profile_email';
  static const _kSignatureColorBase = 'settings_profile_signature_color';

  final SharedPreferences _prefs;
  final CurrentUserContext _currentUserContext;

  const SettingsLocalDataSourceImpl(this._prefs, this._currentUserContext);

  String? _uidOrNull() {
    try {
      return _currentUserContext.uid;
    } catch (_) {
      return null;
    }
  }

  String? _keyOrNull(String baseKey) {
    final uid = _uidOrNull();
    if (uid == null || uid.trim().isEmpty) return null;
    return '$baseKey.$uid';
  }

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

    final nameKey = _keyOrNull(_kNameBase);
    final emailKey = _keyOrNull(_kEmailBase);
    final sigKey = _keyOrNull(_kSignatureColorBase);

    if (nameKey == null || emailKey == null || sigKey == null) {
      return fallback;
    }

    return UserProfileModel.fromStorage(
      name: _prefs.getString(nameKey),
      email: _prefs.getString(emailKey),
      signatureColorValue: _prefs.getInt(sigKey),
      fallback: fallback,
    );
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    final nameKey = _keyOrNull(_kNameBase);
    final emailKey = _keyOrNull(_kEmailBase);
    final sigKey = _keyOrNull(_kSignatureColorBase);

    if (nameKey == null || emailKey == null || sigKey == null) return;

    await _prefs.setString(nameKey, profile.name);
    await _prefs.setString(emailKey, profile.email);
    await _prefs.setInt(sigKey, profile.signatureColorValue);
  }
}

