import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/transaction_tile.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class GroupedTransactionsList extends StatelessWidget {
  const GroupedTransactionsList({
    super.key,
    required this.records,
    required this.categories,
    required this.currencySymbol,
  });

  final List<HistoryExpenseModel> records;
  final List<CustomCategory> categories;
  final String currencySymbol;

  CustomCategory? _findCategory(HistoryExpenseModel record) {
    for (final cat in categories) {
      if (record.categoryId.isNotEmpty && record.categoryId == cat.id) {
        return cat;
      }
    }
    return null;
  }

  String _headerFor(DateTime date, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return loc.today.toUpperCase();
    if (target == today.subtract(const Duration(days: 1))) {
      return loc.yesterday.toUpperCase();
    }

    final pattern = date.year != now.year ? 'd MMMM y' : 'd MMMM';
    return DateFormat(pattern, locale).format(target);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (records.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: LuminaTheme.premiumShadow,
          ),
          child: Center(
            child: Text(
              loc.noExpensesForMonth,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LuminaTheme.subTitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    final grouped = <DateTime, List<HistoryExpenseModel>>{};
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    for (final record in sorted) {
      final key = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      grouped.putIfAbsent(key, () => []).add(record);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final day = days[index];
        final dayTransactions = grouped[day]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                _headerFor(day, context),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LuminaTheme.subTitleColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            ...dayTransactions.map(
              (tx) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: TransactionTile(
                  record: tx,
                  category: _findCategory(tx),
                  currencySymbol: currencySymbol,
                ),
              ),
            ),
          ],
        );
      }, childCount: days.length),
    );
  }
}
