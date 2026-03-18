import '../../../expense/domain/entities/expense_entry.dart';

class PersonalExpensesEntity {
  final String title;
  final String dateRangeLabel;
  final double totalAmount;
  final List<ExpenseEntry> recentActivity;

  const PersonalExpensesEntity({
    required this.title,
    required this.dateRangeLabel,
    required this.totalAmount,
    required this.recentActivity,
  });
}

