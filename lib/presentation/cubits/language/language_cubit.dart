import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageCubit extends Cubit<Locale> {
  // По умолчанию задаем украинский язык
  LanguageCubit() : super(const Locale('uk'));

  /// Явная смена языка по коду (например: 'uk', 'en', 'ru')
  void changeLanguage(String langCode) {
    emit(Locale(langCode));
  }

  /// Циклическое переключение между доступными языками приложения
  void toggleLanguage() {
    if (state.languageCode == 'uk') {
      emit(const Locale('en'));
    } else if (state.languageCode == 'en') {
      emit(const Locale('ru'));
    } else {
      emit(const Locale('uk'));
    }
  }
}
