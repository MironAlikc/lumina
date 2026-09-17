import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/services/notification_service.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/goal_expense_model.dart';
import 'package:lumina/features/history/data/models/budget_model.dart';
import 'package:lumina/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDependencies();

  await Future.wait([
    initializeDateFormatting('uk'),
    initializeDateFormatting('ru'),
    initializeDateFormatting('en'),
    HiveClient().init(),
  ]);

  _registerHiveAdapters();
  await _openHiveBoxes();

  await Supabase.initialize(
    url: 'https://xdeczbkdzvugrjqsgsix.supabase.co',
    publishableKey: 'sb_publishable_txQ-CQLbnDZFNAPC2rK-jw_MeeZ2NZg',
  );

  await NotificationService().initNotification();

  runApp(const LuminaApp());
}

/// Регистрация адаптеров Hive без дублирования проверок
void _registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CustomCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(GoalExpenseModelAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(BudgetModelAdapter());
  }
}

/// Безопасное открытие боксов Hive с обработкой повреждений
Future<void> _openHiveBoxes() async {
  await _openBoxSafely<CustomCategory>('categories_box');
  await _openBoxSafely<GoalExpenseModel>('savings_goals_box');
  await _openBoxSafely<BudgetModel>('budgets_box');
}

Future<void> _openBoxSafely<T>(String boxName) async {
  try {
    await Hive.openBox<T>(boxName);
  } catch (_) {
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<T>(boxName);
  }
}
