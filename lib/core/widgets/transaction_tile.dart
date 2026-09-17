import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class TransactionTile extends StatelessWidget {
  final HistoryExpenseModel record;
  final CustomCategory? category;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.record,
    required this.currencySymbol,
    this.category,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isIncome = record.type == TransactionType.income;

    final String displayName = record.productName.isNotEmpty
        ? record.productName
        : (record.categoryName?.isNotEmpty == true
              ? record.categoryName!
              : loc.defaultTransactionName);

    final Color amountColor = isIncome
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);

    final Color iconColor = category?.color ?? LuminaTheme.accentColor;
    final IconData iconData = category?.icon ?? Icons.receipt_long_rounded;

    final bool hasActions = onEdit != null || onDelete != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: LuminaTheme.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
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
                  '${record.date.day.toString().padLeft(2, '0')}.${record.date.month.toString().padLeft(2, '0')}.${record.date.year}  '
                  '${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
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
          Text(
            '${isIncome ? '+' : '-'}${record.price.toStringAsFixed(0)} $currencySymbol',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: amountColor,
            ),
          ),
          if (hasActions) ...[
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
    );
  }
}
