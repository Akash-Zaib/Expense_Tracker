import 'package:flutter/foundation.dart';

import '../../domain/entities/expense_entry.dart';

class TransactionsStore extends ChangeNotifier {
  final List<ExpenseEntry> _transactions = [];

  List<ExpenseEntry> get transactions => List.unmodifiable(_transactions);

  void seedIfEmpty(List<ExpenseEntry> initial) {
    if (_transactions.isNotEmpty) return;
    _transactions
      ..clear()
      ..addAll(initial);
    notifyListeners();
  }

  void add(ExpenseEntry entry) {
    _transactions.insert(0, entry);
    notifyListeners();
  }
}

