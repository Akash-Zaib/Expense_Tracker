import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../banks/presentation/store/banks_store.dart';
import '../store/transactions_store.dart';
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

    _banksStore.load();
    _txStore.load(force: true, limit: _kLoadLimit);
  }

  @override
  void dispose() {
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

          if ((_txStore.loading && txs.isEmpty) ||
              (!_banksStore.loaded && banks.isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final rows = <_BalanceRow>[];

          for (final userName in widget.displayUsers) {
            final normalized = userName.toLowerCase().trim();
            final uid = widget.uidByNormalizedName[normalized] ?? '';
            if (uid.isEmpty) continue;

            // By Cash row per user
            rows.add(
              _BalanceRow(
                label: AmountAddedByUserPage.cashSourceLabel,
                belongsTo: userName,
                remaining: AmountAddedByUserPage.remainingForOwnerAndSource(
                  ownerUid: uid,
                  ownerName: userName,
                  bankLabel: AmountAddedByUserPage.cashSourceLabel,
                  entries: txs,
                ),
                isCash: true,
              ),
            );

            for (final b in banks.where((b) => b.ownerUid == uid)) {
              rows.add(
                _BalanceRow(
                  label: b.name,
                  belongsTo: b.ownerName.trim().isEmpty
                      ? userName
                      : b.ownerName,
                  remaining: AmountAddedByUserPage.remainingForOwnerAndSource(
                    ownerUid: uid,
                    ownerName: userName,
                    bankLabel: b.name,
                    entries: txs,
                  ),
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
              final remColor = r.remaining >= 0
                  ? const Color(0xFF16A34A)
                  : AppColors.redDark;
              return Container(
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
                        // Text('Remaining', style: AppTextStyles.caption),
                        // const SizedBox(height: 2),
                        Text(
                          fmt.format(r.remaining),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: remColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BalanceRow {
  final String label;
  final String belongsTo;
  final double remaining;
  final bool isCash;

  const _BalanceRow({
    required this.label,
    required this.belongsTo,
    required this.remaining,
    required this.isCash,
  });
}
