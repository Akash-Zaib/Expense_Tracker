import '../entities/expense_entry.dart';
import '../repositories/expense_repository.dart';

class AddTransactionForUid {
  final ExpenseRepository repository;

  const AddTransactionForUid(this.repository);

  Future<void> call({
    required String uid,
    required ExpenseEntry entry,
  }) {
    return repository.addTransactionForUid(uid: uid, entry: entry);
  }
}

