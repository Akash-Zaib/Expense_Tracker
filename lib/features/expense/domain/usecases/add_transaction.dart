import '../entities/expense_entry.dart';
import '../repositories/expense_repository.dart';

class AddTransaction {
  final ExpenseRepository repository;

  const AddTransaction(this.repository);

  Future<void> call(ExpenseEntry entry) {
    return repository.addTransaction(entry);
  }
}
