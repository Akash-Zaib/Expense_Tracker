import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/firebase/firestore_user_scope.dart';
import '../models/bank_model.dart';

abstract class BanksRemoteDataSource {
  Future<List<BankModel>> getBanks();
  Future<void> addBank(BankModel bank);
  Future<void> removeBank(String id);
  Future<void> submitAllBanks();
}

class BanksRemoteDataSourceImpl implements BanksRemoteDataSource {
  final FirestoreUserScope _userScope;

  const BanksRemoteDataSourceImpl(this._userScope);

  @override
  Future<List<BankModel>> getBanks() async {
    final snapshot = await _userScope
        .banksCollection()
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => BankModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList(growable: false);
  }

  @override
  Future<void> addBank(BankModel bank) {
    final uid = _userScope.requiredUid;
    final ownerName = _userScope.auth.currentUser?.displayName?.trim();
    return _userScope.banksCollection().doc(bank.id).set({
      'name': bank.name,
      'accountNumber': bank.accountNumber,
      'isSubmitted': bank.isSubmitted,
      'ownerUid': uid,
      'ownerName': (ownerName == null || ownerName.isEmpty)
          ? 'User'
          : ownerName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeBank(String id) {
    return _userScope.banksCollection().doc(id).delete();
  }

  @override
  Future<void> submitAllBanks() async {
    final snapshot = await _userScope.banksCollection().get();
    final batch = _userScope.firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isSubmitted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
