import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/firebase/firestore_user_scope.dart';
import '../../domain/entities/bank.dart';
import '../models/bank_model.dart';

abstract class BanksRemoteDataSource {
  Future<List<BankModel>> getBanks();
  Future<void> addBank(BankModel bank);
  Future<void> addBankForUid({
    required String ownerUid,
    required BankModel bank,
  });
  Future<void> removeBank(Bank bank);
  Future<void> submitAllBanks();
}

class BanksRemoteDataSourceImpl implements BanksRemoteDataSource {
  final FirestoreUserScope _userScope;

  const BanksRemoteDataSourceImpl(this._userScope);

  @override
  Future<List<BankModel>> getBanks() async {
    // All `users/{uid}/banks` subcollections (requires global read on banks).
    final snapshot =
        await _userScope.firestore.collectionGroup('banks').get();

    final currentName =
        _userScope.auth.currentUser?.displayName?.trim();
    final fallbackOwnerName =
        (currentName != null && currentName.isNotEmpty) ? currentName : 'User';

    final list = snapshot.docs.where((doc) {
      final parts = doc.reference.path.split('/');
      return parts.length >= 4 &&
          parts[0] == 'users' &&
          parts[2] == 'banks';
    }).map((doc) {
      final pathParts = doc.reference.path.split('/');
      final pathUid = pathParts[1];
      final data = doc.data();
      final ownerNameRaw = (data['ownerName'] ?? '').toString().trim();
      final ownerName =
          ownerNameRaw.isNotEmpty ? ownerNameRaw : fallbackOwnerName;

      return BankModel.fromJson({
        'id': doc.id,
        ...data,
        // Path owner: whose `users/{uid}/banks` this doc lives under (delete + filters).
        'ownerUid': pathUid,
        'ownerName': ownerName,
      });
    }).toList(growable: true);

    list.sort((a, b) {
      final byOwner =
          a.ownerName.toLowerCase().compareTo(b.ownerName.toLowerCase());
      if (byOwner != 0) return byOwner;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
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
  Future<void> removeBank(Bank bank) {
    return _userScope.firestore
        .collection('users')
        .doc(bank.ownerUid)
        .collection('banks')
        .doc(bank.id)
        .delete();
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
