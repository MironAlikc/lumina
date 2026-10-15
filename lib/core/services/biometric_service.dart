import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

abstract final class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Есть ли на устройстве биометрия или экран блокировки. Без этого
  /// блокировку включать нельзя: пользователь не смог бы войти.
  static Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e, st) {
      debugPrint('Biometric support check failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          // Разрешает PIN устройства, если биометрии нет.
          biometricOnly: false,
        ),
      );
    } catch (e, st) {
      debugPrint('Biometric authentication error: $e\n$st');
      return false;
    }
  }
}
