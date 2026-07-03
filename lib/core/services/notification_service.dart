import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Синглтон для удобного доступа к сервису из любой фичи
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // Настройка иконки для Android (использует дефолтную иконку приложения)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройка разрешений для iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // Для версии ^17.2.2 настройки передаются ПЕРВЫМ ПОЗИЦИОННЫМ аргументом
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Здесь можно обработать нажатие на уведомление, если потребуется
      },
    );
  }

  // Метод для быстрой проверки или отправки тестового уведомления
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'lumina_channel_id',
          'Lumina Notifications',
          channelDescription: 'Channel for Lumina app budget alerts',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Для версии ^17.2.2 аргументы передаются позиционно: id, title, body, notificationDetails
    await _notificationsPlugin.show(id, title, body, platformDetails);
  }
}
