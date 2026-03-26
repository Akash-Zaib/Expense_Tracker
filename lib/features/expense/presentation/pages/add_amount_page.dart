import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../banks/presentation/store/banks_store.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class AddAmountResult {
  final double amount;
  final String description;
  final String? bankName;

  const AddAmountResult({
    required this.amount,
    required this.description,
    required this.bankName,
  });
}

/// Bank model with name, short code, icon, and color.
class BankOption {
  final String name;
  final String shortCode;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String? subtitle;

  const BankOption({
    required this.name,
    required this.shortCode,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.subtitle,
  });
}

const BankOption _cashOption = BankOption(
  name: 'By Cash',
  shortCode: 'Cash',
  icon: Icons.monetization_on,
  iconBgColor: Color(0xFFE8F5E9),
  iconColor: Color(0xFF4CAF50),
);

/// Legacy export used by other pages.
/// Prefer building options from `BanksStore` instead (Wallet-saved banks).
@Deprecated('Use BanksStore-based dynamic options')
final List<BankOption> appBankOptions = [_cashOption];

class AddAmountPage extends StatefulWidget {
  const AddAmountPage({super.key});

  @override
  State<AddAmountPage> createState() => _AddAmountPageState();
}

class _AddAmountPageState extends State<AddAmountPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  BankOption? _selectedBank;
  late final BanksStore _banksStore;

  @override
  void initState() {
    super.initState();
    _banksStore = sl<BanksStore>();
    _banksStore.load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: AppColors.redDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final desc = _descriptionController.text.trim().isEmpty
        ? 'Amount Added'
        : _descriptionController.text.trim();

    Navigator.pop(
      context,
      AddAmountResult(
        amount: amount,
        description: desc,
        bankName: _selectedBank?.name ?? 'By Cash',
      ),
    );
  }

  void _showBankSelectionSheet() {
    final banks = <BankOption>[
      _cashOption,
      ..._banksStore.banks.where((b) => b.isSubmitted).map((b) {
        final short = b.name.trim().isEmpty ? 'BANK' : b.name.trim().split(' ').first;
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
        title: Text('Add Amount', style: AppTextStyles.heading3),
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
              _buildLabel('Amount'),
              CustomTextField(
                hintText: 'Amount You Have',
                keyboardType: TextInputType.number,
                controller: _amountController,
                prefixIcon: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Select Source (Bank selection bottom sheet)
              _buildLabel('Select Source'),
              GestureDetector(
                onTap: _showBankSelectionSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedBank?.name ?? 'Select Source',
                          style: _selectedBank != null
                              ? AppTextStyles.bodyMedium
                              : AppTextStyles.bodyRegular
                                  .copyWith(color: AppColors.textSecondary),
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
              ),
              const SizedBox(height: 20),

              // Receipt (Optional)
              _buildLabel('Receipt (Optional)'),
              _buildUploadBox(),
              const SizedBox(height: 20),

              // Expense Description (Optional)
              _buildLabel('Expense Description  (Optional)'),
              CustomTextField(
                hintText: 'Enter Expense Description',
                maxLines: 4,
                controller: _descriptionController,
              ),
              const SizedBox(height: 32),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Confirm',
                  onPressed: _confirm,
                ),
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

// ── Reusable Bank Selection Bottom Sheet ──────────────────────────
class _BankSelectionSheet extends StatelessWidget {
  final List<BankOption> banks;
  final BankOption? selectedBank;
  final ValueChanged<BankOption> onSelected;

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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Source', style: AppTextStyles.heading3),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 72),
                itemCount: banks.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  final isSelected = selectedBank?.name == bank.name;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
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
