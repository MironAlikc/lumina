import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/services/notification_service.dart';
import 'core/database/hive_client.dart';
import 'features/history/data/models/custom_category_model.dart'; // Импортируем нашу динамическую модель категорий
import 'features/history/data/repositories/history_repository.dart';
import 'main_app.dart';

void main() async {
  // 1. Гарантируем привязку фреймворка перед асинхронной инициализацией
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Инициализация локалей дат для корректного форматирования
  await initializeDateFormatting('uk', null);
  await initializeDateFormatting('ru', null);
  await initializeDateFormatting('en', null);

  // 3. Инициализация инфраструктуры локального хранилища Hive
  await HiveClient().init();

  // РЕГИСТРАЦИЯ АДАПТЕРА И ОТКРЫТИЕ БОКСА ДЛЯ ДИНАМИЧЕСКИХ КАТЕГОРИЙ
  // Регистрируем сгенерированный адаптер, созданный с помощью build_runner
  Hive.registerAdapter(CustomCategoryAdapter());
  // Открываем постоянный бокс для хранения пользовательских категорий
  await Hive.openBox<CustomCategory>('categories_box');

  // 4. Инициализация Supabase через актуальный параметр publishableKey
  await Supabase.initialize(
    url: 'https://xdeczbkdzvugrjqsgsix.supabase.co', // Твой Project URL
    publishableKey:
        'sb_publishable_txQ-CQLbnDZFNAPC2rK-jw_MeeZ2NZg', // Твой скопированный ключ со строки default
  );

  // 5. Инициализация сервиса локальных уведомлений
  await NotificationService().initNotification();

  // 6. Создаем репозиторий, когда все базы данных (Hive и Supabase) на 100% готовы
  final historyRepo = HistoryRepository();

  // 7. Автоматически запускаем синхронизацию при старте (если юзер залогинен, неотправленные пачки улетят)
  await historyRepo.syncUnsyncedRecords();

  runApp(LuminaApp(historyRepository: historyRepo));
}
