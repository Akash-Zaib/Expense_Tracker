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
    DateTime dateFromFirestore(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    String readString(dynamic raw, {String fallback = ''}) {
      final value = (raw ?? '').toString().trim();
      return value.isEmpty ? fallback : value;
    }

    int readInt(dynamic raw, {int fallback = 0}) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
      return fallback;
    }

    double readDouble(dynamic raw, {double fallback = 0}) {
      if (raw is double) return raw;
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw.trim()) ?? fallback;
      return fallback;
    }

    bool readBool(dynamic raw, {bool fallback = false}) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final v = raw.trim().toLowerCase();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
      }
      return fallback;
    }

    final date = dateFromFirestore(json['date']);
    final hour = readInt(json['hour']).clamp(0, 23);
    final minute = readInt(json['minute']).clamp(0, 59);
    final kindRaw = readString(json['kind'], fallback: 'expense');
    final kind = kindRaw == 'amountAdded'
        ? ExpenseEntryKind.amountAdded
        : ExpenseEntryKind.expense;

    return ExpenseEntryModel(
      id: id,
      description: readString(json['description'], fallback: 'Expense'),
      amount: readDouble(json['amount']),
      category: readString(
        json['category'],
        fallback: 'Miscellaneous Expenses',
      ),
      date: DateTime(date.year, date.month, date.day),
      time: TimeOfDay(hour: hour, minute: minute),
      paidBy: readString(json['paidBy'], fallback: 'You'),
      addedBy: readString(json['addedBy'], fallback: 'You'),
      ownerUid: readString(json['ownerUid'], fallback: ''),
      ownerName: readString(
        json['ownerName'],
        fallback: readString(json['addedBy'], fallback: 'You'),
      ),
      paidTo: readString(json['paidTo'], fallback: ''),
      bankName: readString(json['bankName'], fallback: '').isEmpty
          ? null
          : readString(json['bankName'], fallback: ''),
      kind: kind,
      isCredit: readBool(json['isCredit']),
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
