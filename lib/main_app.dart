import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/localization/lumina_localizations.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/navigation/app_router.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/presentation/cubits/language/language_cubit.dart';

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<LanguageCubit>()),
        // NavigationCubit удален как ненужный компонент
        BlocProvider(create: (_) => sl<HistoryCubit>()),
        BlocProvider(create: (_) => sl<AnalyticsCubit>()),
        BlocProvider(create: (_) => sl<CategoriesCubit>()..loadCategories()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) => MaterialApp.router(
          // appRouter теперь является "единым источником правды" для навигации
          routerConfig: appRouter,

          title: 'Lumina',
          debugShowCheckedModeBanner: false,
          locale: locale,
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
        ),
      ),
    );
  }
}
