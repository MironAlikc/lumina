import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({
    super.key,
    required this.state,
    this.limit = 5,
  });

  final HistoryState state;
  final int limit;

  CustomCategory? _findCategory(List<CustomCategory> categories, String key) {
    final needle = key.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final c in categories) {
      if (c.id == key || c.id.toLowerCase() == needle) return c;
      if (c.name.toLowerCase() == needle) return c;
    }
    const aliases = {
      'food': 'cat_food',
      'food & drinks': 'cat_food',
      'transport': 'cat_transport',
      'shopping': 'cat_shopping',
      'entertainment': 'cat_entertainment',
      'housing': 'cat_housing',
      'home': 'cat_housing',
      'salary': 'cat_salary',
      'income': 'cat_salary',
    };
    final id = aliases[needle];
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final records = [...state.filteredRecords]
      ..sort((a, b) => b.date.compareTo(a.date));
    final items = records.take(limit).toList();

    if (items.isEmpty) {
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

    final catState = context.watch<CategoriesCubit>().state;
    final categories = catState is CategoriesLoaded
        ? catState.categories
        : const <CustomCategory>[];
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entity = items[index];
          return TransactionTile(
            record: HistoryExpenseModel.fromEntity(entity),
            category: _findCategory(categories, entity.category),
            currencySymbol: currencySymbol,
          );
        },
      ),
    );
  }
}
