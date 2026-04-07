import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../banks/presentation/store/banks_store.dart';
import '../store/transactions_store.dart';
import '../../domain/entities/expense_entry.dart';
import 'amount_added_by_user_page.dart';

class BankBalancesPage extends StatefulWidget {
  final Map<String, String> uidByNormalizedName;
  final List<String> displayUsers;

  const BankBalancesPage({
    super.key,
    required this.uidByNormalizedName,
    required this.displayUsers,
  });

  @override
  State<BankBalancesPage> createState() => _BankBalancesPageState();
}

class _BankBalancesPageState extends State<BankBalancesPage> {
  late final TransactionsStore _txStore;
  late final BanksStore _banksStore;

  static const int _kLoadLimit = 2000;

  @override
  void initState() {
    super.initState();
    _txStore = sl<TransactionsStore>();
    _banksStore = sl<BanksStore>();

    _banksStore.startWatching();
    if (!_txStore.watching) {
      _txStore.startWatching(limit: _kLoadLimit);
    }
  }

  @override
  void dispose() {
    _banksStore.stopWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bank Balances', style: AppTextStyles.title),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_txStore, _banksStore]),
        builder: (context, _) {
          final txs = _txStore.transactions;
          final banks = _banksStore.banks;
          final uidByName = <String, String>{...widget.uidByNormalizedName};
          for (final tx in txs) {
            final key = tx.ownerName.trim().toLowerCase();
            final uid = tx.ownerUid.trim();
            if (key.isNotEmpty && uid.isNotEmpty) {
              uidByName.putIfAbsent(key, () => uid);
            }
          }
          for (final b in banks) {
            final key = b.ownerName.trim().toLowerCase();
            final uid = b.ownerUid.trim();
            if (key.isNotEmpty && uid.isNotEmpty) {
              uidByName.putIfAbsent(key, () => uid);
            }
          }

          final displayUsers = <String>[...widget.displayUsers];
          for (final tx in txs) {
            final owner = tx.ownerName.trim();
            if (owner.isNotEmpty &&
                !displayUsers.any((u) => u.toLowerCase().trim() == owner.toLowerCase())) {
              displayUsers.add(owner);
            }
          }
          for (final b in banks) {
            final owner = b.ownerName.trim();
            if (owner.isNotEmpty &&
                !displayUsers.any((u) => u.toLowerCase().trim() == owner.toLowerCase())) {
              displayUsers.add(owner);
            }
          }

          if ((_txStore.loading && txs.isEmpty) ||
              (!_banksStore.loaded && banks.isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final rows = <_BalanceRow>[];

          for (final userName in displayUsers) {
            final normalized = userName.toLowerCase().trim();
            final uid = uidByName[normalized] ?? '';
            if (uid.isEmpty) continue;

            bool ownerMatches(ExpenseEntry e) {
              final eUid = e.ownerUid.trim();
              if (eUid.isNotEmpty) return eUid == uid;
              return e.ownerName.trim().toLowerCase() ==
                  userName.trim().toLowerCase();
            }

            bool hasAnyForSource(String sourceLabel) {
              return txs.any(
                (e) =>
                    ownerMatches(e) &&
                    AmountAddedByUserPage.sourceLabel(e) == sourceLabel,
              );
            }

            // By Cash row per user (only if non-zero OR has any matching tx)
            final cashLabel = AmountAddedByUserPage.cashSourceLabel;
            final cashRemaining =
                AmountAddedByUserPage.remainingForOwnerAndSource(
                  ownerUid: uid,
                  ownerName: userName,
                  bankLabel: cashLabel,
                  entries: txs,
                );
            if (cashRemaining != 0 || hasAnyForSource(cashLabel)) {
              rows.add(
                _BalanceRow(
                  label: cashLabel,
                  belongsTo: userName,
                  ownerUid: uid,
                  ownerName: userName,
                  bankLabel: cashLabel,
                  remaining: cashRemaining,
                  isCash: true,
                ),
              );
            }

            for (final b in banks.where((b) => b.ownerUid == uid)) {
              final bankLabel = b.name.trim();
              if (bankLabel.isEmpty) continue;
              final ownerDisplay = b.ownerName.trim().isEmpty
                  ? userName
                  : b.ownerName;
              final remaining =
                  AmountAddedByUserPage.remainingForOwnerAndSource(
                    ownerUid: uid,
                    ownerName: ownerDisplay,
                    bankLabel: bankLabel,
                    entries: txs,
                  );
              if (remaining == 0 && !hasAnyForSource(bankLabel)) {
                continue;
              }

              rows.add(
                _BalanceRow(
                  label: bankLabel,
                  belongsTo: ownerDisplay,
                  ownerUid: uid,
                  ownerName: ownerDisplay,
                  bankLabel: bankLabel,
                  remaining: remaining,
                  isCash: false,
                ),
              );
            }
          }

          rows.sort((a, b) {
            final byOwner = a.belongsTo.toLowerCase().compareTo(
              b.belongsTo.toLowerCase(),
            );
            if (byOwner != 0) return byOwner;
            if (a.isCash != b.isCash) return a.isCash ? -1 : 1;
            return a.label.toLowerCase().compareTo(b.label.toLowerCase());
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: rows.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = rows[i];
              final displayRemaining = r.remaining < 0 ? 0.0 : r.remaining;
              final remColor = displayRemaining > 0
                  ? const Color(0xFF16A34A)
                  : AppColors.textSecondary;
              return InkWell(
                onTap: () =>
                    _showBankDetailsDialog(context: context, row: r, txs: txs),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: r.isCash
                              ? const Color(0xFFE8F5E9)
                              : AppColors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          r.isCash
                              ? Icons.payments_outlined
                              : Icons.account_balance_outlined,
                          color: r.isCash
                              ? const Color(0xFF2E7D32)
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Belongs to: ${r.belongsTo}',
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(displayRemaining),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: remColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showBankDetailsDialog({
    required BuildContext context,
    required _BalanceRow row,
    required List<ExpenseEntry> txs,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final fmt = NumberFormat('#,##0', 'en_US');
        final dateFmt = DateFormat.yMMMd('en_US');

        bool entryMatchesOwner(ExpenseEntry e) {
          final eUid = e.ownerUid.trim();
          if (eUid.isNotEmpty) {
            return eUid == row.ownerUid;
          }
          return e.ownerName.trim().toLowerCase() ==
              row.ownerName.trim().toLowerCase();
        }

        int minutes(TimeOfDay t) => t.hour * 60 + t.minute;

        final sourceLabel = row.bankLabel.trim();

        final added = txs
            .where(
              (e) =>
                  entryMatchesOwner(e) &&
                  e.kind == ExpenseEntryKind.amountAdded &&
                  AmountAddedByUserPage.sourceLabel(e) == sourceLabel,
            )
            .toList(growable: false);

        final spent = txs
            .where(
              (e) =>
                  entryMatchesOwner(e) &&
                  e.kind == ExpenseEntryKind.expense &&
                  !e.isCredit &&
                  AmountAddedByUserPage.sourceLabel(e) == sourceLabel,
            )
            .toList(growable: false);

        added.sort((a, b) {
          final dateCmp = b.date.compareTo(a.date);
          if (dateCmp != 0) return dateCmp;
          return minutes(b.time).compareTo(minutes(a.time));
        });
        spent.sort((a, b) {
          final dateCmp = b.date.compareTo(a.date);
          if (dateCmp != 0) return dateCmp;
          return minutes(b.time).compareTo(minutes(a.time));
        });

        final totalAdded = added.fold<double>(0, (sum, e) => sum + e.amount);
        final totalSpent = spent.fold<double>(0, (sum, e) => sum + e.amount);
        final remaining = totalAdded - totalSpent;

        String formatTimeOfDay(TimeOfDay t) {
          return MaterialLocalizations.of(
            ctx,
          ).formatTimeOfDay(t, alwaysUse24HourFormat: false);
        }

        Widget entryTile(ExpenseEntry e, {required bool isAdded}) {
          final amountText = isAdded
              ? '+${fmt.format(e.amount)}'
              : '-${fmt.format(e.amount)}';
          final amountColor = isAdded
              ? const Color(0xFF16A34A)
              : AppColors.redDark;
          final iconData = isAdded
              ? Icons.add_circle_outline
              : Icons.money_off_outlined;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAdded
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF1F2),
                    ),
                    child: Icon(iconData, color: amountColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFmt.format(e.date)} • ${formatTimeOfDay(e.time)}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Category: ${e.category}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Paid by: ${e.paidBy} • Added by: ${e.addedBy} • Paid to: ${e.paidTo}',
                          style: AppTextStyles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amountText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return AlertDialog(
          title: Text(
            row.isCash ? AmountAddedByUserPage.cashSourceLabel : row.label,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belongs to: ${row.belongsTo}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.85),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary (All Time)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _detailRow(
                          'Total Amount',
                          fmt.format(totalAdded),
                          valueColor: const Color(0xFF16A34A),
                        ),
                        _detailRow(
                          'Total Spent',
                          fmt.format(totalSpent),
                          valueColor: AppColors.redDark,
                        ),
                        _detailRow(
                          'Remaining Amount',
                          fmt.format(remaining),
                          valueColor: remaining >= 0
                              ? const Color(0xFF16A34A)
                              : AppColors.redDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Amount Added',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (added.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('No amount-added records.'),
                    )
                  else
                    ...added.map((e) => entryTile(e, isAdded: true)),
                  const SizedBox(height: 14),
                  Text(
                    'Expenses',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (spent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('No expense records.'),
                    )
                  else
                    ...spent.map((e) => entryTile(e, isAdded: false)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow {
  final String label;
  final String belongsTo;
  final double remaining;
  final bool isCash;
  final String ownerUid;
  final String ownerName;
  final String bankLabel;

  const _BalanceRow({
    required this.label,
    required this.belongsTo,
    required this.remaining,
    required this.isCash,
    required this.ownerUid,
    required this.ownerName,
    required this.bankLabel,
  });
}
