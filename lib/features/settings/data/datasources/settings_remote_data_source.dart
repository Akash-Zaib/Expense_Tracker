import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/firebase/firestore_user_scope.dart';
import '../models/user_profile_model.dart';

class SignatureColorTakenException implements Exception {
  final String message;

  const SignatureColorTakenException(this.message);

  @override
  String toString() => message;
}

abstract class SettingsRemoteDataSource {
  Future<UserProfileModel?> getUserProfile();
  Future<void> saveUserProfile(UserProfileModel profile);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirestoreUserScope _userScope;

  const SettingsRemoteDataSourceImpl(this._userScope);

  @override
  Future<UserProfileModel?> getUserProfile() async {
    final snapshot = await _userScope.userDoc().get();
    final data = snapshot.data();
    if (data == null) return null;

    final name = (data['name'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();
    final signatureColorValue = (data['signatureColorValue'] as num?)?.toInt();
    if (name == null || name.isEmpty || email == null || email.isEmpty) {
      return null;
    }
    return UserProfileModel(
      name: name,
      email: email,
      signatureColorValue: signatureColorValue ?? AppColors.primaryValue,
    );
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    final uid = _userScope.requiredUid;
    final duplicate = await _userScope.firestore
        .collection('users')
        .where('signatureColorValue', isEqualTo: profile.signatureColorValue)
        .limit(5)
        .get();

    final takenByAnother = duplicate.docs.any((doc) => doc.id != uid);
    if (takenByAnother) {
      throw const SignatureColorTakenException(
        'This color is already selected by another user.',
      );
    }

    await _userScope.userDoc().set({
      'name': profile.name,
      'email': profile.email,
      'signatureColorValue': profile.signatureColorValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
