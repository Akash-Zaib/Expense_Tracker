import 'package:flutter/material.dart';

import '../../domain/entities/expense_entry.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/move_transaction_to_user.dart';
import '../../domain/usecases/split_and_assign.dart';
import '../../domain/usecases/update_paid_to.dart';

class TransactionsStore extends ChangeNotifier {
  final GetTransactions _getTransactions;
  final AddTransaction _addTransaction;
  final UpdatePaidTo _updatePaidTo;
  final SplitAndAssign _splitAndAssign;
  final MoveTransactionToUser _moveTransactionToUser;

  TransactionsStore({
    required GetTransactions getTransactions,
    required AddTransaction addTransaction,
    required UpdatePaidTo updatePaidTo,
    required SplitAndAssign splitAndAssign,
    required MoveTransactionToUser moveTransactionToUser,
  }) : _getTransactions = getTransactions,
       _addTransaction = addTransaction,
       _updatePaidTo = updatePaidTo,
       _splitAndAssign = splitAndAssign,
       _moveTransactionToUser = moveTransactionToUser;

  final List<ExpenseEntry> _transactions = [];
  bool _loading = false;
  String? _error;

  List<ExpenseEntry> get transactions => List.unmodifiable(_transactions);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({int limit = 200, bool force = false}) async {
    if (_loading) return;
    if (!force && _transactions.isNotEmpty) return;
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final items = await _getTransactions(limit: limit);
      _transactions
        ..clear()
        ..addAll(items);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> add(ExpenseEntry entry) async {
    _error = null;
    notifyListeners();
    try {
      await _addTransaction(entry);
      // Reload to get the stored document IDs from Firestore.
      await load(force: true);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> reassignPaidTo({
    required String transactionId,
    required String paidTo,
  }) async {
    _error = null;
    notifyListeners();
    try {
      await _updatePaidTo(transactionId: transactionId, paidTo: paidTo);
      final idx = _transactions.indexWhere((t) => t.id == transactionId);
      if (idx >= 0) {
        final old = _transactions[idx];
        _transactions[idx] = ExpenseEntry(
          id: old.id,
          description: old.description,
          amount: old.amount,
          category: old.category,
          date: old.date,
          time: old.time,
          paidBy: old.paidBy,
          addedBy: old.addedBy,
          ownerUid: old.ownerUid,
          ownerName: old.ownerName,
          paidTo: paidTo,
          bankName: old.bankName,
          kind: old.kind,
          isCredit: old.isCredit,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> splitAndAssign({
    required ExpenseEntry entry,
    required String targetUid,
    required String targetName,
    required double amount,
    required String currentUserName,
    required String currentUserUid,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final remaining = entry.amount - amount;
      if (remaining <= 0) {
        throw StateError('Split amount must be less than original amount.');
      }

      final now = DateTime.now();
      final newEntry = ExpenseEntry(
        description: entry.description,
        amount: amount,
        category: entry.category,
        date: entry.date,
        time: TimeOfDay.fromDateTime(now),
        paidBy: currentUserName,
        addedBy: currentUserName,
        ownerUid: targetUid,
        ownerName: targetName,
        paidTo: targetName,
        bankName: entry.bankName,
        kind: ExpenseEntryKind.expense,
        isCredit: false,
      );

      await _splitAndAssign(
        sourceOwnerUid: currentUserUid,
        sourceTransactionId: entry.id,
        sourceNewAmount: remaining,
        targetUid: targetUid,
        targetEntry: newEntry,
      );

      await load(force: true);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> moveFullAmountToUser({
    required ExpenseEntry entry,
    required String targetUid,
    required String targetName,
    required String currentUserName,
    required String currentUserUid,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final newEntry = ExpenseEntry(
        description: entry.description,
        amount: entry.amount,
        category: entry.category,
        date: entry.date,
        time: TimeOfDay.fromDateTime(now),
        paidBy: currentUserName,
        addedBy: currentUserName,
        ownerUid: targetUid,
        ownerName: targetName,
        paidTo: targetName,
        bankName: entry.bankName,
        kind: ExpenseEntryKind.expense,
        isCredit: false,
      );

      await _moveTransactionToUser(
        sourceOwnerUid: currentUserUid,
        sourceTransactionId: entry.id,
        targetUid: targetUid,
        targetEntry: newEntry,
      );

      await load(force: true);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
  }

  void seedIfEmpty(List<ExpenseEntry> initial) {
    // Backward-compatible fallback for screens that still expect local seed.
    if (_transactions.isNotEmpty || initial.isEmpty) return;
    _transactions
      ..clear()
      ..addAll(initial);
    notifyListeners();
  }
}
