import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Bank model with name, short code, icon, and color.
class BankOption {
  final String name;
  final String shortCode;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const BankOption({
    required this.name,
    required this.shortCode,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });
}

/// All bank options used across the app (shared list).
final List<BankOption> appBankOptions = [
  const BankOption(
    name: 'By Cash',
    shortCode: 'Cash',
    icon: Icons.monetization_on,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF4CAF50),
  ),
  const BankOption(
    name: 'Allied Bank Limited (ABL)',
    shortCode: 'ABL',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFFFEBEE),
    iconColor: Color(0xFFC62828),
  ),
  const BankOption(
    name: 'Bank Alfalah',
    shortCode: 'Alfalah',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE3F2FD),
    iconColor: Color(0xFF1565C0),
  ),
  const BankOption(
    name: 'National Bank of Pakistan (NBP)',
    shortCode: 'NBP',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF2E7D32),
  ),
  const BankOption(
    name: 'Habib Bank Limited (HBL)',
    shortCode: 'HBL',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF388E3C),
  ),
  const BankOption(
    name: 'Meezan Bank',
    shortCode: 'Meezan',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFF3E5F5),
    iconColor: Color(0xFF6A1B9A),
  ),
  const BankOption(
    name: 'Faysal Bank',
    shortCode: 'Faysal',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF1B5E20),
  ),
  const BankOption(
    name: 'United Bank Limited (UBL)',
    shortCode: 'UBL',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE3F2FD),
    iconColor: Color(0xFF0D47A1),
  ),
  const BankOption(
    name: 'MCB Bank',
    shortCode: 'MCB',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFFFF3E0),
    iconColor: Color(0xFFE65100),
  ),
  const BankOption(
    name: 'Bank Al Habib',
    shortCode: 'BAH',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE3F2FD),
    iconColor: Color(0xFF1976D2),
  ),
  const BankOption(
    name: 'Askari Bank',
    shortCode: 'Askari',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFFCE4EC),
    iconColor: Color(0xFFAD1457),
  ),
  const BankOption(
    name: 'Standard Chartered Pakistan',
    shortCode: 'SCB',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF2E7D32),
  ),
  const BankOption(
    name: 'BankIslami Pakistan',
    shortCode: 'BIslami',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF00695C),
  ),
  const BankOption(
    name: 'Dubai Islamic Bank Pakistan',
    shortCode: 'DIB',
    icon: Icons.account_balance,
    iconBgColor: Color(0xFFFFF8E1),
    iconColor: Color(0xFFFF8F00),
  ),
  const BankOption(
    name: 'EasyPaisa (Telenor Bank)',
    shortCode: 'EasyPaisa',
    icon: Icons.phone_android,
    iconBgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF388E3C),
  ),
  const BankOption(
    name: 'JazzCash (Mobilink Bank)',
    shortCode: 'JazzCash',
    icon: Icons.phone_android,
    iconBgColor: Color(0xFFFFEBEE),
    iconColor: Color(0xFFC62828),
  ),
  const BankOption(
    name: 'SadaPay',
    shortCode: 'SadaPay',
    icon: Icons.phone_android,
    iconBgColor: Color(0xFF1A1A2E),
    iconColor: Colors.white,
  ),
  const BankOption(
    name: 'NayaPay',
    shortCode: 'NayaPay',
    icon: Icons.phone_android,
    iconBgColor: Color(0xFFE3F2FD),
    iconColor: Color(0xFF1565C0),
  ),
];

class AddAmountPage extends StatefulWidget {
  const AddAmountPage({super.key});

  @override
  State<AddAmountPage> createState() => _AddAmountPageState();
}

class _AddAmountPageState extends State<AddAmountPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  BankOption? _selectedBank;

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
    // Return the amount to the home page
    Navigator.pop(context, amount);
  }

  void _showBankSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _BankSelectionSheet(
          banks: appBankOptions,
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
                padding: const EdgeInsets.symmetric(vertical: 8),
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
