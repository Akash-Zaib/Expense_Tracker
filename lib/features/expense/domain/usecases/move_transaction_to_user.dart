import '../entities/expense_entry.dart';
import '../repositories/expense_repository.dart';

class MoveTransactionToUser {
  final ExpenseRepository repository;

  const MoveTransactionToUser(this.repository);

  Future<void> call({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required String targetUid,
    required ExpenseEntry targetEntry,
  }) {
    return repository.moveToUser(
      sourceOwnerUid: sourceOwnerUid,
      sourceTransactionId: sourceTransactionId,
      targetUid: targetUid,
      targetEntry: targetEntry,
    );
  }
}

