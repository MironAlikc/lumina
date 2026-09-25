import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/navigation/app_router.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/settings/presentation/cubits/language_cubit.dart';

class LuminaApp extends StatelessWidget {
  const LuminaApp({
    super.key,
    required this.languageCubit,
    required this.currencyCubit,
  });

  final LanguageCubit languageCubit;
  final CurrencyCubit currencyCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>.value(value: languageCubit),
        BlocProvider<CurrencyCubit>.value(value: currencyCubit),
        BlocProvider<HistoryCubit>(
          create: (_) => sl<HistoryCubit>()..loadRecords(),
        ),
        BlocProvider<CategoriesCubit>(create: (_) => sl<CategoriesCubit>()),
        BlocProvider<AnalyticsCubit>(create: (_) => sl<AnalyticsCubit>()),
        BlocProvider<AccountCubit>(create: (_) => sl<AccountCubit>()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp.router(
            key: ValueKey('lumina_${locale.languageCode}'),
            routerConfig: appRouter,
            title: 'Lumina',
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: LuminaTheme.lightTheme,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.25,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
