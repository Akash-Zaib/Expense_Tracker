import '../entities/expense_entry.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntry>> getTransactions({int limit = 200});
  Future<void> addTransaction(ExpenseEntry entry);
  Future<void> addTransactionForUid({
    required String uid,
    required ExpenseEntry entry,
  });
  Future<void> splitAndAssign({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required double sourceNewAmount,
    required String targetUid,
    required ExpenseEntry targetEntry,
  });
  Future<void> moveToUser({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required String targetUid,
    required ExpenseEntry targetEntry,
  });
  Future<void> updatePaidTo({
    required String transactionId,
    required String paidTo,
  });
  Future<void> updateAmount({
    required String ownerUid,
    required String transactionId,
    required double amount,
  });
}
