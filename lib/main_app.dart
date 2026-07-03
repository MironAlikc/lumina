import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/lumina_localizations.dart';
import 'core/theme/lumina_theme.dart';
import 'features/history/data/repositories/history_repository.dart';
import 'features/history/presentation/cubits/history_cubit.dart';
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
        BlocProvider(
          create: (_) => AnalyticsCubit(),
        ), // ИСПРАВЛЕНО: убран лишний аргумент
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            title: 'Lumina',
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('uk'), Locale('ru')],
            localizationsDelegates: const [
              LuminaLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: LuminaTheme.lightTheme,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
