import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lumina/core/services/notification_service.dart';
import 'core/database/hive_client.dart';
import 'features/history/data/repositories/history_repository.dart';
import 'main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Локали дат
  await initializeDateFormatting('uk', null);
  await initializeDateFormatting('ru', null);
  await initializeDateFormatting('en', null);

  // Инициализация инфраструктуры
  await HiveClient().init();
  await NotificationService().initNotification();

  // Инициализация чистых репозиториев
  final historyRepo = HistoryRepository();

  runApp(
    LuminaApp(
      historyRepository: historyRepo, // Передаем только нужный репозиторий
    ),
  );
}
