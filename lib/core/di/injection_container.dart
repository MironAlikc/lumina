import 'package:get_it/get_it.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/history/data/repositories/history_repository_impl.dart';
import 'package:lumina/features/history/domain/repositories/history_repository.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<IHistoryRepository>(() => HistoryRepositoryImpl());

  sl.registerFactory(() => HistoryCubit(sl()));
  sl.registerFactory(() => AnalyticsCubit());
  sl.registerFactory(() => CategoriesCubit());
}
