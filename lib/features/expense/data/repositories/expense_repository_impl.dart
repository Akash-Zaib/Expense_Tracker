import '../../domain/entities/expense_entry.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_data_source.dart';
import '../models/expense_entry_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remote;

  const ExpenseRepositoryImpl(this._remote);

  @override
  Future<List<ExpenseEntry>> getTransactions({int limit = 200}) {
    return _remote.getTransactions(limit: limit);
  }

  @override
  Future<void> addTransaction(ExpenseEntry entry) {
    return _remote.addTransaction(ExpenseEntryModel.fromEntity(entry));
  }

  @override
  Future<void> updatePaidTo({
    required String transactionId,
    required String paidTo,
  }) {
    return _remote.updatePaidTo(transactionId: transactionId, paidTo: paidTo);
  }
}
