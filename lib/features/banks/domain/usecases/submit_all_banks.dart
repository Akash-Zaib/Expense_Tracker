import '../repositories/banks_repository.dart';

class SubmitAllBanks {
  final BanksRepository repository;

  const SubmitAllBanks(this.repository);

  Future<void> call() => repository.submitAllBanks();
}

