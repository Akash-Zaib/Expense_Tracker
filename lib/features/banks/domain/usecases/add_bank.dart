import '../entities/bank.dart';
import '../repositories/banks_repository.dart';

class AddBank {
  final BanksRepository repository;

  const AddBank(this.repository);

  Future<void> call(Bank bank) => repository.addBank(bank);
}

