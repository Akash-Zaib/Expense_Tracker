import 'package:flutter/foundation.dart';

import '../../domain/entities/bank.dart';
import '../../domain/usecases/add_bank.dart';
import '../../domain/usecases/get_banks.dart';
import '../../domain/usecases/remove_bank.dart';
import '../../domain/usecases/submit_all_banks.dart';

class BanksStore extends ChangeNotifier {
  final GetBanks getBanks;
  final AddBank addBank;
  final RemoveBank removeBank;
  final SubmitAllBanks submitAllBanks;

  BanksStore({
    required this.getBanks,
    required this.addBank,
    required this.removeBank,
    required this.submitAllBanks,
  });

  final List<Bank> _banks = [];
  bool _loaded = false;

  List<Bank> get banks => List.unmodifiable(_banks);
  bool get loaded => _loaded;

  Future<void> load() async {
    final items = await getBanks();
    _banks
      ..clear()
      ..addAll(items);
    _loaded = true;
    notifyListeners();
  }

  Future<void> addNew({
    required String name,
    String? accountNumber,
  }) async {
    final normalizedName = name.trim();
    final normalizedAcc = accountNumber?.trim();

    if (normalizedName.isEmpty) return;

    final bank = Bank(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalizedName,
      accountNumber: (normalizedAcc == null || normalizedAcc.isEmpty) ? null : normalizedAcc,
      isSubmitted: false,
    );

    await addBank(bank);
    _banks.insert(0, bank);
    notifyListeners();
  }

  Future<void> removeById(String id) async {
    final Bank? bank = _banks.where((b) => b.id == id).isEmpty
        ? null
        : _banks.firstWhere((b) => b.id == id);
    if (bank == null) return;
    if (bank.isSubmitted) return;

    await removeBank(id);
    _banks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<void> submitAll() async {
    await submitAllBanks();
    for (var i = 0; i < _banks.length; i++) {
      final b = _banks[i];
      _banks[i] = Bank(
        id: b.id,
        name: b.name,
        accountNumber: b.accountNumber,
        isSubmitted: true,
      );
    }
    notifyListeners();
  }
}

