import '../entities/bank.dart';
import '../repositories/banks_repository.dart';

class WatchBanks {
  final BanksRepository repository;

  const WatchBanks(this.repository);

  Stream<List<Bank>> call() => repository.watchBanks();
}
