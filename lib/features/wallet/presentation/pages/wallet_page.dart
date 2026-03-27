import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../expense/presentation/store/transactions_store.dart';
import '../../../banks/domain/entities/bank.dart';
import '../../../banks/presentation/store/banks_store.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final TransactionsStore _transactionsStore;
  late final BanksStore _banksStore;

  @override
  void initState() {
    super.initState();
    _transactionsStore = sl<TransactionsStore>();
    _banksStore = sl<BanksStore>();
    _banksStore.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_transactionsStore, _banksStore]),
      builder: (context, _) {
        final tx = _transactionsStore.transactions;
        final banks = _banksStore.banks;

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
              // const SizedBox(height: 18),
              // _buildBalanceCard(totalSpent: totalSpent, totalReceived: totalReceived),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildBanksSection(banks),
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
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet', style: AppTextStyles.title),
                    Text(
                      'Balance & accounts',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Container(
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     shape: BoxShape.circle,
        //     border: Border.all(color: AppColors.border),
        //   ),
        //   child: IconButton(
        //     icon: const Icon(Icons.more_horiz, color: AppColors.primary),
        //     onPressed: () {},
        //     constraints: const BoxConstraints(),
        //     padding: const EdgeInsets.all(8),
        //   ),
        // ),
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
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
    return _actionCard(
      icon: Icons.add_card,
      title: 'Add Bank',
      subtitle: 'Add / manage accounts',
      onTap: _openAddBankSheet,
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

  Widget _buildBanksSection(List<Bank> banks) {
    final hasUnsubmitted = banks.any((b) => !b.isSubmitted);
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
            child: Row(
              children: [
                Expanded(child: Text('My Banks', style: AppTextStyles.title)),
                TextButton(
                  onPressed: hasUnsubmitted
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _banksStore.submitAll();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Submitted. Banks are now locked.'),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.9)),
          if (banks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No banks yet. Tap “Add Bank” to create one.',
                style: AppTextStyles.caption,
              ),
            )
          else
            ...banks.map(
              (b) => _BankRow(
                bank: b,
                onDelete: b.isSubmitted
                    ? null
                    : () => _banksStore.removeById(b.id),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openAddBankSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AddBankBottomSheet(banksStore: _banksStore);
      },
    );
  }
}

class _AddBankBottomSheet extends StatefulWidget {
  final BanksStore banksStore;

  const _AddBankBottomSheet({required this.banksStore});

  @override
  State<_AddBankBottomSheet> createState() => _AddBankBottomSheetState();
}

class _AddBankBottomSheetState extends State<_AddBankBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _accController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _accController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Add Bank', style: AppTextStyles.title)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Add custom bank', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Bank name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _accController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await widget.banksStore.addNew(
                    name: _nameController.text,
                    accountNumber: _accController.text,
                  );
                  if (!mounted) return;
                  navigator.pop(); // close after adding
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final Bank bank;
  final VoidCallback? onDelete;

  const _BankRow({required this.bank, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final subtitle =
        bank.accountNumber == null || bank.accountNumber!.trim().isEmpty
        ? null
        : 'A/C: ${bank.accountNumber}';

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
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.name,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (bank.isSubmitted)
                Icon(Icons.lock, size: 18, color: AppColors.border)
              else
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.redDark,
                  tooltip: 'Delete',
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
