import 'package:get_it/get_it.dart';
import 'package:lumina/features/history/data/repositories/history_repository.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/presentation/cubits/language/language_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Репозитории
  sl.registerLazySingleton(() => HistoryRepository());

  // Cubits
  sl.registerFactory(() => LanguageCubit());
  sl.registerFactory(() => HistoryCubit(sl()));
  sl.registerFactory(() => AnalyticsCubit());
  sl.registerFactory(() => CategoriesCubit());
}
