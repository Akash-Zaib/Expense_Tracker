import '../../domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.name,
    required super.email,
    required super.signatureColorValue,
  });

  factory UserProfileModel.fromStorage({
    required String? name,
    required String? email,
    required int? signatureColorValue,
    required UserProfileModel fallback,
  }) {
    return UserProfileModel(
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : fallback.name,
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : fallback.email,
      signatureColorValue: signatureColorValue ?? fallback.signatureColorValue,
    );
  }
}

