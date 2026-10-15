import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';

/// Настройка блокировки приложения. Бокс открывает HiveClient при старте.
abstract final class SecurityStorageService {
  static const _biometricKey = 'is_biometric_enabled';

  static Box<dynamic>? get _box => Hive.isBoxOpen(HiveClient.settingsBox)
      ? Hive.box<dynamic>(HiveClient.settingsBox)
      : null;

  /// По умолчанию выключено: блокировка включается пользователем.
  static bool get isBiometricEnabled {
    final value = _box?.get(_biometricKey);
    return value is bool ? value : false;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final box = _box ?? await Hive.openBox<dynamic>(HiveClient.settingsBox);
    await box.put(_biometricKey, value);
  }
}
