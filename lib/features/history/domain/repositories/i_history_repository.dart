// domain/repositories/i_history_repository.dart
import '../entities/history_expense.dart';

abstract class IHistoryRepository {
  Future<List<HistoryExpense>> getExpenses();
  Future<void> addExpense(HistoryExpense expense);
  Future<void> deleteExpense(String id);
}
