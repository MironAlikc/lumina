import '../entities/history_expense.dart';
import '../repositories/history_repository.dart';

class GetAllExpensesUseCase {
  final IHistoryRepository _repository;
  GetAllExpensesUseCase(this._repository);

  List<HistoryExpense> call() => _repository.getAllExpenses();
}
