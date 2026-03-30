import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/expense_entry.dart';
import '../store/transactions_store.dart';

/// Cumulative per-user, per-source (bank / By Cash) added, spent, and remaining.
/// Uses [TransactionsStore] (high fetch limit) — not the home date filter.
class AmountAddedByUserPage extends StatefulWidget {
  final List<String> displayUsers;
  final Map<String, String> uidByNormalizedName;
  final Map<String, int> userColorByName;

  const AmountAddedByUserPage({
    super.key,
    required this.displayUsers,
    required this.uidByNormalizedName,
    required this.userColorByName,
  });

  /// Same owner matching for all aggregations.
  static bool _entryMatchesUser(
    ExpenseEntry e,
    String displayName,
    Map<String, String> uidByNormalizedName,
  ) {
    final normalized = displayName.toLowerCase().trim();
    final uid = uidByNormalizedName[normalized];
    final eUid = e.ownerUid.trim();
    if (eUid.isNotEmpty) {
      return uid != null && eUid == uid;
    }
    return e.ownerName.trim().toLowerCase().trim() == normalized;
  }

  static String sourceLabel(ExpenseEntry e) {
    return (e.bankName ?? '').trim().isEmpty ? 'By Cash' : e.bankName!.trim();
  }

  /// Amount-added entries for this user.
  static List<ExpenseEntry> amountAddedEntriesForUser(
    String displayName,
    List<ExpenseEntry> entries,
    Map<String, String> uidByNormalizedName,
  ) {
    return entries.where((e) {
      if (e.kind != ExpenseEntryKind.amountAdded) return false;
      return _entryMatchesUser(e, displayName, uidByNormalizedName);
    }).toList();
  }

  static double totalAddedForUser(
    String displayName,
    List<ExpenseEntry> entries,
    Map<String, String> uidByNormalizedName,
  ) {
    return amountAddedEntriesForUser(displayName, entries, uidByNormalizedName)
        .fold<double>(0, (s, e) => s + e.amount);
  }

  static Map<String, double> amountAddedByBankForUser(
    String displayName,
    List<ExpenseEntry> entries,
    Map<String, String> uidByNormalizedName,
  ) {
    final map = <String, double>{};
    for (final e in amountAddedEntriesForUser(displayName, entries, uidByNormalizedName)) {
      final label = sourceLabel(e);
      map[label] = (map[label] ?? 0) + e.amount;
    }
    return map;
  }

  /// Debit expenses for this user (same convention as home expense cards).
  static List<ExpenseEntry> expenseEntriesForUser(
    String displayName,
    List<ExpenseEntry> entries,
    Map<String, String> uidByNormalizedName,
  ) {
    return entries.where((e) {
      if (e.kind != ExpenseEntryKind.expense) return false;
      if (e.isCredit) return false;
      return _entryMatchesUser(e, displayName, uidByNormalizedName);
    }).toList();
  }

  static Map<String, double> expensesByBankForUser(
    String displayName,
    List<ExpenseEntry> entries,
    Map<String, String> uidByNormalizedName,
  ) {
    final map = <String, double>{};
    for (final e in expenseEntriesForUser(displayName, entries, uidByNormalizedName)) {
      final label = sourceLabel(e);
      map[label] = (map[label] ?? 0) + e.amount;
    }
    return map;
  }

  static const String cashSourceLabel = 'By Cash';

  /// Spends on a **named bank** where the user recorded **no** amount-added for that
  /// label are shown under [cashSourceLabel] instead (cannot spend from a bank you never funded).
  static Map<String, double> adjustSpentMapForUnfundedBankSources({
    required Map<String, double> addedByBank,
    required Map<String, double> spentByBank,
  }) {
    final spent = Map<String, double>.from(spentByBank);
    for (final label in spent.keys.toList()) {
      if (label == cashSourceLabel) continue;
      final added = addedByBank[label] ?? 0;
      if (added > 0) continue;
      final s = spent[label] ?? 0;
      if (s <= 0) continue;
      spent[cashSourceLabel] = (spent[cashSourceLabel] ?? 0) + s;
      spent.remove(label);
    }
    spent.removeWhere((_, v) => v == 0);
    return spent;
  }

  /// Raw remaining for one source (before [adjustSpentMapForUnfundedBankSources]).
  static double remainingForBankSourceRaw({
    required String displayName,
    required String bankLabel,
    required List<ExpenseEntry> entries,
    required Map<String, String> uidByNormalizedName,
  }) {
    final label = bankLabel.trim().isEmpty ? cashSourceLabel : bankLabel.trim();
    final added = amountAddedByBankForUser(displayName, entries, uidByNormalizedName);
    final spent = expensesByBankForUser(displayName, entries, uidByNormalizedName);
    return (added[label] ?? 0) - (spent[label] ?? 0);
  }

  @override
  State<AmountAddedByUserPage> createState() => _AmountAddedByUserPageState();
}

class _AmountAddedByUserPageState extends State<AmountAddedByUserPage> {
  late final TransactionsStore _store;

  /// Cumulative fetch limit (see [TransactionsStore.load] default 200).
  static const int _kLoadLimit = 2000;

  @override
  void initState() {
    super.initState();
    _store = sl<TransactionsStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  /// [TransactionsStore.load] no-ops while `_loading`; wait so we apply [_kLoadLimit].
  Future<void> _loadTransactions() async {
    var attempts = 0;
    while (_store.loading && attempts < 80) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
    if (!mounted) return;
    await _store.load(force: true, limit: _kLoadLimit);
  }

  Color? _colorForUser(String name) {
    final key = name.toLowerCase().trim();
    final value = widget.userColorByName[key];
    return value == null ? null : Color(value);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Amount added by user', style: AppTextStyles.title),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          if (_store.loading && _store.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final txs = _store.transactions;
          final uidMap = widget.uidByNormalizedName;

          final grandTotal = txs
              .where((e) => e.kind == ExpenseEntryKind.amountAdded)
              .fold<double>(0, (s, e) => s + e.amount);

          final err = _store.error;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All time · by bank or cash',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Balances use up to $_kLoadLimit most recent transactions.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (err != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    err,
                    style: AppTextStyles.caption.copyWith(color: AppColors.redDark),
                  ),
                ),
              for (final name in widget.displayUsers) ...[
                Builder(
                  builder: (context) {
                    final added = AmountAddedByUserPage.amountAddedByBankForUser(
                      name,
                      txs,
                      uidMap,
                    );
                    final spentRaw = AmountAddedByUserPage.expensesByBankForUser(
                      name,
                      txs,
                      uidMap,
                    );
                    final spent = AmountAddedByUserPage.adjustSpentMapForUnfundedBankSources(
                      addedByBank: added,
                      spentByBank: spentRaw,
                    );
                    return _ExpandableUserAmountRow(
                      displayName: name,
                      totalAddedCumulative: AmountAddedByUserPage.totalAddedForUser(
                        name,
                        txs,
                        uidMap,
                      ),
                      addedByBank: added,
                      spentByBank: spent,
                      formatter: formatter,
                      baseColor: _colorForUser(name),
                      initials: _initials(name),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total added (all users)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatter.format(grandTotal),
                            style: AppTextStyles.heading3,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 42,
                      width: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandableUserAmountRow extends StatelessWidget {
  final String displayName;
  /// Cumulative total amount added for this user (all sources).
  final double totalAddedCumulative;
  final Map<String, double> addedByBank;
  final Map<String, double> spentByBank;
  final NumberFormat formatter;
  final Color? baseColor;
  final String initials;

  const _ExpandableUserAmountRow({
    required this.displayName,
    required this.totalAddedCumulative,
    required this.addedByBank,
    required this.spentByBank,
    required this.formatter,
    required this.baseColor,
    required this.initials,
  });

  static List<String> _sortedSourceKeys(
    Map<String, double> addedByBank,
    Map<String, double> spentByBank,
  ) {
    final keys = <String>{...addedByBank.keys, ...spentByBank.keys}.toList();
    keys.sort((a, b) {
      final ta = (addedByBank[a] ?? 0) + (spentByBank[a] ?? 0);
      final tb = (addedByBank[b] ?? 0) + (spentByBank[b] ?? 0);
      return tb.compareTo(ta);
    });
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final border = baseColor == null
        ? Border.all(color: AppColors.border.withValues(alpha: 0.7))
        : Border.all(color: baseColor!.withValues(alpha: 0.45));
    final avatarBg = baseColor ?? AppColors.primary;
    final bankKeys = _sortedSourceKeys(addedByBank, spentByBank);
    final hasBreakdown = bankKeys.isNotEmpty;

    final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );

    if (!hasBreakdown) {
      return Container(
        decoration: cardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarBg,
              child: Text(
                initials.isEmpty ? 'U' : initials,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                displayName,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '+${formatter.format(totalAddedCumulative)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: avatarBg,
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${formatter.format(totalAddedCumulative)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          iconColor: baseColor ?? AppColors.primary,
          collapsedIconColor: baseColor ?? AppColors.primary,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'By bank / source',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (var i = 0; i < bankKeys.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.85),
                      ),
                    _BankSourceRow(
                      label: bankKeys[i],
                      added: addedByBank[bankKeys[i]] ?? 0,
                      spent: spentByBank[bankKeys[i]] ?? 0,
                      formatter: formatter,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankSourceRow extends StatelessWidget {
  final String label;
  final double added;
  final double spent;
  final NumberFormat formatter;

  const _BankSourceRow({
    required this.label,
    required this.added,
    required this.spent,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = added - spent;
    final remColor = remaining >= 0 ? const Color(0xFF16A34A) : AppColors.redDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                label == 'By Cash' ? Icons.payments_outlined : Icons.account_balance_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: 'Added',
                  value: '+${formatter.format(added)}',
                  valueColor: const Color(0xFF16A34A),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  title: 'Spent',
                  value: formatter.format(spent),
                  valueColor: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  title: 'Remaining',
                  value: formatter.format(remaining),
                  valueColor: remColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
