import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/expense_entry.dart';
import '../store/transactions_store.dart';

class PersonalExpensesScreen extends StatelessWidget {
  final List<ExpenseEntry>? entries;
  final String title;
  final bool showOnlyExpenses;
  final bool showOnlyAmountAdded;

  const PersonalExpensesScreen({
    super.key,
    this.entries,
    this.title = 'Personal Expenses',
    this.showOnlyExpenses = false,
    this.showOnlyAmountAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    final store = sl<TransactionsStore>();

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
        title: Text(title, style: AppTextStyles.title),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final source = entries ?? store.transactions;
          final filtered = showOnlyAmountAdded
              ? source
                  .where((e) => e.kind == ExpenseEntryKind.amountAdded)
                  .toList()
              : (showOnlyExpenses
                    ? source
                        .where((e) => e.kind == ExpenseEntryKind.expense)
                        .toList()
                    : source.toList());
          final items = filtered
            ..sort((a, b) {
              final dateCmp = b.date.compareTo(a.date);
              if (dateCmp != 0) return dateCmp;
              final aMin = a.time.hour * 60 + a.time.minute;
              final bMin = b.time.hour * 60 + b.time.minute;
              return bMin.compareTo(aMin);
            });

          final addedTotal = items
              .where((e) => e.kind == ExpenseEntryKind.amountAdded)
              .fold<double>(0, (sum, e) => sum + e.amount);

          final grouped = _groupByDay(items);
          final groupKeys = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              if (!showOnlyExpenses && !showOnlyAmountAdded) ...[
                _TotalCard(totalAddedAmount: addedTotal),
                const SizedBox(height: 16),
              ],
              if (items.isEmpty)
                _EmptyState()
              else
                for (final day in groupKeys) ...[
                  _SectionHeader(title: _formatSectionTitle(day)),
                  const SizedBox(height: 10),
                  _TimelineCard(
                    entries: grouped[day]!,
                    onTapEntry: (entry) => showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => _EntryDetailsDialog(entry: entry),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double totalAddedAmount;

  const _TotalCard({required this.totalAddedAmount});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return Container(
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
                  'Total Amount Added',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  formatter.format(totalAddedAmount),
                  style: AppTextStyles.heading3,
                ),
              ],
            ),
          ),
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.add_circle_outline, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final List<ExpenseEntry> entries;
  final ValueChanged<ExpenseEntry> onTapEntry;

  const _TimelineCard({required this.entries, required this.onTapEntry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            _TimelineRow(entry: entries[i], onTap: () => onTapEntry(entries[i])),
            if (i != entries.length - 1)
              Divider(
                height: 1,
                indent: 68,
                endIndent: 16,
                color: AppColors.border.withValues(alpha: 0.9),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ExpenseEntry entry;
  final VoidCallback onTap;

  const _TimelineRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final isAdded = entry.kind == ExpenseEntryKind.amountAdded;

    final initials = (entry.addedBy.trim().isEmpty ? 'You' : entry.addedBy)
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    final subtitleParts = <String>[
      'Added by ${entry.addedBy}',
      if (isAdded && (entry.bankName ?? '').trim().isNotEmpty) 'Source ${entry.bankName}',
      if (!isAdded && entry.paidBy.trim().isNotEmpty) 'Paid by ${entry.paidBy}',
    ];

    final amountText = isAdded ? '+${formatter.format(entry.amount)}' : formatter.format(entry.amount);
    final amountColor = isAdded ? const Color(0xFF16A34A) : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isAdded ? const Color(0xFF22C55E) : AppColors.primary,
              child: Text(
                initials.isEmpty ? 'U' : initials,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdded ? 'Amount Added' : entry.description,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join(' • '),
                    style: AppTextStyles.caption,
                  ),
                  if (!isAdded && entry.category.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.category,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountText,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryDetailsDialog extends StatelessWidget {
  final ExpenseEntry entry;

  const _EntryDetailsDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final time = entry.time.format(context);
    final amountFmt = NumberFormat('#,##0', 'en_US');
    final isAdded = entry.kind == ExpenseEntryKind.amountAdded;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Details',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 22, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.9)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              ),
              child: Column(
                children: [
                  _detailRow(title: 'Type', value: isAdded ? 'Amount Added' : 'Expense'),
                  const SizedBox(height: 12),
                  _detailRow(title: 'Added by', value: entry.addedBy),
                  const SizedBox(height: 12),
                  _detailRow(title: 'Date', value: '${dateFmt.format(entry.date)} • $time'),
                  if (isAdded && (entry.bankName ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _detailRow(title: 'Source', value: entry.bankName),
                  ],
                  if (!isAdded) ...[
                    const SizedBox(height: 12),
                    _detailRow(title: 'Paid by', value: entry.paidBy),
                    const SizedBox(height: 12),
                    _detailRow(title: 'Category', value: entry.category),
                  ],
                  const SizedBox(height: 16),
                  Divider(height: 1, color: AppColors.border.withValues(alpha: 0.9)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        isAdded ? 'Amount Added:' : 'Amount:',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        amountFmt.format(entry.amount),
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({required String title, String? value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            (value ?? '').toString(),
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No entries yet',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text('Add Amount or submit an expense', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

Map<DateTime, List<ExpenseEntry>> _groupByDay(List<ExpenseEntry> entries) {
  final map = <DateTime, List<ExpenseEntry>>{};
  for (final e in entries) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    (map[day] ??= []).add(e);
  }
  return map;
}

String _formatSectionTitle(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (day == today) return 'Today';
  if (day == yesterday) return 'Yesterday';

  return DateFormat('dd MMM yyyy').format(day);
}
