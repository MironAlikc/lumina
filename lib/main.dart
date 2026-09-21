import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/services/notification_service.dart';
import 'package:lumina/features/history/data/models/budget_model.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/goal_expense_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/data/models/recurring_expense_model.dart';
import 'package:lumina/main_app.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';
import 'package:lumina/presentation/cubits/language/language_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
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
  ]);

  await HiveClient().init();
  _registerHiveAdapters();
  await _openHiveBoxes();

  await initDependencies();

  final languageCubit = LanguageCubit();
  final currencyCubit = CurrencyCubit();
  await Future.wait([languageCubit.hydrate(), currencyCubit.hydrate()]);

  await _initSupabase();
  await NotificationService().initNotification();

  runApp(LuminaApp(languageCubit: languageCubit, currencyCubit: currencyCubit));
}

void _registerHiveAdapters() {
  _registerAdapter(TransactionTypeAdapter());
  _registerAdapter(HistoryExpenseModelAdapter());
  _registerAdapter(CustomCategoryAdapter());
  _registerAdapter(GoalExpenseModelAdapter());
  _registerAdapter(BudgetModelAdapter());
  _registerAdapter(RecurringExpenseModelAdapter());
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter<T>(adapter);
  }
}

Future<void> _openHiveBoxes() async {
  await _openBoxSafely<CustomCategory>('categories_box');
  await _openBoxSafely<GoalExpenseModel>('savings_goals_box');
  await _openBoxSafely<BudgetModel>('budgets_box');
  await _openBoxSafely<RecurringExpenseModel>('recurring_expenses_box');
}

Future<void> _openBoxSafely<T>(String boxName) async {
  try {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<T>(boxName);
    }
  } catch (e, st) {
    debugPrint('Hive box "$boxName" damaged, recreating: $e\n$st');
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<T>(boxName);
  }
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
