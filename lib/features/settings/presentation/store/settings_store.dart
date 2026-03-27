import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/save_user_profile.dart';

class SettingsStore extends ChangeNotifier {
  final GetUserProfile getUserProfile;
  final SaveUserProfile saveUserProfile;

  SettingsStore({required this.getUserProfile, required this.saveUserProfile});

  bool _loading = false;
  bool get loading => _loading;

  UserProfileEntity? _profile;
  UserProfileEntity? get profile => _profile;
  String? _error;
  String? get error => _error;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _profile = await getUserProfile();
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required int signatureColorValue,
  }) async {
    final current = _profile;
    if (current == null) return false;

    final updated = UserProfileEntity(
      name: name.trim().isEmpty ? current.name : name.trim(),
      email: current.email,
      signatureColorValue: signatureColorValue,
    );
    final previous = _profile;
    _profile = updated;
    _error = null;
    notifyListeners();
    try {
      await saveUserProfile(updated);
      return true;
    } catch (e) {
      _profile = previous;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
