import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/firebase/current_user_context.dart';
import '../../../../core/firebase/users_directory_data_source.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../domain/entities/expense_entry.dart';
import 'add_amount_page.dart'; // For BankOption & appBankOptions
import '../../../banks/presentation/store/banks_store.dart';
import '../store/transactions_store.dart';
import 'amount_added_by_user_page.dart';

/// Category model with name, icon, and color.
class CategoryOption {
  final String name;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const CategoryOption({
    required this.name,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });
}

/// Predefined expense categories matching the screenshot.
final List<CategoryOption> appCategoryOptions = [
  const CategoryOption(
    name: 'Office Supplies',
    icon: Icons.shopping_cart,
    iconBgColor: Color(0xFFE3F2FD),
    iconColor: Color(0xFF1565C0),
  ),
  const CategoryOption(
    name: 'Personal Expense',
    icon: Icons.home,
    iconBgColor: Color(0xFFFFEBEE),
    iconColor: Color(0xFFC62828),
  ),
  const CategoryOption(
    name: 'Transport',
    icon: Icons.local_shipping,
    iconBgColor: Color(0xFFF3E5F5),
    iconColor: Color(0xFF6A1B9A),
  ),
  const CategoryOption(
    name: 'Electricity',
    icon: Icons.bolt,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF2E7D32),
  ),
  const CategoryOption(
    name: 'Miscellaneous Expenses',
    icon: Icons.grid_view,
    iconBgColor: Color(0xFFE3F2FD),
    iconColor: Color(0xFF1976D2),
  ),
  const CategoryOption(
    name: 'Food & Dining',
    icon: Icons.restaurant,
    iconBgColor: Color(0xFFFFF3E0),
    iconColor: Color(0xFFE65100),
  ),
];

class SubmitExpensePage extends StatefulWidget {
  const SubmitExpensePage({super.key});

  @override
  State<SubmitExpensePage> createState() => _SubmitExpensePageState();
}

class _SubmitExpensePageState extends State<SubmitExpensePage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  BankOption? _selectedBank;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedPaidTo = '';
  List<String> _paidToTargets = const [];
  late final BanksStore _banksStore;
  late final CurrentUserContext _currentUserContext;
  late final UsersDirectoryDataSource _usersDirectory;
  late final TransactionsStore _transactionsStore;

  @override
  void initState() {
    super.initState();
    _banksStore = sl<BanksStore>();
    _currentUserContext = sl<CurrentUserContext>();
    _usersDirectory = sl<UsersDirectoryDataSource>();
    _transactionsStore = sl<TransactionsStore>();
    _banksStore.load();
    _transactionsStore.load();
    _loadPaidToTargets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitExpense() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: AppColors.redDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    await _ensureTransactionsLoaded();
    final ownerNameEarly = await _currentUserContext.resolvedName();
    if (!mounted) return;

    final txs = _transactionsStore.transactions;
    final uidMap = {ownerNameEarly.toLowerCase().trim(): _currentUserContext.uid};
    final bankLabel = (_selectedBank?.name ?? '').trim();
    final isCash =
        bankLabel.isEmpty || bankLabel == AmountAddedByUserPage.cashSourceLabel;

    if (!isCash) {
      final remaining = AmountAddedByUserPage.remainingForBankSourceRaw(
        displayName: ownerNameEarly,
        bankLabel: bankLabel,
        entries: txs,
        uidByNormalizedName: uidMap,
      );
      if (amount > remaining) {
        final fmt = NumberFormat('#,##0', 'en_US');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remaining <= 0
                  ? 'You have not added money from this bank. Add funds first or choose By Cash.'
                  : 'Only ${fmt.format(remaining)} available for this bank.',
            ),
            backgroundColor: AppColors.redDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
    }

    final availableBalance = txs.fold<double>(
      0,
      (sum, e) => sum + (e.isCredit ? e.amount : -e.amount),
    );
    if (amount > availableBalance) {
      _showInsufficientBalanceDialog(availableBalance: availableBalance);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final ownerUid = _currentUserContext.uid;
    final ownerName = ownerNameEarly;
    if (!mounted) return;
    final paidTo = _selectedPaidTo.trim().isEmpty ? ownerName : _selectedPaidTo;
    final entry = ExpenseEntry(
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : (_selectedCategory ?? 'Expense'),
      amount: amount,
      category: _selectedCategory ?? 'Miscellaneous Expenses',
      date: _selectedDate ?? today,
      time: _selectedTime ?? TimeOfDay.fromDateTime(now),
      paidBy: ownerName,
      addedBy: ownerName,
      ownerUid: ownerUid,
      ownerName: ownerName,
      paidTo: paidTo,
      bankName: _selectedBank?.name,
      kind: ExpenseEntryKind.expense,
      isCredit: false,
    );

    Navigator.pop(context, entry);
  }

  Future<void> _loadPaidToTargets() async {
    final ownerName = await _currentUserContext.resolvedName();
    final profiles = await _usersDirectory.getAllProfilesByUid();
    final unique = <String>{};
    for (final profile in profiles.values) {
      final name = profile.name.trim();
      if (name.isNotEmpty) unique.add(name);
    }
    if (!mounted) return;
    setState(() {
      _selectedPaidTo = '';
      _paidToTargets = [ownerName, ...unique.where((u) => u != ownerName)];
    });
  }

  void _showInsufficientBalanceDialog({required double availableBalance}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    showDialog<void>(
      context: context,
      builder: (context) {
        final maxSpend = availableBalance;
        return AlertDialog(
          title: const Text('Insufficient Balance'),
          content: Text(
            'Available balance is ${formatter.format(availableBalance)}.\n\n'
            'You can spend up to ${formatter.format(maxSpend)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ensureTransactionsLoaded() async {
    // TransactionsStore.load() is async but load() itself may no-op while loading.
    // This small retry loop ensures we don't validate against an empty list.
    for (var i = 0; i < 5; i++) {
      if (_transactionsStore.transactions.isNotEmpty ||
          (!_transactionsStore.loading && i > 0)) {
        return;
      }
      await _transactionsStore.load();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  // ── Bank Selection Bottom Sheet ──────────────────────────
  void _showBankSelectionSheet() {
    final banks = <BankOption>[
      // Always allow cash source
      ...appBankOptions.where((b) => b.shortCode == 'Cash'),
      // Only show locked/submitted banks like Add Amount page
      ..._banksStore.banks.where((b) => b.isSubmitted).map((b) {
        final short = b.name.trim().isEmpty
            ? 'BANK'
            : b.name.trim().split(' ').first;
        final acc = (b.accountNumber == null || b.accountNumber!.trim().isEmpty)
            ? null
            : 'A/C: ${b.accountNumber}';
        return BankOption(
          name: b.name,
          shortCode: short,
          icon: Icons.account_balance,
          iconBgColor: const Color(0xFFE3F2FD),
          iconColor: AppColors.primary,
          subtitle: acc,
        );
      }),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _BankSelectionSheet(
          banks: banks,
          selectedBank: _selectedBank,
          onSelected: (bank) {
            setState(() => _selectedBank = bank);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  // ── Category Selection Bottom Sheet ──────────────────────
  void _showCategorySelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _CategorySelectionSheet(
          categories: appCategoryOptions,
          selectedCategory: _selectedCategory,
          onSelected: (category) {
            setState(() => _selectedCategory = category);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text('Submit Expense', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount
              _buildLabel('Expense Amount (PKR)'),
              CustomTextField(
                hintText: 'Enter Amount',
                keyboardType: TextInputType.number,
                controller: _amountController,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                prefixIcon: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Category (Bottom Sheet)
              _buildLabel('Expense Category'),
              _buildSelectionField(
                text: _selectedCategory ?? 'Select Category',
                icon: Icons.grid_view_outlined,
                isSelected: _selectedCategory != null,
                onTap: _showCategorySelectionSheet,
              ),
              const SizedBox(height: 20),

              // Bank (Bottom Sheet)
              _buildLabel('Select Bank'),
              _buildSelectionField(
                text: _selectedBank?.name ?? 'Enter Bank',
                icon: Icons.account_balance_outlined,
                isSelected: _selectedBank != null,
                onTap: _showBankSelectionSheet,
              ),
              const SizedBox(height: 20),

              _buildLabel('Paid To'),
              _buildSelectionField(
                text: _selectedPaidTo.trim().isEmpty
                    ? 'Optional (Self/Personal by default)'
                    : _selectedPaidTo,
                icon: Icons.person_outline,
                isSelected: _selectedPaidTo.trim().isNotEmpty,
                onTap: _showPaidToSelectionSheet,
              ),
              const SizedBox(height: 20),

              // Date
              _buildLabel('Transaction Date'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                              : 'Enter Transaction Date',
                          style: _selectedDate != null
                              ? AppTextStyles.bodyMedium
                              : AppTextStyles.bodyRegular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time
              _buildLabel('Transaction Time'),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select Time',
                          style: _selectedTime != null
                              ? AppTextStyles.bodyMedium
                              : AppTextStyles.bodyRegular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Receipt
              _buildLabel('Receipt (Optional)'),
              _buildUploadBox(),
              const SizedBox(height: 20),

              // Description
              _buildLabel('Expense Description  (Optional)'),
              CustomTextField(
                hintText: 'Enter Expense Description',
                maxLines: 4,
                controller: _descriptionController,
              ),
              const SizedBox(height: 32),

              // Confirm
              SizedBox(
                width: double.infinity,
                child: CustomButton(text: 'Confirm', onPressed: _submitExpense),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaidToSelectionSheet() {
    final targets = _paidToTargets;
    if (targets.isEmpty) return;
    final ownerName = targets.first;
    final options = <String>['Self (Personal)', ...targets];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Paid To', style: AppTextStyles.heading3),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelf = option == 'Self (Personal)';
                      final targetValue = isSelf ? '' : option;
                      final selected = (isSelf && _selectedPaidTo.trim().isEmpty) ||
                          (!isSelf && _selectedPaidTo == targetValue);
                      return Material(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Icon(
                            isSelf ? Icons.person : Icons.business,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            isSelf ? option : option,
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: isSelf
                              ? Text(
                                  ownerName,
                                  style: AppTextStyles.caption,
                                )
                              : null,
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() => _selectedPaidTo = targetValue);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String text,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: isSelected
                    ? AppTextStyles.bodyMedium
                    : AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.attachment,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload Proof',
            style: AppTextStyles.title.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Format should be in .pdf .jpeg .png less than 5MB',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Bank Selection Bottom Sheet ──────────────────────────────────
class _BankSelectionSheet extends StatelessWidget {
  final List<BankOption> banks;
  final BankOption? selectedBank;
  final ValueChanged<BankOption> onSelected;
  static const _silverDivider = Color(0xFFD1D5DB);

  const _BankSelectionSheet({
    required this.banks,
    required this.selectedBank,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 72),
                itemCount: banks.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 20,
                  color: _silverDivider,
                ),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  final isSelected = selectedBank?.name == bank.name;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bank.iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(bank.icon, color: bank.iconColor, size: 20),
                    ),
                    title: Text(
                      bank.name,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: bank.subtitle == null
                        ? null
                        : Text(
                            bank.subtitle!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    onTap: () => onSelected(bank),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Selection Bottom Sheet ──────────────────────────────
class _CategorySelectionSheet extends StatefulWidget {
  final List<CategoryOption> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategorySelectionSheet({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  State<_CategorySelectionSheet> createState() =>
      _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<_CategorySelectionSheet> {
  final _customCategoryController = TextEditingController();
  static const _silverDivider = Color(0xFFD1D5DB);

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.categories.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 20,
                  color: _silverDivider,
                ),
                itemBuilder: (context, index) {
                  final cat = widget.categories[index];
                  final isSelected = widget.selectedCategory == cat.name;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cat.iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, color: cat.iconColor, size: 20),
                    ),
                    title: Text(
                      cat.name,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    onTap: () => widget.onSelected(cat.name),
                  );
                },
              ),
            ),
            // Add Custom Category section
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Custom Category',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _customCategoryController,
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Enter Expense Category',
                              hintStyle: AppTextStyles.bodyRegular.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          final custom = _customCategoryController.text.trim();
                          if (custom.isNotEmpty) {
                            widget.onSelected(custom);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
