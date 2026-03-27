import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/firebase/firestore_user_scope.dart';
import '../models/expense_entry_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseEntryModel>> getTransactions({int limit = 200});
  Future<void> addTransaction(ExpenseEntryModel entry);
  Future<void> updatePaidTo({
    required String transactionId,
    required String paidTo,
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
  Future<void> addTransaction(ExpenseEntryModel entry) {
    return _userScope.transactionsCollection().add(entry.toFirestore());
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
}
