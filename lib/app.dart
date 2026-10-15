import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/navigation/app_router.dart';
import 'package:lumina/core/services/biometric_service.dart';
import 'package:lumina/core/services/security_storage_service.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/settings/presentation/cubits/language_cubit.dart';
import 'package:lumina/features/settings/presentation/screens/lock_screen.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

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
        // Синглтоны из GetIt: .value, чтобы провайдер их не закрывал.
        BlocProvider<AccountCubit>.value(value: sl<AccountCubit>()),
        BlocProvider<HistoryCubit>.value(value: sl<HistoryCubit>()),
        BlocProvider<CategoriesCubit>.value(value: sl<CategoriesCubit>()),
        BlocProvider<AnalyticsCubit>(create: (_) => sl<AnalyticsCubit>()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp.router(
            routerConfig: appRouter,
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: LuminaTheme.lightTheme,
            builder: (context, child) {
              return MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.25,
                child: _LockGate(child: child ?? const SizedBox.shrink()),
              );
            },
          );
        },
      ),
    );
  }
}

/// Блокировка приложения. Приложение остаётся в дереве (Offstage), поэтому
/// после разблокировки навигация и введённые данные не теряются.
class _LockGate extends StatefulWidget {
  const _LockGate({required this.child});

  final Widget child;

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> with WidgetsBindingObserver {
  static const _grace = Duration(seconds: 30);

  late bool _locked;
  bool _covered = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = SecurityStorageService.isBiometricEnabled;
    if (_locked) _verifySupport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Без биометрии и экрана блокировки войти было бы невозможно.
  Future<void> _verifySupport() async {
    final supported = await BiometricService.isSupported();
    if (!supported && mounted) setState(() => _locked = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!SecurityStorageService.isBiometricEnabled) {
      if (_covered) setState(() => _covered = false);
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
        // Закрываем содержимое в списке недавних приложений.
        if (!_locked) setState(() => _covered = true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
        if (!_locked) setState(() => _covered = true);
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        setState(() {
          _covered = false;
          if (since != null && DateTime.now().difference(since) > _grace) {
            _locked = true;
          }
        });
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = _locked && SecurityStorageService.isBiometricEnabled;

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: locked,
          child: TickerMode(enabled: !locked, child: widget.child),
        ),
        if (locked)
          Positioned.fill(
            child: LockScreen(
              onAuthenticated: () => setState(() => _locked = false),
            ),
          ),
        if (_covered && !locked) const Positioned.fill(child: _PrivacyCover()),
      ],
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: LuminaColors.background,
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 48,
          color: LuminaColors.textSecondary,
        ),
      ),
    );
  }
}
