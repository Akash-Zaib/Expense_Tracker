import '../entities/expense_entry.dart';
import '../repositories/expense_repository.dart';

class GetTransactions {
  final ExpenseRepository repository;

  const GetTransactions(this.repository);

  Future<List<ExpenseEntry>> call({int limit = 200}) {
    return repository.getTransactions(limit: limit);
  }
}
