import '../entities/bank.dart';
import '../repositories/banks_repository.dart';

class RemoveBank {
  final BanksRepository repository;

  const RemoveBank(this.repository);

  Future<void> call(Bank bank) => repository.removeBank(bank);
}

