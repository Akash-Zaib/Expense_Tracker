import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/firebase/firestore_user_scope.dart';
import '../models/bank_model.dart';

abstract class BanksRemoteDataSource {
  Future<List<BankModel>> getBanks();
  Future<void> addBank(BankModel bank);
  Future<void> addBankForUid({
    required String ownerUid,
    required BankModel bank,
  });
  Future<void> removeBank(String id);
  Future<void> submitAllBanks();
}

class BanksRemoteDataSourceImpl implements BanksRemoteDataSource {
  final FirestoreUserScope _userScope;

  const BanksRemoteDataSourceImpl(this._userScope);

  @override
  Future<List<BankModel>> getBanks() async {
    // Without permission to read other users' subcollections, we only read:
    //   users/{currentUid}/banks
    final snapshot = await _userScope.banksCollection().get();

    final currentName =
        _userScope.auth.currentUser?.displayName?.trim();
    final uid = _userScope.requiredUid;
    final fallbackOwnerName =
        (currentName != null && currentName.isNotEmpty) ? currentName : 'User';

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final ownerName =
          (data['ownerName'] ?? fallbackOwnerName).toString();

      // We do NOT rely on ownerUid existing in Firestore. Only ownerName is
      // stored as the "Belong to" string.
      return BankModel.fromJson({
        'id': doc.id,
        ...data,
        // If older docs missing `ownerUid`, infer it from the path we read.
        'ownerUid': (data['ownerUid'] ?? uid).toString(),
        'ownerName': ownerName,
      });
    }).toList(growable: false);
  }

  @override
  Future<void> addBank(BankModel bank) {
    final selectedOwnerName = bank.ownerName.trim();
    final ownerName = selectedOwnerName.isNotEmpty
        ? selectedOwnerName
        : _userScope.auth.currentUser?.displayName?.trim();
    final uid = _userScope.requiredUid;
    return _userScope.banksCollection().doc(bank.id).set({
      'name': bank.name,
      'accountNumber': bank.accountNumber,
      'isSubmitted': bank.isSubmitted,
      // Required for your current security rules (kept internal).
      'ownerUid': uid,
      'ownerName': (ownerName == null || ownerName.isEmpty)
          ? 'User'
          : ownerName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addBankForUid({
    required String ownerUid,
    required BankModel bank,
  }) {
    // Write under the chosen user's subcollection, but store only ownerName
    // (string) in the document to avoid needing UUID in the doc payload.
    final ownerName = bank.ownerName.trim().isNotEmpty ? bank.ownerName : 'User';
    return _userScope.firestore
        .collection('users')
        .doc(ownerUid)
        .collection('banks')
        .doc(bank.id)
        .set({
      'name': bank.name,
      'accountNumber': bank.accountNumber,
      'isSubmitted': bank.isSubmitted,
      // Stored for rule checks.
      'ownerUid': ownerUid,
      'ownerName': ownerName,
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
