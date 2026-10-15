import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(Locale(_deviceCode()));

  static const languageKey = 'selected_language';
  static const supportedCodes = ['uk', 'ru', 'en'];
  static const _fallback = 'uk';

  static bool isSupported(String code) => supportedCodes.contains(code);

  /// Язык устройства, если он поддерживается, иначе украинский.
  static String _deviceCode() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return isSupported(code) ? code : _fallback;
  }

  Box<dynamic> get _box => Hive.box(HiveClient.settingsBox);

  /// Сохранённый выбор важнее языка устройства.
  Future<void> hydrate() async {
    try {
      final saved = _box.get(languageKey);
      if (saved is String &&
          isSupported(saved) &&
          state.languageCode != saved) {
        emit(Locale(saved));
      }
    } catch (e, st) {
      debugPrint('Error loading saved language: $e\n$st');
    }
  }

  Future<void> changeLanguage(String code) async {
    if (!isSupported(code) || state.languageCode == code) return;
    try {
      await _box.put(languageKey, code);
      emit(Locale(code));
    } catch (e, st) {
      debugPrint('Error saving language preference: $e\n$st');
    }
  }
}
