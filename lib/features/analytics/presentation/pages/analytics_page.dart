import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../expense/domain/entities/expense_entry.dart';
import '../../../expense/presentation/store/transactions_store.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late final TransactionsStore _transactionsStore;
  final TextEditingController _searchController = TextEditingController();

  AnalyticsFilter _filter = const AnalyticsFilter();

  @override
  void initState() {
    super.initState();
    _transactionsStore = sl<TransactionsStore>();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transactionsStore,
      builder: (context, _) {
        final all = _transactionsStore.transactions;
        final filtered = _apply(all);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              _buildSearchRow(context),
              const SizedBox(height: 14),
              _buildRecentExpenses(context, filtered),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.greenDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logic Worms',
                      style: AppTextStyles.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '3 Partners',
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      hintStyle: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () async {
            final result = await showModalBottomSheet<AnalyticsFilter>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => FilterExpensesSheet(
                initial: _filter,
                paidByOptions: _paidByOptions(_transactionsStore.transactions),
                categoryOptions: _categoryOptions(
                  _transactionsStore.transactions,
                ),
              ),
            );
            if (result != null) setState(() => _filter = result);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.transparent),
            ),
            child: const Icon(Icons.tune, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpenses(
    BuildContext context,
    List<ExpenseEntry> entries,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Recent Expenses', style: AppTextStyles.title),
          ),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.9)),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text('No expenses found', style: AppTextStyles.caption),
            )
          else
            ...entries.map((e) => _ExpenseRow(entry: e)),
        ],
      ),
    );
  }

  List<String> _paidByOptions(List<ExpenseEntry> all) {
    final set = <String>{};
    for (final e in all) {
      set.add(e.paidBy);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  List<String> _categoryOptions(List<ExpenseEntry> all) {
    final set = <String>{};
    for (final e in all) {
      set.add(e.category);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  List<ExpenseEntry> _apply(List<ExpenseEntry> all) {
    final query = _searchController.text.trim().toLowerCase();

    bool matchesSearch(ExpenseEntry e) {
      if (query.isEmpty) return true;
      return e.description.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query) ||
          e.paidBy.toLowerCase().contains(query) ||
          e.amount.toString().contains(query);
    }

    bool matchesDate(ExpenseEntry e) {
      final now = DateTime.now();
      switch (_filter.dateRange) {
        case AnalyticsDateRange.allTime:
          return true;
        case AnalyticsDateRange.today:
          return e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day;
        case AnalyticsDateRange.thisWeek:
          final start = now.subtract(Duration(days: now.weekday - 1));
          final startDay = DateTime(start.year, start.month, start.day);
          final endDay = startDay.add(const Duration(days: 7));
          return !e.date.isBefore(startDay) && e.date.isBefore(endDay);
        case AnalyticsDateRange.thisMonth:
          return e.date.year == now.year && e.date.month == now.month;
      }
    }

    bool matchesPaidBy(ExpenseEntry e) {
      final p = _filter.paidBy;
      if (p == null || p == 'All') return true;
      return e.paidBy == p;
    }

    bool matchesCategory(ExpenseEntry e) {
      final c = _filter.category;
      if (c == null || c == 'All') return true;
      return e.category == c;
    }

    return all
        .where(matchesSearch)
        .where(matchesDate)
        .where(matchesPaidBy)
        .where(matchesCategory)
        .toList();
  }
}

class _ExpenseRow extends StatelessWidget {
  final ExpenseEntry entry;

  const _ExpenseRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final amountFormat = NumberFormat('#,##0', 'en_US');

    final icon = _categoryIcon(entry.category);
    final bg = _categoryBg(entry.category);
    final ic = _categoryIconColor(entry.category);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: ic),
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
                      'Paid by ${entry.paidBy} • ${dateFormat.format(entry.date)}',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountFormat.format(entry.amount),
                    style: AppTextStyles.title,
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

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('electric')) return Icons.bolt;
    if (c.contains('transport') || c.contains('delivery')) {
      return Icons.local_shipping;
    }
    if (c.contains('food') || c.contains('dining') || c.contains('lunch')) {
      return Icons.restaurant;
    }
    if (c.contains('office') || c.contains('suppl')) return Icons.shopping_cart;
    return Icons.receipt_long;
  }

  Color _categoryBg(String category) {
    final c = category.toLowerCase();
    if (c.contains('electric')) return const Color(0xFFE8F5E9);
    if (c.contains('transport') || c.contains('delivery')) {
      return const Color(0xFFF3E5F5);
    }
    if (c.contains('food') || c.contains('dining') || c.contains('lunch')) {
      return const Color(0xFFEDE9FE);
    }
    if (c.contains('office') || c.contains('suppl')) {
      return const Color(0xFFE8F5E9);
    }
    return const Color(0xFFEFF6FF);
  }

  Color _categoryIconColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('electric')) return const Color(0xFF2E7D32);
    if (c.contains('transport') || c.contains('delivery')) {
      return const Color(0xFF6A1B9A);
    }
    if (c.contains('food') || c.contains('dining') || c.contains('lunch')) {
      return const Color(0xFF6D28D9);
    }
    if (c.contains('office') || c.contains('suppl')) {
      return const Color(0xFF2E7D32);
    }
    return const Color(0xFF1D4ED8);
  }
}

enum AnalyticsDateRange { allTime, today, thisWeek, thisMonth }

class AnalyticsFilter {
  final AnalyticsDateRange dateRange;
  final String? paidBy;
  final String? category;

  const AnalyticsFilter({
    this.dateRange = AnalyticsDateRange.allTime,
    this.paidBy,
    this.category,
  });

  AnalyticsFilter copyWith({
    AnalyticsDateRange? dateRange,
    String? paidBy,
    String? category,
  }) {
    return AnalyticsFilter(
      dateRange: dateRange ?? this.dateRange,
      paidBy: paidBy ?? this.paidBy,
      category: category ?? this.category,
    );
  }
}

class FilterExpensesSheet extends StatefulWidget {
  final AnalyticsFilter initial;
  final List<String> paidByOptions;
  final List<String> categoryOptions;

  const FilterExpensesSheet({
    super.key,
    required this.initial,
    required this.paidByOptions,
    required this.categoryOptions,
  });

  @override
  State<FilterExpensesSheet> createState() => _FilterExpensesSheetState();
}

class _FilterExpensesSheetState extends State<FilterExpensesSheet> {
  late AnalyticsFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 10,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Text('Filter Expenses', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(
              'Fill in your information to begin the process.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            _sectionTitle(
              icon: Icons.calendar_month_outlined,
              title: 'Date Range',
            ),
            const SizedBox(height: 10),
            _twoByTwoChips(
              labels: const ['All Time', 'Today', 'This Week', 'This Month'],
              selectedIndex: _dateSelectedIndex(_filter.dateRange),
              onSelect: (i) => setState(() {
                _filter = _filter.copyWith(dateRange: _dateFromIndex(i));
              }),
            ),
            const SizedBox(height: 16),
            _sectionTitle(icon: Icons.person_outline, title: 'Paid By'),
            const SizedBox(height: 10),
            _twoByTwoChips(
              labels: _paidByChipLabels(),
              selectedIndex: _paidBySelectedIndex(),
              onSelect: (i) => setState(() {
                _filter = _filter.copyWith(paidBy: _paidByChipLabels()[i]);
              }),
            ),
            const SizedBox(height: 16),
            _sectionTitle(
              icon: Icons.grid_view_outlined,
              title: 'Expense Category',
            ),
            const SizedBox(height: 10),
            _categoryGrid(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, widget.initial),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text('Add Expense'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _filter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Add Expense'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _twoByTwoChips({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    final cells = labels.take(4).toList();
    while (cells.length < 4) {
      cells.add('');
    }

    Widget chip(String text, bool selected, VoidCallback onTap) {
      return InkWell(
        onTap: text.isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: chip(cells[0], selectedIndex == 0, () => onSelect(0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: chip(cells[1], selectedIndex == 1, () => onSelect(1)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: chip(cells[2], selectedIndex == 2, () => onSelect(2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: chip(cells[3], selectedIndex == 3, () => onSelect(3)),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _paidByChipLabels() {
    final base = widget.paidByOptions.take(4).toList();
    while (base.length < 4) {
      base.add('');
    }
    return base;
  }

  int _paidBySelectedIndex() {
    final labels = _paidByChipLabels();
    final p = _filter.paidBy ?? 'All';
    final idx = labels.indexOf(p);
    return idx < 0 ? 0 : idx;
  }

  int _dateSelectedIndex(AnalyticsDateRange range) {
    switch (range) {
      case AnalyticsDateRange.allTime:
        return 0;
      case AnalyticsDateRange.today:
        return 1;
      case AnalyticsDateRange.thisWeek:
        return 2;
      case AnalyticsDateRange.thisMonth:
        return 3;
    }
  }

  AnalyticsDateRange _dateFromIndex(int index) {
    switch (index) {
      case 1:
        return AnalyticsDateRange.today;
      case 2:
        return AnalyticsDateRange.thisWeek;
      case 3:
        return AnalyticsDateRange.thisMonth;
      case 0:
      default:
        return AnalyticsDateRange.allTime;
    }
  }

  Widget _categoryGrid() {
    final labels = widget.categoryOptions;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: labels.length.clamp(0, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 12,
        childAspectRatio: 3.2,
      ),
      itemBuilder: (context, index) {
        final text = labels[index];
        final selected = (_filter.category ?? 'All') == text;
        return InkWell(
          onTap: () =>
              setState(() => _filter = _filter.copyWith(category: text)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
