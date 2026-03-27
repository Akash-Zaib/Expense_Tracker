import 'package:flutter/material.dart';

enum ExpenseEntryKind { expense, amountAdded }

class ExpenseEntry {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final TimeOfDay time;
  final String paidBy;
  final String addedBy;
  final String ownerUid;
  final String ownerName;
  final String paidTo;
  final String? bankName;
  final ExpenseEntryKind kind;
  final bool isCredit; // true = green, false = red

  const ExpenseEntry({
    this.id = '',
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.time,
    required this.paidBy,
    this.addedBy = 'You',
    this.ownerUid = '',
    this.ownerName = 'You',
    this.paidTo = '',
    this.bankName,
    this.kind = ExpenseEntryKind.expense,
    this.isCredit = false,
  });
}
