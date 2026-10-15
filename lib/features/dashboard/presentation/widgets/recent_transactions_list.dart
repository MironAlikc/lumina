import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Сливер с последними операциями. Записи кубит уже отсортировал по дате.
class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key, this.limit = 5});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final catState = context.watch<CategoriesCubit>().state;
    final symbol = context.select((CurrencyCubit c) => c.state.symbol);
    // Старые названия категорий переводит в id миграция в CategoriesCubit,
    // поэтому здесь достаточно поиска по id.
    final byId = <String, CustomCategory>{
      if (catState is CategoriesLoaded)
        for (final c in catState.categories) c.id: c,
    };

    return BlocBuilder<HistoryCubit, HistoryState>(
      buildWhen: (p, n) =>
          !listEquals(p.filteredRecords, n.filteredRecords) ||
          p.allRecords.isEmpty != n.allRecords.isEmpty,
      builder: (context, state) {
        final items = state.filteredRecords.take(limit).toList();

        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyRecent(firstRun: state.allRecords.isEmpty),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entity = items[index];
              return TransactionTile(
                key: ValueKey(entity.id),
                record: HistoryExpenseModel.fromEntity(entity),
                category: byId[entity.category],
                currencySymbol: symbol,
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.firstRun});

  /// true: операций нет вообще, предлагаем добавить первую.
  final bool firstRun;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: LuminaTheme.premiumShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            firstRun ? loc.noTransactionsYet : loc.noExpensesForPeriod,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LuminaColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (firstRun) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-transaction'),
              icon: const Icon(Icons.add_rounded),
              label: Text(loc.create),
            ),
          ],
        ],
      ),
    );
  }
}
