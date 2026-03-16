import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';

/// Model for an expense entry.
class ExpenseEntry {
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final TimeOfDay time;
  final String paidBy;
  final bool isCredit; // true = green (you/personal), false = red (other user)

  const ExpenseEntry({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.time,
    required this.paidBy,
    this.isCredit = false,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

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

  Future<void> _navigateToAddAmount() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addAmount);
    if (result != null && result is double) {
      setState(() {
        _availableBalance += result;
      });
    }
  }

  Future<void> _navigateToSubmitExpense() async {
    final result = await Navigator.pushNamed(context, AppRoutes.submitExpense);
    if (result != null && result is ExpenseEntry) {
      setState(() {
        _entries.insert(0, result);
        if (!result.isCredit) {
          _availableBalance -= result.amount;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBalanceSection(),
              const SizedBox(height: 24),
              _buildGridSection(),
              const SizedBox(height: 24),
              _buildRecentActivitySection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: FloatingActionButton(
          onPressed: _navigateToSubmitExpense,
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HEADER (matches Figma exactly) ────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Logic Worms', style: AppTextStyles.title),
                Text(
                  '3 Partners',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () {},
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  // ── BALANCE SECTION (matches Figma) ───────────────────────
  Widget _buildBalanceSection() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance', style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(_dateRange, style: AppTextStyles.caption),
                ],
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatter.format(_availableBalance),
                    style: AppTextStyles.heading1.copyWith(fontSize: 32),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.open_in_new, color: AppColors.primary, size: 20),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _navigateToAddAmount,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Cash'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // ── EXPENSE GRID (matches Figma) ──────────────────────────
  Widget _buildGridSection() {
    final formatter = NumberFormat('#,##0', 'en_US');
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildExpenseCard(
                title: 'My Personal Expenses',
                amount: formatter.format(_myExpenses),
                bgColor: AppColors.greenLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExpenseCard(
                title: "Badar's Expenses",
                amount: formatter.format(_badarExpenses),
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
                amount: formatter.format(_logicWormsExpenses),
                bgColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExpenseCard(
                title: 'Rovynx Expenses',
                amount: formatter.format(_rovynxExpenses),
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
                child: Text(
                  amount,
                  style: AppTextStyles.heading3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.open_in_new, color: AppColors.primary, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  // ── RECENT ACTIVITY (matches Figma) ───────────────────────
  Widget _buildRecentActivitySection() {
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
          if (_entries.isEmpty)
            _buildEmptyState()
          else
            ..._entries.map((entry) => _buildActivityItem(entry)),
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
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.description, style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Paid by ${entry.paidBy} • ${dateFormat.format(entry.date)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatter.format(entry.amount),
                      style: AppTextStyles.title,
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
