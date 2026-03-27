import '../repositories/expense_repository.dart';

class UpdateTransactionAmount {
  final ExpenseRepository repository;

  const UpdateTransactionAmount(this.repository);

  Future<void> call({
    required String ownerUid,
    required String transactionId,
    required double amount,
  }) {
    return repository.updateAmount(
      ownerUid: ownerUid,
      transactionId: transactionId,
      amount: amount,
    );
  }
}

