import 'package:cloud_firestore/cloud_firestore.dart';

class UserDirectoryProfile {
  final String uid;
  final String name;
  final String email;
  final int signatureColorValue;

  const UserDirectoryProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.signatureColorValue,
  });
}

class UsersDirectoryDataSource {
  final FirebaseFirestore firestore;

  const UsersDirectoryDataSource(this.firestore);

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  Future<void> upsertUserProfile({
    required String uid,
    required String name,
    required String email,
    required int signatureColorValue,
  }) {
    return _users.doc(uid).set({
      'name': name,
      'email': email,
      'signatureColorValue': signatureColorValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, UserDirectoryProfile>> getAllProfilesByUid() async {
    final snapshot = await _users.get();
    final map = <String, UserDirectoryProfile>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] as String?)?.trim();
      final email = (data['email'] as String?)?.trim();
      if (name == null || name.isEmpty || email == null || email.isEmpty) {
        continue;
      }
      map[doc.id] = UserDirectoryProfile(
        uid: doc.id,
        name: name,
        email: email,
        signatureColorValue:
            (data['signatureColorValue'] as num?)?.toInt() ?? 0xFF0057FF,
      );
    }
    return map;
  }

  Future<bool> isSignatureColorTaken({
    required int signatureColorValue,
    String? excludeUid,
  }) async {
    final snapshot = await _users
        .where('signatureColorValue', isEqualTo: signatureColorValue)
        .limit(5)
        .get();
    for (final doc in snapshot.docs) {
      if (excludeUid != null && doc.id == excludeUid) continue;
      return true;
    }
    return false;
  }

  Future<int?> firstAvailableColor(List<int> palette) async {
    for (final value in palette) {
      final taken = await isSignatureColorTaken(signatureColorValue: value);
      if (!taken) return value;
    }
    return null;
  }
}
