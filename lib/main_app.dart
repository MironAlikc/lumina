import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/lumina_localizations.dart';
import 'core/theme/lumina_theme.dart';
import 'features/history/data/repositories/history_repository.dart';
import 'features/history/presentation/cubits/history_cubit.dart';
import 'features/history/presentation/cubits/categories_cubit.dart'; // Импортируем кубит категорий
import 'features/analytics/presentation/cubits/analytics_cubit.dart';
import 'presentation/cubits/language/language_cubit.dart';
import 'presentation/cubits/navigation/navigation_cubit.dart';
import 'features/layout/presentation/main_shell.dart';

class LuminaApp extends StatelessWidget {
  final HistoryRepository historyRepository;

  const LuminaApp({Key? key, required this.historyRepository})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageCubit()),
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => HistoryCubit(historyRepository)),
        BlocProvider(create: (_) => AnalyticsCubit()),
        // ИСПРАВЛЕНО: Добавлен CategoriesCubit и сразу инициализирована загрузка категорий из Hive
        BlocProvider(create: (_) => CategoriesCubit()..loadCategories()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            title: 'Lumina',
            debugShowCheckedModeBanner: false,
            locale: locale,
            // Поддерживаем полноценные локали стран, чтобы intl форматировал даты идеально
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('uk', 'UA'),
              Locale('ru', 'UA'),
            ],
            localizationsDelegates: const [
              LuminaLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: LuminaTheme.lightTheme,
            home: const MainShell(), // Загружает наш обновленный плавный shell
          );
        },
      ),
    );
  }
}
