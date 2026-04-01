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
    // No local cache: always fetch from Firebase.
    return remoteDataSource.getBanks();
  }

  @override
  Stream<List<Bank>> watchBanks() {
    return remoteDataSource.watchBanks();
  }

  @override
  Future<void> addBank(Bank bank) async {
    final model = BankModel(
      id: bank.id,
      name: bank.name,
      accountNumber: bank.accountNumber,
      isSubmitted: bank.isSubmitted,
      ownerUid: bank.ownerUid,
      ownerName: bank.ownerName,
    );
    await remoteDataSource.addBank(model);
  }

  @override
  Future<void> addBankForUid({
    required String ownerUid,
    required Bank bank,
  }) async {
    final model = BankModel(
      id: bank.id,
      name: bank.name,
      accountNumber: bank.accountNumber,
      isSubmitted: bank.isSubmitted,
      ownerUid: ownerUid,
      ownerName: bank.ownerName,
    );
    await remoteDataSource.addBankForUid(ownerUid: ownerUid, bank: model);
  }

  @override
  Future<void> removeBank(Bank bank) async {
    await remoteDataSource.removeBank(bank);
  }

  @override
  Future<void> submitAllBanks() async {
    await remoteDataSource.submitAllBanks();
  }
}
