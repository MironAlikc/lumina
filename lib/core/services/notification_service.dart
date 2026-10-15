import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Не запрашивает разрешения: это делается отдельно, в нужный момент.
  Future<void> initNotification() async {
    if (_initialized || !_isSupported) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e, st) {
      debugPrint('NotificationService init failed: $e\n$st');
    }
  }

  /// Вызывать, когда пользователь включает уведомления (например, лимиты).
  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    } catch (e, st) {
      debugPrint('Notification permission error: $e\n$st');
      return false;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelName = 'Lumina',
    String channelDescription = 'Budget alerts',
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'lumina_channel_id',
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e, st) {
      debugPrint('showNotification failed: $e\n$st');
    }
  }
}
