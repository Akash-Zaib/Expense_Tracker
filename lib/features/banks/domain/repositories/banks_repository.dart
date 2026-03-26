import '../entities/bank.dart';

abstract class BanksRepository {
  /// Local now (SharedPreferences). Later replace implementation with Firebase:
  /// - Firestore path: `workspaces/{workspaceId}/banks/{bankId}`
  /// - Security: allow only workspace members to read/write
  Future<List<Bank>> getBanks();

  /// Firebase later: `set()` bank doc under the workspace.
  Future<void> addBank(Bank bank);

  /// Firebase later: `delete()` bank doc. If using `isSubmitted`, you can
  /// enforce “cannot delete after submit” in Firestore rules too.
  Future<void> removeBank(String id);

  /// Firebase later: batch update all bank docs `isSubmitted=true`.
  Future<void> submitAllBanks();
}

