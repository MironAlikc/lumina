import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/history_expense_model.dart';
import '../cubits/history_cubit.dart';
import '../../presentation/cubits/categories_cubit.dart';
import '../../presentation/cubits/categories_state.dart';
import '../../../../presentation/cubits/currency/currency_cubit.dart';

class ExpenseItemWidget extends StatelessWidget {
  final HistoryExpenseModel item;

  const ExpenseItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final catState = context.watch<CategoriesCubit>().state;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;

    final category =
        (catState is CategoriesLoaded && catState.categories.isNotEmpty)
        ? catState.categories.firstWhere(
            (c) => c.id == item.categoryId,
            orElse: () => catState.categories.first,
          )
        : null;

    final formattedDate = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(item.date);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: const _DismissBackground(),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        context.read<HistoryCubit>().removeRecord(item.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            _showTransactionDetailsModal(
              context,
              item,
              category?.name ?? 'Без категории',
              currencySymbol,
            );
          },
          onLongPress: () {
            HapticFeedback.vibrate();
            context.push(
              '/add-transaction',
              extra: {'name': item.productName, 'price': item.price},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CategoryIcon(
                  icon: category?.icon ?? Icons.category_rounded,
                  color: category?.color ?? Colors.grey,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ItemInfo(
                    name: item.productName,
                    categoryName: category?.name ?? 'Без категории',
                    date: formattedDate,
                  ),
                ),
                _PriceStatus(item: item, currencySymbol: currencySymbol),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetailsModal(
    BuildContext context,
    HistoryExpenseModel record,
    String categoryName,
    String currencySymbol,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Детали транзакции',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Название:',
                value: record.productName.isNotEmpty
                    ? record.productName
                    : categoryName,
              ),
              _DetailRow(label: 'Категория:', value: categoryName),
              _DetailRow(
                label: 'Сумма:',
                value:
                    '${record.isIncome ? '+' : '-'}${record.price.toStringAsFixed(0)} $currencySymbol',
              ),
              _DetailRow(
                label: 'Дата:',
                value: DateFormat.yMMMd(
                  Localizations.localeOf(context).languageCode,
                ).format(record.date),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  label: const Text(
                    'Удалить транзакцию',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await context.read<HistoryCubit>().removeRecord(record.id);
                    if (modalContext.mounted) {
                      Navigator.pop(modalContext);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _CategoryIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ItemInfo extends StatelessWidget {
  final String name;
  final String categoryName;
  final String date;

  const _ItemInfo({
    required this.name,
    required this.categoryName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        Text(
          '$categoryName • $date',
          style: const TextStyle(color: Colors.black45, fontSize: 12),
        ),
      ],
    );
  }
}

class _PriceStatus extends StatelessWidget {
  final HistoryExpenseModel item;
  final String currencySymbol;

  const _PriceStatus({required this.item, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${item.isIncome ? '+' : '-'}${item.price.toStringAsFixed(0)} $currencySymbol',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: item.isIncome ? const Color(0xFF10B981) : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          item.isSynced ? Icons.cloud_done : Icons.cloud_upload,
          size: 12,
          color: item.isSynced ? Colors.green : Colors.amber,
        ),
      ],
    );
  }
}
