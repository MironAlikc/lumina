import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/history_expense_model.dart';
import '../cubits/history_cubit.dart';

class ExpenseItemWidget extends StatelessWidget {
  final HistoryExpenseModel item;

  const ExpenseItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final style = _CategoryStyles.getStyle(item.category);
    final formattedDate = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(item.date);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
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
          onLongPress: () {
            HapticFeedback.vibrate();
            // Используем go_router для перехода вместо старого статического метода
            context.push(
              '/add-transaction',
              extra: {'name': item.productName, 'price': item.price},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CategoryIcon(icon: style.icon, color: style.color),
                const SizedBox(width: 14),
                Expanded(
                  child: _ItemInfo(
                    name: item.productName,
                    category: item.category,
                    date: formattedDate,
                  ),
                ),
                _PriceStatus(item: item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() => Container(
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

// Вспомогательные виджеты для чистоты кода
class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CategoryIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

class _ItemInfo extends StatelessWidget {
  final String name, category, date;
  const _ItemInfo({
    required this.name,
    required this.category,
    required this.date,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      Text(
        '$category • $date',
        style: const TextStyle(color: Colors.black45, fontSize: 12),
      ),
    ],
  );
}

class _PriceStatus extends StatelessWidget {
  final HistoryExpenseModel item;
  const _PriceStatus({required this.item});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        '${item.isIncome ? '+' : '-'}${item.price.toStringAsFixed(0)} ₴',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: item.isIncome ? const Color(0xFF10B981) : Colors.black87,
        ),
      ),
      Icon(
        item.isSynced ? Icons.cloud_done : Icons.cloud_upload,
        size: 12,
        color: item.isSynced ? Colors.green : Colors.amber,
      ),
    ],
  );
}

// Класс-стилизатор
class _CategoryStyles {
  static ({IconData icon, Color color}) getStyle(String category) {
    return switch (category) {
      'Доход' => (
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF10B981),
      ),
      'Продукты' => (
        icon: Icons.shopping_basket,
        color: const Color(0xFFF59E0B),
      ),
      _ => (icon: Icons.shopping_bag, color: const Color(0xFF64748B)),
    };
  }
}
