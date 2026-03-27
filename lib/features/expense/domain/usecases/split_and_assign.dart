import '../entities/expense_entry.dart';
import '../repositories/expense_repository.dart';

class SplitAndAssign {
  final ExpenseRepository repository;

  const SplitAndAssign(this.repository);

  Future<void> call({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required double sourceNewAmount,
    required String targetUid,
    required ExpenseEntry targetEntry,
  }) {
    return repository.splitAndAssign(
      sourceOwnerUid: sourceOwnerUid,
      sourceTransactionId: sourceTransactionId,
      sourceNewAmount: sourceNewAmount,
      targetUid: targetUid,
      targetEntry: targetEntry,
    );
  }
}

