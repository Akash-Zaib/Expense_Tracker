import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bank_model.dart';

abstract class BanksLocalDataSource {
  Future<List<BankModel>> getBanks();
  Future<void> saveBanks(List<BankModel> banks);
}

class BanksLocalDataSourceImpl implements BanksLocalDataSource {
  // Local cache only. Firebase later will live in Firestore under:
  // `workspaces/{workspaceId}/banks/{bankId}`
  static const _key = 'banks.v1';

  final SharedPreferences prefs;

  const BanksLocalDataSourceImpl(this.prefs);

  @override
  Future<List<BankModel>> getBanks() async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((e) => BankModel.fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.id.trim().isNotEmpty && b.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> saveBanks(List<BankModel> banks) async {
    final encoded = jsonEncode(banks.map((b) => b.toJson()).toList(growable: false));
    await prefs.setString(_key, encoded);
  }
}

