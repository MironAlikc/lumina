import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';

class LanguageCubit extends Cubit<Locale> {
  static const languageKey = 'selected_language';
  static const supportedCodes = ['uk', 'ru', 'en'];

  LanguageCubit() : super(const Locale('uk'));

  Future<void> hydrate() => _loadSavedLanguage();

  Future<void> _loadSavedLanguage() async {
    try {
      final box = await _settingsBox();
      final saved = box.get(languageKey, defaultValue: 'uk');
      final code = saved is String ? saved : 'uk';
      if (isSupported(code) && state.languageCode != code) {
        emit(Locale(code));
      }
    } catch (e, st) {
      debugPrint('Error loading language: $e\n$st');
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (!isSupported(langCode) || state.languageCode == langCode) return;
    try {
      final box = await _settingsBox();
      await box.put(languageKey, langCode);
      emit(Locale(langCode));
    } catch (e, st) {
      debugPrint('Error saving language: $e\n$st');
    }
  }

  static bool isSupported(String code) => supportedCodes.contains(code);

  Future<Box<dynamic>> _settingsBox() async {
    if (Hive.isBoxOpen(HiveClient.settingsBox)) {
      return Hive.box(HiveClient.settingsBox);
    }
    return Hive.openBox(HiveClient.settingsBox);
  }
}
