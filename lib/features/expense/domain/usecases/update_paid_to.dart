import '../repositories/expense_repository.dart';

class UpdatePaidTo {
  final ExpenseRepository _repository;

  const UpdatePaidTo(this._repository);

  Future<void> call({
    required String transactionId,
    required String paidTo,
  }) {
    return _repository.updatePaidTo(
      transactionId: transactionId,
      paidTo: paidTo,
    );
  }
}
