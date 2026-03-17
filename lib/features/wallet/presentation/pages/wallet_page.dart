import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../expense/domain/entities/expense_entry.dart';
import '../../../expense/presentation/store/transactions_store.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final TransactionsStore _transactionsStore;

  @override
  void initState() {
    super.initState();
    _transactionsStore = sl<TransactionsStore>();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transactionsStore,
      builder: (context, _) {
        final tx = _transactionsStore.transactions;

        final totalSpent = tx.fold<double>(
          0,
          (sum, e) => sum + (e.isCredit ? 0 : e.amount),
        );
        final totalReceived = tx.fold<double>(
          0,
          (sum, e) => sum + (e.isCredit ? e.amount : 0),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildBalanceCard(totalSpent: totalSpent, totalReceived: totalReceived),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildRecentTransactions(tx),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 20,
                child: const Icon(Icons.account_balance_wallet, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet', style: AppTextStyles.title),
                    Text(
                      'Balance & accounts',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.primary),
            onPressed: () {},
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard({
    required double totalSpent,
    required double totalReceived,
  }) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final net = totalReceived - totalSpent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Balance',
            style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatter.format(net.abs()),
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  net >= 0 ? 'Positive' : 'Negative',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  label: 'Received',
                  value: formatter.format(totalReceived),
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  label: 'Spent',
                  value: formatter.format(totalSpent),
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.add_card,
            title: 'Add Bank',
            subtitle: 'Link an account',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            icon: Icons.swap_horiz,
            title: 'Transfer',
            subtitle: 'Move funds',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<ExpenseEntry> tx) {
    final items = tx.take(8).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Recent Transactions', style: AppTextStyles.title),
          ),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.9)),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No transactions yet', style: AppTextStyles.caption),
            )
          else
            ...items.map((e) => _WalletTxRow(entry: e)),
        ],
      ),
    );
  }
}

class _WalletTxRow extends StatelessWidget {
  final ExpenseEntry entry;

  const _WalletTxRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final amountFormat = NumberFormat('#,##0', 'en_US');

    final isIn = entry.isCredit;
    final color = isIn ? AppColors.greenDark : AppColors.redDark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIn ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.category} • ${dateFormat.format(entry.date)}',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${isIn ? '+' : '-'}${amountFormat.format(entry.amount)}',
                    style: AppTextStyles.title.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          indent: 64,
          endIndent: 16,
          color: AppColors.border.withValues(alpha: 0.9),
        ),
      ],
    );
  }
}
