import 'package:flutter/material.dart';

class ExpenseEntry {
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final TimeOfDay time;
  final String paidBy;
  final bool isCredit; // true = green (you/personal), false = red (other user)

  const ExpenseEntry({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.time,
    required this.paidBy,
    this.isCredit = false,
  });
}

