import 'package:firebase_auth/firebase_auth.dart';

import 'users_directory_data_source.dart';

class CurrentUserContext {
  final FirebaseAuth auth;
  final UsersDirectoryDataSource usersDirectory;

  const CurrentUserContext({required this.auth, required this.usersDirectory});

  String get uid {
    final current = auth.currentUser;
    if (current == null || current.uid.trim().isEmpty) {
      throw StateError('User is not authenticated.');
    }
    return current.uid;
  }

  Future<String> resolvedName() async {
    final current = auth.currentUser;
    if (current == null) return 'User';
    final fromAuth = current.displayName?.trim();
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    final profiles = await usersDirectory.getAllProfilesByUid();
    return profiles[current.uid]?.name ?? 'User';
  }
}
