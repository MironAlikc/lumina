import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lumina/app.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/services/notification_service.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/settings/presentation/cubits/language_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Future.wait([
    initializeDateFormatting('uk'),
    initializeDateFormatting('ru'),
    initializeDateFormatting('en'),
    HiveClient().init(),
  ]);

  await initDependencies();

  final languageCubit = LanguageCubit();
  final currencyCubit = CurrencyCubit();
  await Future.wait([languageCubit.hydrate(), currencyCubit.hydrate()]);

  await _initSupabase();
  await NotificationService().initNotification();

  runApp(LuminaApp(languageCubit: languageCubit, currencyCubit: currencyCubit));
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
