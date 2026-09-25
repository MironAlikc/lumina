import '../entities/history_expense.dart';
import '../repositories/history_repository.dart';

class SaveExpenseUseCase {
  final IHistoryRepository _repository;

  SaveExpenseUseCase(this._repository);

  Future<void> call(HistoryExpense expense) async {
    await _repository.saveExpense(expense);
  }
}
