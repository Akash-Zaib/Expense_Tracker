import '../entities/personal_expenses_entity.dart';
import '../repositories/reports_repository.dart';

class GetPersonalExpenses {
  final ReportsRepository _repo;

  const GetPersonalExpenses(this._repo);

  Future<PersonalExpensesEntity> call() => _repo.getPersonalExpenses();
}

