import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/current_user_context.dart';
import '../../domain/entities/expense_entry.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/move_transaction_to_user.dart';
import '../../domain/usecases/split_and_assign.dart';
import '../../domain/usecases/update_paid_to.dart';
import '../../domain/repositories/expense_repository.dart';

class TransactionsStore extends ChangeNotifier {
  final GetTransactions _getTransactions;
  final AddTransaction _addTransaction;
  final UpdatePaidTo _updatePaidTo;
  final SplitAndAssign _splitAndAssign;
  final MoveTransactionToUser _moveTransactionToUser;
  final CurrentUserContext _currentUserContext;
  final ExpenseRepository _repository;
  static const _logTag = '[TransactionsStore]';

  /// Tracks which UID `_transactions` belongs to (to avoid cross-user leakage).
  String? _loadedForUid;

  TransactionsStore({
    required GetTransactions getTransactions,
    required AddTransaction addTransaction,
    required UpdatePaidTo updatePaidTo,
    required SplitAndAssign splitAndAssign,
    required MoveTransactionToUser moveTransactionToUser,
    required CurrentUserContext currentUserContext,
    required ExpenseRepository repository,
  }) : _getTransactions = getTransactions,
       _addTransaction = addTransaction,
       _updatePaidTo = updatePaidTo,
       _splitAndAssign = splitAndAssign,
       _moveTransactionToUser = moveTransactionToUser,
       _currentUserContext = currentUserContext,
       _repository = repository;

  final List<ExpenseEntry> _transactions = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<ExpenseEntry>>? _watchSub;
  Timer? _fallbackPollTimer;
  Timer? _watchRetryTimer;
  int _watchLimit = 2000;
  bool _watching = false;
  Future<void>? _inFlightLoad;
  bool _pendingForceReload = false;
  int _pendingLimit = 200;

  List<ExpenseEntry> get transactions => List.unmodifiable(_transactions);
  bool get loading => _loading;
  String? get error => _error;
  bool get watching => _watching;

  void startWatching({int limit = 2000}) {
    _watchLimit = limit;
    _watching = true;
    _error = null;

    _watchSub?.cancel();
    _watchRetryTimer?.cancel();
    _watchSub = _repository
        .watchTransactions(limit: _watchLimit)
        .listen(
          (items) {
            debugPrint(
              '$_logTag watch success items=${items.length} limit=$_watchLimit',
            );
            _stopFallbackPolling();
            _transactions
              ..clear()
              ..addAll(items);
            _error = null;
            notifyListeners();
          },
          onError: (e, st) {
            debugPrint('$_logTag watch error=$e');
            debugPrintStack(
              stackTrace: st,
              label: '$_logTag watch error stack',
            );
            _error = e.toString();
            _startFallbackPolling();
            _scheduleWatchRetry();
            notifyListeners();
          },
        );
  }

  Future<void> stopWatching() async {
    _watching = false;
    _stopFallbackPolling();
    _watchRetryTimer?.cancel();
    _watchRetryTimer = null;
    await _watchSub?.cancel();
    _watchSub = null;
    notifyListeners();
  }

  Future<void> load({int limit = 200, bool force = false}) async {
    _pendingLimit = _pendingLimit > limit ? _pendingLimit : limit;
    final currentUid = _currentUserContext.uid;
    final uidChanged = _loadedForUid != null && _loadedForUid != currentUid;
    if (uidChanged) {
      _transactions.clear();
      _error = null;
      force = true;
    }
    _loadedForUid = currentUid;

    if (_loading) {
      if (force) _pendingForceReload = true;
      return _inFlightLoad ?? Future<void>.value();
    }
    if (!force && _transactions.isNotEmpty) return;
    _setLoading(true);
    _error = null;
    notifyListeners();

    _inFlightLoad = () async {
      try {
        final items = await _getTransactions(limit: limit);
        debugPrint(
          '$_logTag load success items=${items.length} limit=$limit force=$force',
        );
        if (force && items.isEmpty && _transactions.isNotEmpty) {
          debugPrint(
            '$_logTag load preserved existing=${_transactions.length} due to transient empty fetch',
          );
          _error = null;
          return;
        }
        _transactions
          ..clear()
          ..addAll(items);
        _error = null;
      } catch (e) {
        debugPrint('$_logTag load error=$e');
        _error = e.toString();
      } finally {
        _setLoading(false);
        notifyListeners();
      }
    }();

    await _inFlightLoad;
    _inFlightLoad = null;

    if (_pendingForceReload) {
      final nextLimit = _pendingLimit;
      _pendingForceReload = false;
      _pendingLimit = 200;
      await load(limit: nextLimit, force: true);
    } else {
      _pendingLimit = 200;
    }
  }

  Future<void> add(ExpenseEntry entry) async {
    _error = null;
    notifyListeners();
    try {
      await _addTransaction(entry);
      // Always force reload so current screen refreshes immediately even if
      // realtime stream is delayed or temporarily failing.
      await load(limit: _watching ? _watchLimit : 200, force: true);
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

  void _startFallbackPolling() {
    if (!_watching || _fallbackPollTimer != null) return;
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      // Best-effort fallback while realtime listener is unavailable.
      load(limit: _watchLimit, force: true);
    });
  }

  void _stopFallbackPolling() {
    _fallbackPollTimer?.cancel();
    _fallbackPollTimer = null;
  }

  void _scheduleWatchRetry() {
    if (!_watching) return;
    _watchRetryTimer?.cancel();
    _watchRetryTimer = Timer(const Duration(seconds: 5), () {
      if (!_watching) return;
      startWatching(limit: _watchLimit);
    });
  }

  @override
  void dispose() {
    _fallbackPollTimer?.cancel();
    _watchRetryTimer?.cancel();
    _watchSub?.cancel();
    super.dispose();
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
