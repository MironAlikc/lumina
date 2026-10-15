import 'package:get_it/get_it.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/analytics/domain/usecases/calculate_month_analytics.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/transactions/data/repositories/history_repository_impl.dart';
import 'package:lumina/features/transactions/domain/repositories/history_repository.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Репозитории и use case'ы.
  sl.registerLazySingleton<IHistoryRepository>(() => HistoryRepositoryImpl());
  sl.registerLazySingleton<CalculateMonthAnalytics>(
    () => const CalculateMonthAnalytics(),
  );

  // Кубиты-синглтоны живут всё время работы приложения. dispose нужен,
  // чтобы sl.reset() (повторный запуск после ошибки) их закрывал.
  sl.registerLazySingleton<AccountCubit>(
    () => AccountCubit(),
    dispose: (c) => c.close(),
  );
  sl.registerLazySingleton<HistoryCubit>(
    // Явные типы: accountCubit - nullable, и sl() искал бы AccountCubit?.
    () => HistoryCubit(
      sl<IHistoryRepository>(),
      accountCubit: sl<AccountCubit>(),
    ),
    dispose: (c) => c.close(),
  );
  sl.registerLazySingleton<CategoriesCubit>(
    () => CategoriesCubit(),
    dispose: (c) => c.close(),
  );

  // Factory: новый экземпляр, которым владеет BlocProvider.
  sl.registerFactory<AnalyticsCubit>(
    () => AnalyticsCubit(
      calculateMonthAnalytics: sl<CalculateMonthAnalytics>(),
    ),
  );
}
