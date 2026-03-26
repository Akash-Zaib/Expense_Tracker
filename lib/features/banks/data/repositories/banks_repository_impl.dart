import '../../domain/entities/bank.dart';
import '../../domain/repositories/banks_repository.dart';
import '../datasources/banks_local_data_source.dart';
import '../models/bank_model.dart';

class BanksRepositoryImpl implements BanksRepository {
  final BanksLocalDataSource localDataSource;

  const BanksRepositoryImpl(this.localDataSource);

  @override
  Future<List<Bank>> getBanks() async {
    // TODO(firebase): replace with Firestore query:
    // `workspaces/{workspaceId}/banks` (orderBy createdAt if needed)
    return localDataSource.getBanks();
  }

  @override
  Future<void> addBank(Bank bank) async {
    // TODO(firebase): replace with `set()`:
    // `workspaces/{workspaceId}/banks/{bank.id}`
    final current = await localDataSource.getBanks();
    final updated = <BankModel>[
      BankModel(id: bank.id, name: bank.name, accountNumber: bank.accountNumber),
      ...current.where((b) => b.id != bank.id),
    ];
    await localDataSource.saveBanks(updated);
  }

  @override
  Future<void> removeBank(String id) async {
    // TODO(firebase): replace with `delete()`:
    // `workspaces/{workspaceId}/banks/{id}`
    final current = await localDataSource.getBanks();
    final updated = current.where((b) => b.id != id).toList(growable: false);
    await localDataSource.saveBanks(updated);
  }

  @override
  Future<void> submitAllBanks() async {
    // TODO(firebase): replace with a batch write to update:
    // `isSubmitted=true` for all docs in `workspaces/{workspaceId}/banks`
    final current = await localDataSource.getBanks();
    final updated = current.map((b) => b.copyWith(isSubmitted: true)).toList(growable: false);
    await localDataSource.saveBanks(updated);
  }
}

