import '../entities/expense_entry.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntry>> getTransactions({int limit = 200});
  Future<void> addTransaction(ExpenseEntry entry);
  Future<void> updatePaidTo({
    required String transactionId,
    required String paidTo,
  });
}
