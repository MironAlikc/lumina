import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.record,
    required this.currencySymbol,
    this.category,
    this.onEdit,
    this.onDelete,
  });

  final HistoryExpenseModel record;
  final CustomCategory? category;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final isIncome = record.type == TransactionType.income;

    final categoryLabel = category?.localizedName(loc);
    final displayName = record.productName.isNotEmpty
        ? record.productName
        : (categoryLabel ??
              (record.categoryName?.isNotEmpty == true
                  ? record.categoryName!
                  : loc.defaultTransactionName));

    final hasTime = record.date.hour != 0 || record.date.minute != 0;
    final dateLabel = DateFormat(
      hasTime ? 'd MMM, HH:mm' : 'd MMM y',
      locale,
    ).format(record.date);

    final amountColor = isIncome ? LuminaColors.success : LuminaColors.error;
    final iconColor = category?.color ?? LuminaTheme.accentColor;
    final hasActions = onEdit != null || onDelete != null;

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
