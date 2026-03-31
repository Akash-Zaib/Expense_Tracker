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
  Stream<List<ExpenseEntry>> watchTransactions({int limit = 200}) {
    return _remote.watchTransactions(limit: limit);
  }

  @override
  Future<void> addTransaction(ExpenseEntry entry) {
    return _remote.addTransaction(ExpenseEntryModel.fromEntity(entry));
  }

  @override
  Future<void> addTransactionForUid({
    required String uid,
    required ExpenseEntry entry,
  }) {
    return _remote.addTransactionForUid(
      uid: uid,
      entry: ExpenseEntryModel.fromEntity(entry),
    );
  }

  @override
  Future<void> updatePaidTo({
    required String transactionId,
    required String paidTo,
  }) {
    return _remote.updatePaidTo(transactionId: transactionId, paidTo: paidTo);
  }

  @override
  Future<void> updateAmount({
    required String ownerUid,
    required String transactionId,
    required double amount,
  }) {
    return _remote.updateAmount(
      ownerUid: ownerUid,
      transactionId: transactionId,
      amount: amount,
    );
  }

  @override
  Future<void> splitAndAssign({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required double sourceNewAmount,
    required String targetUid,
    required ExpenseEntry targetEntry,
  }) {
    return _remote.splitAndAssign(
      sourceOwnerUid: sourceOwnerUid,
      sourceTransactionId: sourceTransactionId,
      sourceNewAmount: sourceNewAmount,
      targetUid: targetUid,
      targetEntry: ExpenseEntryModel.fromEntity(targetEntry),
    );
  }

  @override
  Future<void> moveToUser({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required String targetUid,
    required ExpenseEntry targetEntry,
  }) {
    return _remote.moveToUser(
      sourceOwnerUid: sourceOwnerUid,
      sourceTransactionId: sourceTransactionId,
      targetUid: targetUid,
      targetEntry: ExpenseEntryModel.fromEntity(targetEntry),
    );
  }
}
