/// Подсказывает категорию по названию позиции. Это эвристика: пользователь
/// всегда может изменить выбор. Если уверенности нет, возвращает null.
class ReceiptCategorizer {
  ReceiptCategorizer._();

  /// Основы слов, совпадение идёт с начала слова.
  static const _rules = <String, List<String>>{
    'cat_food': [
      'хліб',
      'хлеб',
      'батон',
      'булк',
      'молок',
      'кефір',
      'кефир',
      'йогурт',
      'сир',
      'сыр',
      'масл',
      'яйц',
      'яєц',
      "м'яс",
      'мяс',
      'куряч',
      'курка',
      'куриц',
      'ковбас',
      'колбас',
      'сосис',
      'риб',
      'рыб',
      'круп',
      'пшон',
      'цукор',
      'сахар',
      'кава',
      'кофе',
      'чай',
      'напій',
      'напиток',
      'пепсі',
      'кола',
      'вода',
      'води',
      'пиво',
      'сік',
      'сок',
      'овоч',
      'фрукт',
      'яблук',
      'яблок',
      'банан',
      'сіль',
      'соль',
      'олія',
      'макарон',
      'рис',
      'шоколад',
      'печив',
      'цукерк',
      'конфет',
      'морозив',
      'мороженое',
      'snack',
      'food',
    ],
    'cat_shopping': [
      'пакет',
      'торб',
      'стакан',
      'посуд',
      'сервет',
      'губк',
      'однораз',
    ],
    'cat_housing': [
      'ламп',
      'батарей',
      'побут',
      'засіб',
      'порош',
      'мил',
      'шампун',
      'зубн',
      'туалет',
      'прибир',
      'гель',
    ],
    'cat_transport': [
      'бензин',
      'дизель',
      'пальне',
      'проїзд',
      'метро',
      'таксі',
      'такси',
      'fuel',
      'автогаз',
    ],
    'cat_entertainment': ['квиток', 'билет', 'кіно', 'кино', 'ігр', 'підписк'],
  };

  static final Map<String, List<RegExp>> _compiled = {
    for (final entry in _rules.entries)
      entry.key: [
        for (final stem in entry.value)
          RegExp(
            r'(?<![\p{L}\d])' + RegExp.escape(stem),
            unicode: true,
          ),
      ],
  };

  static String? suggest(String name) {
    final text =
        name.toLowerCase().replaceAll('’', "'").replaceAll('ʼ', "'").trim();
    if (text.isEmpty) return null;

    String? best;
    var bestScore = 0;
    for (final entry in _compiled.entries) {
      final score = entry.value.where((re) => re.hasMatch(text)).length;
      // При равенстве побеждает категория, объявленная раньше.
      if (score > bestScore) {
        bestScore = score;
        best = entry.key;
      }
    }
    return best;
  }
}
