import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/di/injection_container.dart';

import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../domain/entities/expense_entry.dart';
import '../store/transactions_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  late final TransactionsStore _transactionsStore;

  // Dummy data – will be replaced with Firebase data later
  double _availableBalance = 22450;
  final String _dateRange = '1 Feb 2026 - 30 Feb 2026';
  final double _myExpenses = 12000;
  final double _badarExpenses = 12000;
  final double _logicWormsExpenses = 12000;
  final double _rovynxExpenses = 12000;

  final List<ExpenseEntry> _entries = [
    ExpenseEntry(
      description: 'Wholesale Purchase',
      amount: 450,
      category: 'Office Supplies',
      date: DateTime(2026, 2, 18),
      time: const TimeOfDay(hour: 14, minute: 30),
      paidBy: 'Saeed',
      isCredit: true,
    ),
    ExpenseEntry(
      description: 'Electricity Bill',
      amount: 1125,
      category: 'Electricity',
      date: DateTime(2026, 2, 17),
      time: const TimeOfDay(hour: 10, minute: 0),
      paidBy: 'You',
      isCredit: false,
    ),
    ExpenseEntry(
      description: 'Delivery Charges',
      amount: 450,
      category: 'Transport',
      date: DateTime(2026, 2, 16),
      time: const TimeOfDay(hour: 9, minute: 15),
      paidBy: 'Saeed',
      isCredit: true,
    ),
    ExpenseEntry(
      description: 'Office Supplies',
      amount: 6220,
      category: 'Miscellaneous Expenses',
      date: DateTime(2026, 2, 15),
      time: const TimeOfDay(hour: 16, minute: 45),
      paidBy: 'Badar',
      isCredit: false,
    ),
  ];

  // Tab pages for bottom nav
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _transactionsStore = sl<TransactionsStore>();
    _transactionsStore.seedIfEmpty(_entries);
    _pages = [
      _HomeContent(
        availableBalance: _availableBalance,
        dateRange: _dateRange,
        myExpenses: _myExpenses,
        badarExpenses: _badarExpenses,
        logicWormsExpenses: _logicWormsExpenses,
        rovynxExpenses: _rovynxExpenses,
        entries: _entries,
        onAddCash: _navigateToAddAmount,
        onSubmitExpense: _navigateToSubmitExpense,
      ),
      const AnalyticsPage(), // TODO: Replace with actual analytics page
      const WalletPage(), // TODO: Replace with actual wallet page
      const SettingsPage(), // TODO: Replace with actual settings page
    ];
  }

  void _rebuildHomeContent() {
    _pages[0] = _HomeContent(
      availableBalance: _availableBalance,
      dateRange: _dateRange,
      myExpenses: _myExpenses,
      badarExpenses: _badarExpenses,
      logicWormsExpenses: _logicWormsExpenses,
      rovynxExpenses: _rovynxExpenses,
      entries: _entries,
      onAddCash: _navigateToAddAmount,
      onSubmitExpense: _navigateToSubmitExpense,
    );
  }

  Future<void> _navigateToAddAmount() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addAmount);
    if (result != null && result is double) {
      setState(() {
        _availableBalance += result;
        _rebuildHomeContent();
      });
    }
  }

  Future<void> _navigateToSubmitExpense() async {
    final result = await Navigator.pushNamed(context, AppRoutes.submitExpense);
    if (result != null && result is ExpenseEntry) {
      setState(() {
        _entries.insert(0, result);
        _transactionsStore.add(result);
        if (!result.isCredit) {
          _availableBalance -= result.amount;
        }
        _rebuildHomeContent();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _currentNavIndex, children: _pages),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: _currentNavIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 84, right: 10),
              child: FloatingActionButton(
                onPressed: _navigateToSubmitExpense,
                backgroundColor: AppColors.primary,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── BOTTOM NAV (matches Figma) ────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      color: const Color(0xFF1F1F1F),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 0),
            _buildNavItem(Icons.bar_chart, 1),
            _buildNavItem(Icons.account_balance_wallet, 2),
            _buildNavItem(Icons.settings, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 28),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── HOME CONTENT (extracted so it can be used in IndexedStack) ───
class _HomeContent extends StatelessWidget {
  final double availableBalance;
  final String dateRange;
  final double myExpenses;
  final double badarExpenses;
  final double logicWormsExpenses;
  final double rovynxExpenses;
  final List<ExpenseEntry> entries;
  final VoidCallback onAddCash;
  final VoidCallback onSubmitExpense;

  const _HomeContent({
    required this.availableBalance,
    required this.dateRange,
    required this.myExpenses,
    required this.badarExpenses,
    required this.logicWormsExpenses,
    required this.rovynxExpenses,
    required this.entries,
    required this.onAddCash,
    required this.onSubmitExpense,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildBalanceSection(context),
          const SizedBox(height: 24),
          _buildGridSection(context),
          const SizedBox(height: 24),
          _buildRecentActivitySection(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── HEADER (matches Figma exactly) ────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              // Avatar with badge
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

  // ── BALANCE SECTION (overflow-safe) ───────────────────────
  Widget _buildBalanceSection(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + calendar icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Balance', style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text(dateRange, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.blueLight,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balance amount + Add Cash button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatter.format(availableBalance),
                          style: AppTextStyles.heading1.copyWith(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.open_in_new,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onAddCash,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Cash'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── EXPENSE GRID (overflow-safe) ──────────────────────────
  Widget _buildGridSection(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildExpenseCard(
                title: 'My Personal Expenses',
                amount: formatter.format(myExpenses),
                bgColor: AppColors.greenLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExpenseCard(
                title: "Badar's Expenses",
                amount: formatter.format(badarExpenses),
                bgColor: AppColors.redLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildExpenseCard(
                title: 'Logic Worms Expenses',
                amount: formatter.format(logicWormsExpenses),
                bgColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExpenseCard(
                title: 'Rovynx Expenses',
                amount: formatter.format(rovynxExpenses),
                bgColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseCard({
    required String title,
    required String amount,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: bgColor == Colors.white
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(amount, style: AppTextStyles.heading3),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, color: AppColors.primary, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  // ── RECENT ACTIVITY (overflow-safe) ───────────────────────
  Widget _buildRecentActivitySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: AppTextStyles.title),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            _buildEmptyState()
          else
            ...entries.map((entry) => _buildActivityItem(entry)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first expense',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ExpenseEntry entry) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final formatter = NumberFormat('#,##0', 'en_US');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: entry.isCredit ? AppColors.greenLight : AppColors.redLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color indicator bar on left
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: entry.isCredit ? AppColors.greenDark : AppColors.redDark,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.description,
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paid by ${entry.paidBy} • ${dateFormat.format(entry.date)}',
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatter.format(entry.amount),
                          style: AppTextStyles.title,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
