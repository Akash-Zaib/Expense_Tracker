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
  // const CategoryOption(
  //   name: 'Office Supplies',
  //   icon: Icons.shopping_cart,
  //   iconBgColor: Color(0xFFE3F2FD),
  //   iconColor: Color(0xFF1565C0),
  // ),
  const CategoryOption(
    name: 'Personal Expense',
    icon: Icons.home,
    iconBgColor: Color(0xFFFFEBEE),
    iconColor: Color.fromARGB(255, 40, 108, 198),
  ),
  // const CategoryOption(
  //   name: 'Transport',
  //   icon: Icons.local_shipping,
  //   iconBgColor: Color(0xFFF3E5F5),
  //   iconColor: Color(0xFF6A1B9A),
  // ),
  // const CategoryOption(
  //   name: 'Electricity',
  //   icon: Icons.bolt,
  //   iconBgColor: Color(0xFFE8F5E9),
  //   iconColor: Color(0xFF2E7D32),
  // ),
  // const CategoryOption(
  //   name: 'Miscellaneous Expenses',
  //   icon: Icons.grid_view,
  //   iconBgColor: Color(0xFFE3F2FD),
  //   iconColor: Color(0xFF1976D2),
  // ),
  // const CategoryOption(
  //   name: 'Food & Dining',
  //   icon: Icons.restaurant,
  //   iconBgColor: Color(0xFFFFF3E0),
  //   iconColor: Color(0xFFE65100),
  // ),
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

  /// All registered users (sorted) shown in category bottom sheet.
  List<String> _registeredUserNames = const [];

  /// Optional assignee selected in category bottom sheet.
  String? _selectedAssigneeName;
  late final BanksStore _banksStore;
  late final CurrentUserContext _currentUserContext;
  late final UsersDirectoryDataSource _usersDirectory;
  late final TransactionsStore _transactionsStore;

  String _toUpperCamelWords(String input) {
    final normalized = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';
    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _banksStore = sl<BanksStore>();
    _currentUserContext = sl<CurrentUserContext>();
    _usersDirectory = sl<UsersDirectoryDataSource>();
    _transactionsStore = sl<TransactionsStore>();
    _banksStore.startWatching();
    _transactionsStore.load();
    _loadPaidToTargetsAndDirectory();
  }

  @override
  void dispose() {
    _banksStore.stopWatching();
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
    final uidMap = {
      ownerNameEarly.toLowerCase().trim(): _currentUserContext.uid,
    };
    final bankLabel = (_selectedBank?.name ?? '').trim();
    final sourceLabel = bankLabel.isEmpty
        ? AmountAddedByUserPage.cashSourceLabel
        : bankLabel;
    final isCash = sourceLabel == AmountAddedByUserPage.cashSourceLabel;
    final remainingForSource = AmountAddedByUserPage.remainingForBankSourceRaw(
      displayName: ownerNameEarly,
      bankLabel: sourceLabel,
      entries: txs,
      uidByNormalizedName: uidMap,
    );
    if (amount > remainingForSource) {
      final fmt = NumberFormat('#,##0', 'en_US');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remainingForSource <= 0
                ? (isCash
                      ? 'You have not added cash yet. Add amount first.'
                      : 'You have not added money from this bank. Add funds first or choose By Cash.')
                : 'Only ${fmt.format(remainingForSource)} available for $sourceLabel.',
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
    final paidTo = _selectedAssigneeName?.trim().isNotEmpty == true
        ? _selectedAssigneeName!.trim()
        : ownerName;
    final typedDescription = _descriptionController.text.trim();
    final entry = ExpenseEntry(
      description: typedDescription.isNotEmpty
          ? _toUpperCamelWords(typedDescription)
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

  Future<void> _loadPaidToTargetsAndDirectory() async {
    final profiles = await _usersDirectory.getAllProfilesByUid();
    final unique = <String>{};
    for (final profile in profiles.values) {
      final name = profile.name.trim();
      if (name.isNotEmpty) unique.add(name);
    }
    final sortedAll = unique.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _registeredUserNames = sortedAll;
      if (_selectedAssigneeName != null &&
          !_registeredUserNames.contains(_selectedAssigneeName)) {
        _selectedAssigneeName = null;
      }
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
    final currentUid = _currentUserContext.uid;
    final banks = <BankOption>[
      // Always allow cash source
      ...appBankOptions.where((b) => b.shortCode == 'Cash'),
      // Only current logged-in user's banks.
      ..._banksStore.banks.where((b) => b.ownerUid == currentUid).map((b) {
        final short = b.name.trim().isEmpty
            ? 'BANK'
            : b.name.trim().split(' ').first;
        final acc = (b.accountNumber == null || b.accountNumber!.trim().isEmpty)
            ? null
            : 'A/C: ${b.accountNumber}';
        final belongs = b.ownerName.trim();
        final subtitleParts = <String>[];
        if (belongs.isNotEmpty) subtitleParts.add('Belongs to: $belongs');
        if (acc != null) subtitleParts.add(acc);
        return BankOption(
          name: b.name,
          shortCode: short,
          selectionKey: '${b.ownerUid}::${b.id}',
          icon: Icons.account_balance,
          iconBgColor: const Color(0xFFE3F2FD),
          iconColor: AppColors.primary,
          subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' · '),
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
          assigneeOptions: _registeredUserNames,
          selectedCategory: _selectedCategory,
          selectedAssignee: _selectedAssigneeName,
          onSelected: ({required category, assignee}) {
            setState(() {
              _selectedCategory = category;
              _selectedAssigneeName = assignee;
            });
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
              _buildLabel('Purpose'),
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
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 20,
                  color: _silverDivider,
                ),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  final isSelected =
                      selectedBank?.selectionKey == bank.selectionKey;
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
  final List<String> assigneeOptions;
  final String? selectedCategory;
  final String? selectedAssignee;
  final void Function({required String category, String? assignee}) onSelected;

  const _CategorySelectionSheet({
    required this.categories,
    required this.assigneeOptions,
    required this.selectedCategory,
    required this.selectedAssignee,
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
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + bottomSafe + 20,
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Purpose', style: AppTextStyles.heading3),
            ),
            const SizedBox(height: 20),
            Flexible(
              flex: 1,
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.categories.length,
                itemBuilder: (context, index) {
                  final cat = widget.categories[index];
                  final isSelected = widget.selectedCategory == cat.name;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.55)
                              : _silverDivider,
                        ),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.white,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
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
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.4,
                                    ),
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
                        onTap: () => widget.onSelected(
                          category: cat.name,
                          assignee: null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.assigneeOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Flexible(
                flex: 2,
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: widget.assigneeOptions.length,
                  itemBuilder: (context, index) {
                    final name = widget.assigneeOptions[index];
                    final selected =
                        widget.selectedCategory == name &&
                        widget.selectedAssignee == name;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : _silverDivider,
                          ),
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.white,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.4,
                                      ),
                                width: 2,
                              ),
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          onTap: () {
                            widget.onSelected(category: name, assignee: name);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            // Add Custom Category section
            Padding(
              padding: const EdgeInsets.only(
                left: 2,
                right: 2,
                top: 16,
                bottom: 12,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _silverDivider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Custom Category',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            final custom = _customCategoryController.text
                                .trim();
                            if (custom.isNotEmpty) {
                              widget.onSelected(
                                category: custom,
                                assignee: null,
                              );
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
            ),
          ],
        ),
      ),
    );
  }
}
