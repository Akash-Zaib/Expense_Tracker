import '../entities/bank.dart';
import '../repositories/banks_repository.dart';

class GetBanks {
  final BanksRepository repository;

  const GetBanks(this.repository);

  Future<List<Bank>> call() => repository.getBanks();
}

