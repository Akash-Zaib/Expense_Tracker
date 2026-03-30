import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/firebase/current_user_context.dart';
import '../models/bank_model.dart';

abstract class BanksLocalDataSource {
  Future<List<BankModel>> getBanks();
  Future<void> saveBanks(List<BankModel> banks);
}

class BanksLocalDataSourceImpl implements BanksLocalDataSource {
  // Local cache only. Firebase later will live in Firestore under:
  // `workspaces/{workspaceId}/banks/{bankId}`
  static const _baseKey = 'banks.v1';

  final SharedPreferences prefs;
  final CurrentUserContext _currentUserContext;

  const BanksLocalDataSourceImpl(this.prefs, this._currentUserContext);

  String? _keyForCurrentUser() {
    try {
      final uid = _currentUserContext.uid;
      return '$_baseKey.$uid';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BankModel>> getBanks() async {
    final key = _keyForCurrentUser();
    if (key == null) return [];

    final raw = prefs.getString(key);
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
    final key = _keyForCurrentUser();
    if (key == null) return;

    final encoded =
        jsonEncode(banks.map((b) => b.toJson()).toList(growable: false));
    await prefs.setString(key, encoded);
  }
}

