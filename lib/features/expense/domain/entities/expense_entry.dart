import 'package:flutter/material.dart';

enum ExpenseEntryKind {
  expense,
  amountAdded,
}

class ExpenseEntry {
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final TimeOfDay time;
  final String paidBy;
  final String addedBy;
  final String? bankName;
  final ExpenseEntryKind kind;
  final bool isCredit; // true = green, false = red

  const ExpenseEntry({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.time,
    required this.paidBy,
    this.addedBy = 'You',
    this.bankName,
    this.kind = ExpenseEntryKind.expense,
    this.isCredit = false,
  });
}

