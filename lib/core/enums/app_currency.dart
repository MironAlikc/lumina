import 'package:lumina/l10n/app_localizations.dart';

enum AppCurrency {
  uah,
  usd,
  eur;

  String get symbol => switch (this) {
    AppCurrency.uah => '₴',
    AppCurrency.usd => '\$',
    AppCurrency.eur => '€',
  };

  String localizedName(AppLocalizations loc) => switch (this) {
    AppCurrency.uah => loc.currencyUah,
    AppCurrency.usd => loc.currencyUsd,
    AppCurrency.eur => loc.currencyEur,
  };

  /// Читает и новый формат (`uah`), и старый (`₴` / «Гривна»).
  static AppCurrency fromStored(String? value) {
    return switch (value) {
      'uah' || '₴' || 'Гривна' || 'Гривня' || 'Hryvnia' => AppCurrency.uah,
      'usd' ||
      '\$' ||
      'USD' ||
      'Dollar' ||
      'Долар США' ||
      'Доллар' => AppCurrency.usd,
      'eur' || '€' || 'EUR' || 'Euro' || 'Євро' || 'Евро' => AppCurrency.eur,
      _ => AppCurrency.uah,
    };
  }
}
