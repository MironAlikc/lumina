import 'dart:async';
import 'package:flutter/material.dart';

class LuminaLocalizations {
  final Locale locale;
  LuminaLocalizations(this.locale);

  static LuminaLocalizations of(BuildContext context) {
    return Localizations.of<LuminaLocalizations>(context, LuminaLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Lumina',
      'pureBalance': 'Pure balance',
      'limit': 'Limit',
      'budgetExceeded': '⚠️ Budget exceeded!',
      'allFilter': 'All',
      'expenseFilter': 'Expenses',
      'incomeFilter': 'Incomes',
      'noExpenses': 'No data for this period',
      'settingsTitle': 'Profile Settings',
      'myWallet': 'My Wallet',
      'localProfile': 'Lumina Local Profile',
      'budgetManagement': 'Budget Management',
      'monthlyLimit': 'Monthly limit',
      'appSection': 'Application',
      'interfaceLanguage': 'Interface Language',
      'currentLanguageLabel': 'English (US)',
      // Старые сохраненные ключи
      'totalSpent': 'Total spent in selected filter',
      'searchHint': 'Search product (e.g. cucumbers)...',
      'addPurchase': 'New Purchase',
      'productName': 'Product Name',
      'price': 'Price',
      'addButton': 'Add to list',
      'emptyList': 'No items found. Time to shop!',
      'allMonths': 'All Time',
      'priceTrend': 'Price Dynamic',
      'analytics': 'Analytics',
      'catFood': 'Food & Drinks',
      'catTransport': 'Transport',
      'catShopping': 'Shopping',
      'catEntertainment': 'Entertainment',
      'catHousing': 'Housing',
      'catIncome': 'Income',
      'noteHint': 'Add a note...',
      'done': 'Done',
    },
    'uk': {
      'appName': 'Lumina',
      'pureBalance': 'Чистий баланс',
      'limit': 'Ліміт',
      'budgetExceeded': '⚠️ Бюджет перевищено!',
      'allFilter': 'Все',
      'expenseFilter': 'Витрати',
      'incomeFilter': 'Доходи',
      'noExpenses': 'Немає даних за цей період',
      'settingsTitle': 'Налаштування профілю',
      'myWallet': 'Мій гаманець',
      'localProfile': 'Локальний профіль Lumina',
      'budgetManagement': 'Управління бюджетом',
      'monthlyLimit': 'Місячний ліміт',
      'appSection': 'Додаток',
      'interfaceLanguage': 'Мова інтерфейсу',
      'currentLanguageLabel': 'Українська (UA)',
      // Старые сохраненные ключи
      'totalSpent': 'Всього витрачено за фільтром',
      'searchHint': 'Пошук продукту (напр. огірки)...',
      'addPurchase': 'Нова покупка',
      'productName': 'Назва товару',
      'price': 'Ціна',
      'addButton': 'Додати до списку',
      'emptyList': 'Нічого не знайдено. Час оновити витрати!',
      'allMonths': 'Весь час',
      'priceTrend': 'Динаміка цін',
      'analytics': 'Аналітика',
      'catFood': 'Їжа та напої',
      'catTransport': 'Транспорт',
      'catShopping': 'Шопінг',
      'catEntertainment': 'Розваги',
      'catHousing': 'Житло',
      'catIncome': 'Доходи',
      'noteHint': 'Додати нотатку...',
      'done': 'Готово',
    },
    'ru': {
      'appName': 'Lumina',
      'pureBalance': 'Чистый баланс',
      'limit': 'Лимит',
      'budgetExceeded': '⚠️ Бюджет превышен!',
      'allFilter': 'Все',
      'expenseFilter': 'Расходы',
      'incomeFilter': 'Доходы',
      'noExpenses': 'Нет данных за этот период',
      'settingsTitle': 'Настройки профиля',
      'myWallet': 'Мой кошелек',
      'localProfile': 'Локальный профиль Lumina',
      'budgetManagement': 'Управление бюджетом',
      'monthlyLimit': 'Месячный лимит',
      'appSection': 'Приложение',
      'interfaceLanguage': 'Язык интерфейса',
      'currentLanguageLabel': 'Русский (UA)',
      // Старые сохраненные ключи
      'totalSpent': 'Всего потрачено по фильтру',
      'searchHint': 'Поиск продукта (напр. огурцы)...',
      'addPurchase': 'Новая покупка',
      'productName': 'Название товара',
      'price': 'Цена',
      'addButton': 'Добавить в список',
      'emptyList': 'Ничего не найдено. Время внести расходы!',
      'allMonths': 'Все время',
      'priceTrend': 'Динамика цен',
      'analytics': 'Аналитика',
      'catFood': 'Еда и напитки',
      'catTransport': 'Транспорт',
      'catShopping': 'Шопинг',
      'catEntertainment': 'Развлечения',
      'catHousing': 'Жилье',
      'catIncome': 'Доходы',
      'noteHint': 'Добавить заметку...',
      'done': 'Готово',
    },
  };

  String translate(String key) =>
      _localizedValues[locale.languageCode]?[key] ?? key;
}

class LuminaLocalizationsDelegate
    extends LocalizationsDelegate<LuminaLocalizations> {
  const LuminaLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'uk', 'ru'].contains(locale.languageCode);
  @override
  Future<LuminaLocalizations> load(Locale locale) async =>
      LuminaLocalizations(locale);
  @override
  bool shouldReload(LuminaLocalizationsDelegate old) => false;
}
