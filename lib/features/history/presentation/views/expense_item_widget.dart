import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/history_expense_model.dart';
import '../cubits/history_cubit.dart';
import '../../../layout/presentation/main_shell.dart';

class ExpenseItemWidget extends StatelessWidget {
  final HistoryExpenseModel item;

  const ExpenseItemWidget({Key? key, required this.item}) : super(key: key);

  /// Умный подбор стиля категории
  Map<String, dynamic> _getCategoryStyle() {
    switch (item.category) {
      case 'Доход':
        return {
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF10B981),
        };
      case 'Продукты':
        return {
          'icon': Icons.shopping_basket_rounded,
          'color': const Color(0xFFF59E0B),
        };
      case 'Транспорт':
        return {
          'icon': Icons.directions_car_filled_rounded,
          'color': const Color(0xFF3B82F6),
        };
      case 'Кафе':
        return {
          'icon': Icons.local_cafe_rounded,
          'color': const Color(0xFFEC4899),
        };
      case 'Образование':
        return {'icon': Icons.school_rounded, 'color': const Color(0xFF8B5CF6)};
      case 'Жилье':
        return {
          'icon': Icons.home_work_rounded,
          'color': const Color(0xFF64748B),
        };
      default:
        return {
          'icon': Icons.shopping_bag_rounded,
          'color': const Color(0xFF64748B),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentLocale = Localizations.localeOf(context).languageCode;
    final style = _getCategoryStyle();
    final Color catColor = style['color'] as Color;

    String formattedDate;
    try {
      formattedDate = DateFormat.yMMMMd(currentLocale).format(item.date);
    } catch (_) {
      formattedDate = item.date.toString();
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFEF4444),
          size: 26,
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        context.read<HistoryCubit>().removeRecord(item.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onLongPress: () {
              HapticFeedback.vibrate();
              MainShell.openQuickAdd(
                context,
                name: item.productName,
                price: item.price,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Иконка категории
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      style['icon'] as IconData,
                      color: catColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Текст: Название и Дата
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.category} • $formattedDate',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Цена и статус
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.isIncome ? '+' : '-'}${item.price.toStringAsFixed(0)} ₴',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: item.isIncome
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Индикатор синхронизации
                      Icon(
                        item.isSynced
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_upload_rounded,
                        size: 14,
                        color: item.isSynced
                            ? const Color(0xFF10B981)
                            : Colors.amber.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
