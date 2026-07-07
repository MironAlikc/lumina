import 'package:flutter/material.dart';
import '../../../../core/localization/lumina_localizations.dart';

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  housing,
  income;

  /// Получение локализованного названия категории
  String getName(LuminaLocalizations loc) {
    switch (this) {
      case TransactionCategory.food:
        return loc.translate('catFood');
      case TransactionCategory.transport:
        return loc.translate('catTransport');
      case TransactionCategory.shopping:
        return loc.translate('catShopping');
      case TransactionCategory.entertainment:
        return loc.translate('catEntertainment');
      case TransactionCategory.housing:
        return loc.translate('catHousing');
      case TransactionCategory.income:
        return loc.translate('catIncome');
    }
  }

  /// Иконка для категории
  IconData get icon {
    switch (this) {
      case TransactionCategory.food:
        return Icons.fastfood_rounded;
      case TransactionCategory.transport:
        return Icons.directions_car_rounded;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TransactionCategory.entertainment:
        return Icons.confirmation_number_rounded;
      case TransactionCategory.housing:
        return Icons.home_rounded;
      case TransactionCategory.income:
        return Icons.account_balance_wallet_rounded;
    }
  }

  /// Цвет подложки иконки
  Color get color {
    switch (this) {
      case TransactionCategory.food:
        return const Color(0xFFF59E0B); // Оранжевый
      case TransactionCategory.transport:
        return const Color(0xFF3B82F6); // Синий
      case TransactionCategory.shopping:
        return const Color(0xFFEC4899); // Розовый
      case TransactionCategory.entertainment:
        return const Color(0xFF8B5CF6); // Фиолетовый
      case TransactionCategory.housing:
        return const Color(0xFFEF4444); // Красный
      case TransactionCategory.income:
        return const Color(0xFF10B981); // Зеленый
    }
  }
}
