import '../entities/personal_expenses_entity.dart';

abstract class ReportsRepository {
  Future<PersonalExpensesEntity> getPersonalExpenses();
}

