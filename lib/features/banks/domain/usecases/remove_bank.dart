import '../repositories/banks_repository.dart';

class RemoveBank {
  final BanksRepository repository;

  const RemoveBank(this.repository);

  Future<void> call(String id) => repository.removeBank(id);
}

