import 'package:get_it/get_it.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:lumina/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:lumina/features/analytics/domain/usecases/calculate_month_analytics.dart';
import 'package:lumina/features/analytics/domain/usecases/search_matching_expenses.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/transactions/data/repositories/history_repository_impl.dart';
import 'package:lumina/features/transactions/domain/repositories/history_repository.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<IHistoryRepository>(() => HistoryRepositoryImpl());
  sl.registerLazySingleton<IAnalyticsRepository>(
    () => AnalyticsRepositoryImpl(),
  );
  sl.registerLazySingleton<CalculateMonthAnalytics>(
    () => const CalculateMonthAnalytics(),
  );
  sl.registerLazySingleton<SearchMatchingExpenses>(
    () => SearchMatchingExpenses(sl()),
  );

  sl.registerLazySingleton(() => HistoryCubit(sl()));
  sl.registerLazySingleton(() => CategoriesCubit());
  sl.registerLazySingleton(() => AccountCubit());
  sl.registerFactory(() => AnalyticsCubit(calculateMonthAnalytics: sl()));
}
