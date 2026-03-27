import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/expense_entry.dart';

class ExpenseEntryModel extends ExpenseEntry {
  const ExpenseEntryModel({
    super.id,
    required super.description,
    required super.amount,
    required super.category,
    required super.date,
    required super.time,
    required super.paidBy,
    super.addedBy,
    super.ownerUid,
    super.ownerName,
    super.paidTo,
    super.bankName,
    super.kind,
    super.isCredit,
  });

  factory ExpenseEntryModel.fromEntity(ExpenseEntry entry) {
    return ExpenseEntryModel(
      description: entry.description,
      id: entry.id,
      amount: entry.amount,
      category: entry.category,
      date: entry.date,
      time: entry.time,
      paidBy: entry.paidBy,
      addedBy: entry.addedBy,
      ownerUid: entry.ownerUid,
      ownerName: entry.ownerName,
      paidTo: entry.paidTo,
      bankName: entry.bankName,
      kind: entry.kind,
      isCredit: entry.isCredit,
    );
  }

  factory ExpenseEntryModel.fromFirestore(Map<String, dynamic> json, String id) {
    final timestamp = json['date'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final hour = (json['hour'] as num?)?.toInt() ?? 0;
    final minute = (json['minute'] as num?)?.toInt() ?? 0;
    final kindRaw = (json['kind'] as String?) ?? 'expense';
    final kind = kindRaw == 'amountAdded'
        ? ExpenseEntryKind.amountAdded
        : ExpenseEntryKind.expense;

    return ExpenseEntryModel(
      id: id,
      description: (json['description'] as String?)?.trim().isNotEmpty == true
          ? (json['description'] as String).trim()
          : 'Expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : 'Miscellaneous Expenses',
      date: DateTime(date.year, date.month, date.day),
      time: TimeOfDay(hour: hour, minute: minute),
      paidBy: (json['paidBy'] as String?)?.trim().isNotEmpty == true
          ? (json['paidBy'] as String).trim()
          : 'You',
      addedBy: (json['addedBy'] as String?)?.trim().isNotEmpty == true
          ? (json['addedBy'] as String).trim()
          : 'You',
      ownerUid: (json['ownerUid'] as String?) ?? '',
      ownerName: (json['ownerName'] as String?)?.trim().isNotEmpty == true
          ? (json['ownerName'] as String).trim()
          : ((json['addedBy'] as String?)?.trim().isNotEmpty == true
                ? (json['addedBy'] as String).trim()
                : 'You'),
      paidTo: (json['paidTo'] as String?)?.trim() ?? '',
      bankName: (json['bankName'] as String?)?.trim().isEmpty == true
          ? null
          : (json['bankName'] as String?),
      kind: kind,
      isCredit: (json['isCredit'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'hour': time.hour,
      'minute': time.minute,
      'paidBy': paidBy,
      'addedBy': addedBy,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'paidTo': paidTo,
      'bankName': bankName,
      'kind': kind == ExpenseEntryKind.amountAdded ? 'amountAdded' : 'expense',
      'isCredit': isCredit,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
