import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import 'home_page.dart';

class SubmitExpensePage extends StatefulWidget {
  const SubmitExpensePage({super.key});

  @override
  State<SubmitExpensePage> createState() => _SubmitExpensePageState();
}

class _SubmitExpensePageState extends State<SubmitExpensePage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedBank;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> categories = [
    'Office Supplies',
    'Personal Expense',
    'Transport',
    'Electricity',
    'Miscellaneous Expenses',
    'Food & Dining',
  ];

  // All Pakistan banks
  final List<String> banks = [
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

  void _submitExpense() {
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

    final entry = ExpenseEntry(
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : (_selectedCategory ?? 'Expense'),
      amount: amount,
      category: _selectedCategory ?? 'Miscellaneous Expenses',
      date: _selectedDate ?? DateTime.now(),
      time: _selectedTime ?? TimeOfDay.now(),
      paidBy: 'You',
      isCredit: false,
    );

    Navigator.pop(context, entry);
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
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.primary),
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
                prefixIcon: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Expense Category'),
              _buildDropdown(
                hint: 'Select Category',
                icon: Icons.grid_view_outlined,
                items: categories,
                value: _selectedCategory,
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 20),

              // Bank
              _buildLabel('Select Bank'),
              _buildDropdown(
                hint: 'Enter Bank',
                icon: Icons.account_balance_outlined,
                items: banks,
                value: _selectedBank,
                onChanged: (val) => setState(() => _selectedBank = val),
              ),
              const SizedBox(height: 20),

              // Date
              _buildLabel('Transaction Date'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                              : 'Enter Transaction Date',
                          style: _selectedDate != null
                              ? AppTextStyles.bodyMedium
                              : AppTextStyles.bodyRegular.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select Time',
                          style: _selectedTime != null
                              ? AppTextStyles.bodyMedium
                              : AppTextStyles.bodyRegular.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
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
                child: CustomButton(
                  text: 'Confirm',
                  onPressed: _submitExpense,
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
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
      isExpanded: true,
      items: items.map((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(
            val,
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
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
            child: const Icon(Icons.attachment, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text('Upload Proof', style: AppTextStyles.title.copyWith(color: AppColors.primary)),
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
