import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.record,
    required this.currencySymbol,
    this.category,
    this.onEdit,
    this.onDelete,
    this.enableDismissible = true,
  });

  final HistoryExpenseModel record;
  final CustomCategory? category;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool enableDismissible;

  static String _localizeStoredName(String raw, AppLocalizations loc) {
    return switch (raw.trim().toLowerCase()) {
      'food' || 'food & drinks' => loc.catFood,
      'transport' => loc.catTransport,
      'shopping' => loc.catShopping,
      'entertainment' => loc.catEntertainment,
      'housing' || 'home' => loc.catHousing,
      'salary' || 'income' => loc.catSalary,
      _ => raw.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final isIncome = record.isIncome || record.type == TransactionType.income;

    final categoryLabel = category?.localizedName(loc);
    final stored = record.productName.trim();
    final mapped = stored.isEmpty ? '' : _localizeStoredName(stored, loc);

    final displayName = mapped.isNotEmpty
        ? mapped
        : (categoryLabel ??
              (record.categoryName?.isNotEmpty == true
                  ? _localizeStoredName(record.categoryName!, loc)
                  : loc.defaultTransactionName));

    final hasTime = record.date.hour != 0 || record.date.minute != 0;
    final dateLabel = DateFormat(
      hasTime ? 'd MMM, HH:mm' : 'd MMM y',
      locale,
    ).format(record.date);

    final amountColor = isIncome ? LuminaColors.success : LuminaColors.textMain;
    final iconColor = category?.color ?? LuminaTheme.accentColor;
    final categoryNameStr =
        category?.name ?? record.categoryName ?? 'Без категории';

    final tileContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: LuminaTheme.premiumShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          _showTransactionDetailsDialog(
            context,
            record,
            categoryNameStr,
            currencySymbol,
            category,
          );
        },
        onLongPress: () {
          HapticFeedback.vibrate();
          if (onEdit != null) {
            onEdit!();
          } else {
            context.push(
              '/add-transaction',
              extra: {
                'name': record.productName,
                'price': record.price,
                'id': record.id,
                'categoryId': record.categoryId,
              },
            );
          }
        },
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category?.icon ?? Icons.receipt_long_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: LuminaTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    categoryLabel != null && categoryLabel != displayName
                        ? '$categoryLabel · $dateLabel'
                        : dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: LuminaTheme.subTitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${record.price.toStringAsFixed(0)} $currencySymbol',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  record.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                  size: 12,
                  color: record.isSynced ? Colors.green : Colors.amber,
                ),
              ],
            ),
            if (onEdit != null || onDelete != null) ...[
              if (onEdit != null)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 4),
                  onPressed: onDelete,
                ),
            ],
          ],
        ),
      ),
    );

    if (!enableDismissible) {
      return tileContent;
    }

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFEF4444),
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        if (onDelete != null) {
          onDelete!();
        } else {
          context.read<HistoryCubit>().removeRecord(record.id);
        }
      },
      child: tileContent,
    );
  }

  void _showTransactionDetailsDialog(
    BuildContext context,
    HistoryExpenseModel record,
    String categoryName,
    String currencySymbol,
    CustomCategory? category,
  ) {
    final isIncome = record.isIncome || record.type == TransactionType.income;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
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
                        onPressed: () => Navigator.pop(dialogContext),
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
                        '${isIncome ? '+' : '-'}${record.price.toStringAsFixed(0)} $currencySymbol',
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
                        if (onDelete != null) {
                          onDelete!();
                        } else {
                          await context.read<HistoryCubit>().removeRecord(
                            record.id,
                          );
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

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
