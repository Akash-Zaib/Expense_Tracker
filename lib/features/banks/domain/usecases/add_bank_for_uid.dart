import '../entities/bank.dart';
import '../repositories/banks_repository.dart';

class AddBankForUid {
  final BanksRepository _repository;

  const AddBankForUid(this._repository);

  Future<void> call({
    required String ownerUid,
    required Bank bank,
  }) {
    return _repository.addBankForUid(ownerUid: ownerUid, bank: bank);
  }
}

