import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lumina/app.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/services/notification_service.dart';
import 'package:lumina/core/services/sync_service.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/settings/presentation/cubits/language_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  await _configureSystemUi();
  await _start();
}

/// Запускает приложение. При критической ошибке инициализации показывает
/// экран с кнопкой «Повторить» вместо белого экрана.
Future<void> _start() async {
  try {
    runApp(await _bootstrap());
  } catch (e, st) {
    debugPrint('Startup failed: $e\n$st');
    runApp(_StartupErrorApp(error: e, onRetry: _start));
  }
}

void _installErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };
}

Future<void> _configureSystemUi() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
}

Future<Widget> _bootstrap() async {
  await Hive.initFlutter();

  await Future.wait([
    initializeDateFormatting('uk'),
    initializeDateFormatting('ru'),
    initializeDateFormatting('en'),
    HiveClient().init(),
  ]);

  await sl.reset();
  await initDependencies();

  final languageCubit = LanguageCubit();
  final currencyCubit = CurrencyCubit();
  await Future.wait([languageCubit.hydrate(), currencyCubit.hydrate()]);

  await _initSupabase();
  await _initNotifications();

  // Инициализация сервиса фоновой синхронизации
  SyncService.init();

  return LuminaApp(languageCubit: languageCubit, currencyCubit: currencyCubit);
}

Future<void> _initSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty) {
    debugPrint('Supabase skipped: pass SUPABASE_URL and SUPABASE_ANON_KEY');
    return;
  }
  try {
    await Supabase.initialize(url: url, publishableKey: key);
  } catch (e, st) {
    debugPrint('Supabase init failed, local mode: $e\n$st');
  }
}

Future<void> _initNotifications() async {
  try {
    await NotificationService().initNotification();
  } catch (e, st) {
    debugPrint('Notifications init failed: $e\n$st');
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  static const _texts = <String, (String, String, String)>{
    'uk': (
      'Не вдалося запустити додаток',
      'Ваші дані не постраждали. Спробуйте ще раз.',
      'Спробувати знову',
    ),
    'ru': (
      'Не удалось запустить приложение',
      'Ваши данные не пострадали. Попробуйте ещё раз.',
      'Повторить',
    ),
    'en': (
      'The app could not start',
      'Your data is safe. Please try again.',
      'Try again',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final code = PlatformDispatcher.instance.locale.languageCode;
    final (title, message, retry) = _texts[code] ?? _texts['en']!;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(onPressed: onRetry, child: Text(retry)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
