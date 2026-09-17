import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/transaction_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';
import '../../data/models/custom_category_model.dart';
import '../../data/models/history_expense_model.dart';

class GroupedTransactionsList extends StatelessWidget {
  final List<HistoryExpenseModel> records;
  final List<CustomCategory> categories;
  final String currencySymbol;

  const GroupedTransactionsList({
    super.key,
    required this.records,
    required this.categories,
    required this.currencySymbol,
  });

  CustomCategory? _findCategory(HistoryExpenseModel record) {
    for (final cat in categories) {
      final matchesId =
          record.categoryId.isNotEmpty && record.categoryId == cat.id;
      final matchesName =
          record.categoryName != null &&
          record.categoryName!.toLowerCase() == cat.name.toLowerCase();
      if (matchesId || matchesName) return cat;
    }
    return null;
  }

  String _formatDateKey(DateTime date, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return loc.today.toUpperCase();
    } else if (target == today.subtract(const Duration(days: 1))) {
      return loc.yesterday.toUpperCase();
    } else {
      final pattern = date.year != now.year ? 'd MMMM y' : 'd MMMM';
      return DateFormat(pattern, locale).format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      final loc = AppLocalizations.of(context)!;
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
              loc.noTransactionsYet,
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

    final sortedRecords = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<HistoryExpenseModel>> grouped = {};
    for (var record in sortedRecords) {
      final dateKey = _formatDateKey(record.date, context);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    final dateKeys = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dateKey = dateKeys[index];
        final dayTransactions = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                dateKey,
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
      }, childCount: dateKeys.length),
    );
  }
}
