import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/services/supabase_sync_service.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
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

  /// Устаревшие записи хранят в productName локализованное имя категории.
  /// Удалить после разовой миграции данных.
  static String _localizeLegacyName(String raw, AppLocalizations loc) {
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

  static String formatAmount(double value, String locale) {
    final hasFraction = (value * 100).round() % 100 != 0;
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: hasFraction ? 2 : 0,
    ).format(value);
  }

  String _signedAmount(String locale) {
    final sign = switch (record.type) {
      TransactionType.income => '+',
      TransactionType.expense => '−',
      TransactionType.transfer => '',
    };
    return '$sign${formatAmount(record.price, locale)} $currencySymbol';
  }

  Color get _amountColor => switch (record.type) {
        TransactionType.income => LuminaColors.success,
        TransactionType.expense => LuminaColors.textMain,
        TransactionType.transfer => LuminaColors.accentDeep,
      };

  String _displayName(AppLocalizations loc, String? categoryLabel) {
    final stored = record.productName.trim();
    if (stored.isNotEmpty) return _localizeLegacyName(stored, loc);
    if (record.isTransfer) return loc.transfer;
    if (categoryLabel != null) return categoryLabel;
    final fallback = record.categoryName?.trim() ?? '';
    if (fallback.isNotEmpty) return _localizeLegacyName(fallback, loc);
    return loc.defaultTransactionName;
  }

  void _edit(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (onEdit != null) {
      onEdit!();
      return;
    }
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

  void _performDelete({
    required ScaffoldMessengerState messenger,
    required HistoryCubit cubit,
    required AppLocalizations loc,
  }) {
    if (onDelete != null) {
      onDelete!();
      return;
    }
    final backup = record.toEntity();
    cubit.removeRecord(record.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(loc.transactionDeleted),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: loc.undo,
            onPressed: () => cubit.addRecord(backup),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final categoryLabel = category?.localizedName(loc);
    final displayName = _displayName(loc, categoryLabel);

    final hasTime = record.date.hour != 0 || record.date.minute != 0;
    final dateLabel = DateFormat(
      hasTime ? 'd MMM, HH:mm' : 'd MMM y',
      locale,
    ).format(record.date);

    final subtitle = categoryLabel != null && categoryLabel != displayName
        ? '$categoryLabel · $dateLabel'
        : dateLabel;

    final iconColor = record.isTransfer
        ? LuminaColors.accentDeep
        : (category?.color ?? LuminaTheme.accentColor);
    final iconData = record.isTransfer
        ? Icons.swap_horiz_rounded
        : (category?.icon ?? Icons.receipt_long_rounded);

    final amountText = _signedAmount(locale);
    final showSyncState = SupabaseSyncService.instance.isAuthenticated;

    final tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: LuminaTheme.premiumShadow,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showDetails(
              context,
              displayName: displayName,
              categoryLabel: categoryLabel ?? loc.exportNoCategory,
              amountText: amountText,
            );
          },
          onLongPress: () => _edit(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
                      amountText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _amountColor,
                      ),
                    ),
                    if (showSyncState) ...[
                      const SizedBox(height: 2),
                      Icon(
                        record.isSynced
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_upload_rounded,
                        size: 12,
                        color: record.isSynced
                            ? LuminaColors.success
                            : Colors.amber,
                      ),
                    ],
                  ],
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: loc.change,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: LuminaColors.textSecondary,
                    ),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: loc.delete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: LuminaColors.error,
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final accessible = Semantics(
      container: true,
      label: '$displayName, $subtitle, $amountText',
      child: ExcludeSemantics(child: tile),
    );

    if (!enableDismissible) return accessible;

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: LuminaColors.errorSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: LuminaColors.error,
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        _performDelete(
          messenger: ScaffoldMessenger.of(context),
          cubit: context.read<HistoryCubit>(),
          loc: loc,
        );
      },
      child: accessible,
    );
  }

  void _showDetails(
    BuildContext context, {
    required String displayName,
    required String categoryLabel,
    required String amountText,
  }) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<HistoryCubit>();
    final dateText = DateFormat.yMMMd(locale).add_Hm().format(record.date);
    final typeText = switch (record.type) {
      TransactionType.income => loc.incomeType,
      TransactionType.expense => loc.expense,
      TransactionType.transfer => loc.transfer,
    };

    showLuminaDialog<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.transactionDetails,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: LuminaColors.textMain,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: loc.cancel,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: LuminaColors.textSecondary,
                  ),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  _DetailRow(label: loc.nameLabel, value: displayName),
                  _DetailRow(label: loc.categoryLabel, value: categoryLabel),
                  _DetailRow(label: loc.categoryType, value: typeText),
                  _DetailRow(label: loc.amountLabel, value: amountText),
                  _DetailRow(label: loc.dateLabel, value: dateText),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(loc.change),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LuminaColors.accentDeep,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              _edit(context);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(loc.delete),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LuminaColors.errorSoft,
                              foregroundColor: LuminaColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context, rootNavigator: true).pop();
                              _performDelete(
                                messenger: messenger,
                                cubit: cubit,
                                loc: loc,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LuminaColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: LuminaColors.textMain,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
