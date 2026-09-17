import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/navigation/app_router.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';
import 'package:lumina/presentation/cubits/language/language_cubit.dart';

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>(create: (context) => LanguageCubit()),
        BlocProvider<CurrencyCubit>(create: (context) => CurrencyCubit()),
        BlocProvider<HistoryCubit>(
          create: (context) => sl<HistoryCubit>()..loadRecords(),
        ),
        BlocProvider<CategoriesCubit>(create: (context) => CategoriesCubit()),
        BlocProvider<AnalyticsCubit>(create: (context) => AnalyticsCubit()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) => MaterialApp.router(
          routerConfig: appRouter,
          title: 'Lumina',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: LuminaTheme.lightTheme,
        ),
      ),
    );
  }
}
