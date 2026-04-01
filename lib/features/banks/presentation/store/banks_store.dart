import 'package:flutter/foundation.dart';

import '../../domain/entities/bank.dart';
import '../../domain/usecases/add_bank.dart';
import '../../domain/usecases/add_bank_for_uid.dart';
import '../../domain/usecases/get_banks.dart';
import '../../domain/usecases/remove_bank.dart';
import '../../domain/usecases/submit_all_banks.dart';
import '../../domain/usecases/watch_banks.dart';
import '../../../../core/firebase/current_user_context.dart';
import 'dart:async';

class BanksStore extends ChangeNotifier {
  final GetBanks getBanks;
  final AddBank addBank;
  final AddBankForUid addBankForUid;
  final RemoveBank removeBank;
  final SubmitAllBanks submitAllBanks;
  final WatchBanks watchBanks;
  final CurrentUserContext _currentUserContext;
  StreamSubscription<List<Bank>>? _watchSub;
  bool _watching = false;

  BanksStore({
    required GetBanks getBanks,
    required AddBank addBank,
    required AddBankForUid addBankForUid,
    required RemoveBank removeBank,
    required SubmitAllBanks submitAllBanks,
    required WatchBanks watchBanks,
    required CurrentUserContext currentUserContext,
  })  : getBanks = getBanks,
        addBank = addBank,
        addBankForUid = addBankForUid,
        removeBank = removeBank,
        submitAllBanks = submitAllBanks,
        watchBanks = watchBanks,
        _currentUserContext = currentUserContext;

  final List<Bank> _banks = [];
  bool _loaded = false;

  List<Bank> get banks => List.unmodifiable(_banks);
  bool get loaded => _loaded;
  bool get watching => _watching;

  void startWatching() {
    _watching = true;
    _watchSub?.cancel();
    _watchSub = watchBanks().listen(
      (items) {
        _banks
          ..clear()
          ..addAll(items);
        _loaded = true;
        notifyListeners();
      },
      onError: (_) async {
        // Keep app responsive even if stream errors temporarily.
        await load();
      },
    );
  }

  void stopWatching() {
    _watching = false;
    _watchSub?.cancel();
    _watchSub = null;
  }

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

    return addNewForOwner(
      ownerUid: _currentUserContext.uid,
      ownerName: _currentUserContext.auth.currentUser?.displayName?.trim().isNotEmpty == true
          ? _currentUserContext.auth.currentUser!.displayName!.trim()
          : 'User',
      name: normalizedName,
      accountNumber: normalizedAcc,
    );
  }

  Future<void> addNewForOwner({
    required String ownerUid,
    required String ownerName,
    required String name,
    String? accountNumber,
  }) async {
    final normalizedName = name.trim();
    final normalizedAcc = accountNumber?.trim();

    if (normalizedName.isEmpty) return;

    final bank = Bank(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalizedName,
      accountNumber: (normalizedAcc == null || normalizedAcc.isEmpty)
          ? null
          : normalizedAcc,
      // No "Submit" UI: banks should be usable immediately.
      isSubmitted: true,
      // We store the bank under the currently logged-in user (for Firebase
      // write permissions), but mark the bank's "belongs to" via ownerName.
      ownerUid: _currentUserContext.uid,
      ownerName: ownerName.trim().isNotEmpty ? ownerName.trim() : 'User',
    );

    // Write under current user's subcollection (avoid cross-user write rules).
    await addBank(bank);
    _banks.insert(0, bank);
    notifyListeners();
  }

  Future<void> deleteBank(Bank bank) async {
    await removeBank(bank);
    _banks.removeWhere(
      (b) => b.id == bank.id && b.ownerUid == bank.ownerUid,
    );
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
        ownerUid: b.ownerUid,
        ownerName: b.ownerName,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _watchSub?.cancel();
    super.dispose();
  }
}

