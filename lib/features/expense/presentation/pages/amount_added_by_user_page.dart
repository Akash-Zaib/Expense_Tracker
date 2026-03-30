import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/expense_entry.dart';

/// Per-user totals for [ExpenseEntryKind.amountAdded] within [entries]
/// (typically one calendar day, as passed from home).
class AmountAddedByUserPage extends StatelessWidget {
  final List<ExpenseEntry> entries;
  final List<String> displayUsers;
  final Map<String, String> uidByNormalizedName;
  final Map<String, int> userColorByName;
  final String dateRange;

  const AmountAddedByUserPage({
    super.key,
    required this.entries,
    required this.displayUsers,
    required this.uidByNormalizedName,
    required this.userColorByName,
    required this.dateRange,
  });

  /// Amount-added entries for this user (same rules as [totalAddedForUser]).
  static List<ExpenseEntry> amountAddedEntriesForUser(
    String displayName,
    List<ExpenseEntry> entries,
    Map<String, String> uidByNormalizedName,
  ) {
    final normalized = displayName.toLowerCase().trim();
    final uid = uidByNormalizedName[normalized];
    return entries.where((e) {
      if (e.kind != ExpenseEntryKind.amountAdded) return false;
      final eUid = e.ownerUid.trim();
      if (eUid.isNotEmpty) {
        return uid != null && eUid == uid;
      }
      return e.ownerName.trim().toLowerCase().trim() == normalized;
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

  /// Label → sum for that bank/cash source (matches add flow: empty bank → "By Cash").
  static Map<String, double> amountAddedByBankForUser(
    String displayName,
    List<ExpenseEntry> entries,
    Map<String, String> uidByNormalizedName,
  ) {
    final map = <String, double>{};
    for (final e in amountAddedEntriesForUser(displayName, entries, uidByNormalizedName)) {
      final label = (e.bankName ?? '').trim().isEmpty ? 'By Cash' : e.bankName!.trim();
      map[label] = (map[label] ?? 0) + e.amount;
    }
    return map;
  }

  Color? _colorForUser(String name) {
    final key = name.toLowerCase().trim();
    final value = userColorByName[key];
    return value == null ? null : Color(value);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final amountAddedEntries =
        entries.where((e) => e.kind == ExpenseEntryKind.amountAdded).toList();
    final grandTotal = amountAddedEntries.fold<double>(
      0,
      (s, e) => s + e.amount,
    );

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              dateRange,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final name in displayUsers) ...[
            _ExpandableUserAmountRow(
              displayName: name,
              amount: totalAddedForUser(name, entries, uidByNormalizedName),
              byBank: amountAddedByBankForUser(name, entries, uidByNormalizedName),
              formatter: formatter,
              baseColor: _colorForUser(name),
              initials: _initials(name),
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
      ),
    );
  }
}

class _ExpandableUserAmountRow extends StatelessWidget {
  final String displayName;
  final double amount;
  final Map<String, double> byBank;
  final NumberFormat formatter;
  final Color? baseColor;
  final String initials;

  const _ExpandableUserAmountRow({
    required this.displayName,
    required this.amount,
    required this.byBank,
    required this.formatter,
    required this.baseColor,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final border = baseColor == null
        ? Border.all(color: AppColors.border.withValues(alpha: 0.7))
        : Border.all(color: baseColor!.withValues(alpha: 0.45));
    final avatarBg = baseColor ?? AppColors.primary;
    final hasBreakdown = byBank.isNotEmpty;

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
              '+${formatter.format(amount)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }

    final bankKeys = byBank.keys.toList()
      ..sort((a, b) => byBank[b]!.compareTo(byBank[a]!));

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
                '+${formatter.format(amount)}',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            bankKeys[i] == 'By Cash'
                                ? Icons.payments_outlined
                                : Icons.account_balance_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bankKeys[i],
                              style: AppTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '+${formatter.format(byBank[bankKeys[i]]!)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
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
