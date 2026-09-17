import 'package:flutter/material.dart';
import 'package:lumina/l10n/app_localizations.dart';

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  housing,
  income;

  String getName(AppLocalizations loc) {
    switch (this) {
      case TransactionCategory.food:
        return loc.catFood;
      case TransactionCategory.transport:
        return loc.catTransport;
      case TransactionCategory.shopping:
        return loc.catShopping;
      case TransactionCategory.entertainment:
        return loc.catEntertainment;
      case TransactionCategory.housing:
        return loc.catHousing;
      case TransactionCategory.income:
        return loc.catIncome;
    }
  }

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

  Color get color {
    switch (this) {
      case TransactionCategory.food:
        return const Color(0xFFF59E0B);
      case TransactionCategory.transport:
        return const Color(0xFF3B82F6);
      case TransactionCategory.shopping:
        return const Color(0xFFEC4899);
      case TransactionCategory.entertainment:
        return const Color(0xFF8B5CF6);
      case TransactionCategory.housing:
        return const Color(0xFFEF4444);
      case TransactionCategory.income:
        return const Color(0xFF10B981);
    }
  }
}
