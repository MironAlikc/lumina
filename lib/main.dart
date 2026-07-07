import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/services/notification_service.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация DI
  await initDependencies();

  // Инициализация локализации и БД
  await Future.wait([
    initializeDateFormatting('uk'),
    initializeDateFormatting('ru'),
    initializeDateFormatting('en'),
    HiveClient().init(),
  ]);

  Hive.registerAdapter(CustomCategoryAdapter());
  await Hive.openBox<CustomCategory>('categories_box');

  await Supabase.initialize(
    url: 'https://xdeczbkdzvugrjqsgsix.supabase.co',
    publishableKey: 'sb_publishable_txQ-CQLbnDZFNAPC2rK-jw_MeeZ2NZg',
  );

  await NotificationService().initNotification();

  runApp(const LuminaApp());
}
