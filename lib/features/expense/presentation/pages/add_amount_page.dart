import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class AddAmountPage extends StatefulWidget {
  const AddAmountPage({super.key});

  @override
  State<AddAmountPage> createState() => _AddAmountPageState();
}

class _AddAmountPageState extends State<AddAmountPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSource;

  // All Pakistan banks list
  final List<String> _sources = [
    'Cash',
    'HBL - Habib Bank Limited',
    'UBL - United Bank Limited',
    'MCB - Muslim Commercial Bank',
    'ABL - Allied Bank Limited',
    'NBP - National Bank of Pakistan',
    'Bank Alfalah',
    'Meezan Bank',
    'Faysal Bank',
    'Bank Al Habib',
    'Askari Bank',
    'Standard Chartered Pakistan',
    'Summit Bank',
    'Silk Bank',
    'Soneri Bank',
    'JS Bank',
    'BankIslami Pakistan',
    'Dubai Islamic Bank Pakistan',
    'Bank of Punjab',
    'Sindh Bank',
    'Bank of Khyber',
    'First Women Bank',
    'SME Bank',
    'Zarai Taraqiati Bank',
    'EasyPaisa (Telenor Bank)',
    'JazzCash (Mobilink Bank)',
    'SadaPay',
    'NayaPay',
  ];

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

              // Select Source (Pakistan banks)
              _buildLabel('Select Source'),
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: const InputDecoration(
                  hintText: 'Select Source',
                  prefixIcon: Icon(
                    Icons.account_balance_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
                isExpanded: true,
                items: _sources.map((String bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(
                      bank,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSource = val),
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
