import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/firebase/firestore_user_scope.dart';
import '../models/expense_entry_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseEntryModel>> getTransactions({int limit = 200});
  Stream<List<ExpenseEntryModel>> watchTransactions({int limit = 200});
  Future<void> addTransaction(ExpenseEntryModel entry);
  Future<void> addTransactionForUid({
    required String uid,
    required ExpenseEntryModel entry,
  });
  Future<void> splitAndAssign({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required double sourceNewAmount,
    required String targetUid,
    required ExpenseEntryModel targetEntry,
  });
  Future<void> moveToUser({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required String targetUid,
    required ExpenseEntryModel targetEntry,
  });
  Future<void> updatePaidTo({
    required String transactionId,
    required String paidTo,
  });
  Future<void> updateAmount({
    required String ownerUid,
    required String transactionId,
    required double amount,
  });
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirestoreUserScope _userScope;

  const ExpenseRemoteDataSourceImpl(this._userScope);

  @override
  Future<List<ExpenseEntryModel>> getTransactions({int limit = 200}) async {
    final usersSnapshot = await _userScope.firestore.collection('users').get();
    if (usersSnapshot.docs.isEmpty) return const [];

    final transactionSnapshots = await Future.wait(
      usersSnapshot.docs.map(
        (userDoc) => userDoc.reference.collection('transactions').get(),
      ),
    );

    final items = transactionSnapshots
        .expand((snapshot) => snapshot.docs)
        .map((doc) => ExpenseEntryModel.fromFirestore(doc.data(), doc.id))
        .toList(growable: true);

    // Sort client-side to avoid depending on createdAt index/field presence.
    items.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return bMinutes.compareTo(aMinutes);
    });

    if (items.length > limit) {
      return items.take(limit).toList(growable: false);
    }
    return items;
  }

  @override
  Stream<List<ExpenseEntryModel>> watchTransactions({int limit = 200}) {
    // Use a collectionGroup query so all users' transactions are observed in one
    // real-time stream (multi-device sync).
    //
    // Keep the query index-friendly: stream all docs from the collection group
    // and apply ordering/limit client-side.
    return _userScope.firestore
        .collectionGroup('transactions')
        .snapshots()
        .map((snapshot) {
          final items =
              snapshot.docs
                  .map((doc) => ExpenseEntryModel.fromFirestore(doc.data(), doc.id))
                  .toList(growable: true);

          items.sort((a, b) {
            final dateCmp = b.date.compareTo(a.date);
            if (dateCmp != 0) return dateCmp;
            final aMinutes = a.time.hour * 60 + a.time.minute;
            final bMinutes = b.time.hour * 60 + b.time.minute;
            return bMinutes.compareTo(aMinutes);
          });

          if (items.length > limit) {
            return items.take(limit).toList(growable: false);
          }
          return items;
        });
  }

  @override
  Future<void> addTransaction(ExpenseEntryModel entry) {
    return _userScope.transactionsCollection().add(entry.toFirestore());
  }

  @override
  Future<void> addTransactionForUid({
    required String uid,
    required ExpenseEntryModel entry,
  }) {
    return _userScope.firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(entry.toFirestore());
  }

  @override
  Future<void> updatePaidTo({
    required String transactionId,
    required String paidTo,
  }) async {
    final usersSnapshot = await _userScope.firestore.collection('users').get();
    for (final userDoc in usersSnapshot.docs) {
      final ref = userDoc.reference.collection('transactions').doc(transactionId);
      final snap = await ref.get();
      if (!snap.exists) continue;
      await ref.update({
        'paidTo': paidTo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    throw StateError('Transaction not found for reassignment.');
  }

  @override
  Future<void> updateAmount({
    required String ownerUid,
    required String transactionId,
    required double amount,
  }) async {
    await _userScope.firestore
        .collection('users')
        .doc(ownerUid)
        .collection('transactions')
        .doc(transactionId)
        .update({
          'amount': amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> splitAndAssign({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required double sourceNewAmount,
    required String targetUid,
    required ExpenseEntryModel targetEntry,
  }) async {
    final sourceRef = _userScope.firestore
        .collection('users')
        .doc(sourceOwnerUid)
        .collection('transactions')
        .doc(sourceTransactionId);
    final targetRef = _userScope.firestore
        .collection('users')
        .doc(targetUid)
        .collection('transactions')
        .doc(); // new activity

    final batch = _userScope.firestore.batch();
    batch.update(sourceRef, {
      'amount': sourceNewAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(targetRef, targetEntry.toFirestore());
    await batch.commit();
  }

  @override
  Future<void> moveToUser({
    required String sourceOwnerUid,
    required String sourceTransactionId,
    required String targetUid,
    required ExpenseEntryModel targetEntry,
  }) async {
    final sourceRef = _userScope.firestore
        .collection('users')
        .doc(sourceOwnerUid)
        .collection('transactions')
        .doc(sourceTransactionId);
    final targetRef = _userScope.firestore
        .collection('users')
        .doc(targetUid)
        .collection('transactions')
        .doc(); // new activity

    final batch = _userScope.firestore.batch();
    batch.delete(sourceRef);
    batch.set(targetRef, targetEntry.toFirestore());
    await batch.commit();
  }
}
