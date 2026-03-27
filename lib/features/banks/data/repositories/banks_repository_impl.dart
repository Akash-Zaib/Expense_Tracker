import '../../domain/entities/bank.dart';
import '../../domain/repositories/banks_repository.dart';
import '../datasources/banks_local_data_source.dart';
import '../datasources/banks_remote_data_source.dart';
import '../models/bank_model.dart';

class BanksRepositoryImpl implements BanksRepository {
  final BanksLocalDataSource localDataSource;
  final BanksRemoteDataSource remoteDataSource;

  const BanksRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Future<List<Bank>> getBanks() async {
    try {
      final remote = await remoteDataSource.getBanks();
      await localDataSource.saveBanks(remote);
      return remote;
    } catch (_) {
      return localDataSource.getBanks();
    }
  }

  @override
  Future<void> addBank(Bank bank) async {
    final model = BankModel(
      id: bank.id,
      name: bank.name,
      accountNumber: bank.accountNumber,
      isSubmitted: bank.isSubmitted,
    );
    try {
      await remoteDataSource.addBank(model);
    } catch (_) {
      // Keep local write so UX still works while offline.
    }
    final current = await localDataSource.getBanks();
    await localDataSource.saveBanks([
      model,
      ...current.where((b) => b.id != bank.id),
    ]);
  }

  @override
  Future<void> removeBank(String id) async {
    try {
      await remoteDataSource.removeBank(id);
    } catch (_) {
      // Continue local delete if remote is unavailable.
    }
    final current = await localDataSource.getBanks();
    final updated = current.where((b) => b.id != id).toList(growable: false);
    await localDataSource.saveBanks(updated);
  }

  @override
  Future<void> submitAllBanks() async {
    try {
      await remoteDataSource.submitAllBanks();
    } catch (_) {
      // Keep local submission state if remote fails.
    }
    final current = await localDataSource.getBanks();
    final updated = current
        .map((b) => b.copyWith(isSubmitted: true))
        .toList(growable: false);
    await localDataSource.saveBanks(updated);
  }
}
