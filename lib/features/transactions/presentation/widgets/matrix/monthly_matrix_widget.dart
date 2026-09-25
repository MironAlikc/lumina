import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class _MatrixCol {
  const _MatrixCol({
    required this.id,
    required this.title,
    required this.isIncome,
    this.icon,
    this.color,
  });

  final String id;
  final String title;
  final bool isIncome;
  final IconData? icon;
  final Color? color;
}

class MonthlyMatrixWidget extends StatelessWidget {
  const MonthlyMatrixWidget({
    super.key,
    required this.monthRecords,
    required this.categories,
    required this.month,
    required this.year,
    required this.currencySymbol,
    this.onCategoryHeaderTap,
    this.onDayTap,
    this.onDeleteTransaction,
    this.onEditTransaction,
  });

  final List<HistoryExpenseModel> monthRecords;
  final List<CustomCategory> categories;
  final int month;
  final int year;
  final String currencySymbol;
  final Function(String? categoryKey)? onCategoryHeaderTap;
  final Function(int day)? onDayTap;
  final Function(HistoryExpenseModel transaction)? onDeleteTransaction;
  final Function(HistoryExpenseModel transaction)? onEditTransaction;

  String _keyOf(HistoryExpenseModel r) {
    if (r.categoryId.isNotEmpty) {
      for (final c in categories) {
        if (c.id == r.categoryId) return c.id;
      }
    }
    final name = r.categoryName?.trim() ?? '';
    if (name.isNotEmpty) {
      for (final c in categories) {
        if (c.id == name || c.name.toLowerCase() == name.toLowerCase()) {
          return c.id;
        }
      }
    }
    if (r.categoryId.isNotEmpty) return r.categoryId;
    if (name.isNotEmpty) return name;
    return 'other';
  }

  double _signed(HistoryExpenseModel r) =>
      r.type == TransactionType.income ? r.price : -r.price;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final whole = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final filtered = monthRecords
        .where((r) => r.date.month == month && r.date.year == year)
        .toList();

    final byDayCat = <int, Map<String, double>>{};
    final catMonth = <String, double>{};
    final dayNet = <int, double>{};

    for (final r in filtered) {
      final day = r.date.day;
      final key = _keyOf(r);
      byDayCat.putIfAbsent(day, () => {});
      byDayCat[day]![key] = (byDayCat[day]![key] ?? 0) + r.price;
      catMonth[key] = (catMonth[key] ?? 0) + r.price;
      dayNet[day] = (dayNet[day] ?? 0) + _signed(r);
    }

    final catById = {for (final c in categories) c.id: c};
    final cols = <_MatrixCol>[];
    final seen = <String>{};

    for (final c in categories) {
      if ((catMonth[c.id] ?? 0) <= 0) continue;
      seen.add(c.id);
      cols.add(
        _MatrixCol(
          id: c.id,
          title: c.localizedName(loc),
          isIncome: c.isIncome,
          icon: c.icon,
          color: c.color,
        ),
      );
    }
    for (final key in catMonth.keys) {
      if (seen.contains(key) || (catMonth[key] ?? 0) <= 0) continue;
      final c = catById[key];
      cols.add(
        _MatrixCol(
          id: key,
          title:
              c?.localizedName(loc) ??
              (key.startsWith('cat_') ? loc.otherCategory : key),
          isIncome: c?.isIncome ?? false,
          icon: c?.icon,
          color: c?.color,
        ),
      );
    }
    cols.sort((a, b) {
      final t = a.isIncome == b.isIncome ? 0 : (a.isIncome ? 1 : -1);
      return t != 0
          ? t
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    final days = dayNet.keys.toList()..sort();
    final grandNet = dayNet.values.fold<double>(0, (s, v) => s + v);

    final headerH = landscape ? 40.0 : 48.0;
    final rowH = landscape ? 36.0 : 44.0;
    final footerH = landscape ? 42.0 : 48.0;

    String money(double v) => '${whole.format(v.abs())} $currencySymbol';

    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Text(
          loc.noExpensesForMonth,
          style: TextStyle(color: LuminaTheme.textColor.withValues(alpha: 0.5)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.sizeOf(context).width;
        final hPad = landscape ? 8.0 : 16.0;
        final maxW =
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : screenW) -
            hPad * 2;

        const minCatW = 92.0;
        const minDayW = 64.0;
        const minNetW = 108.0;

        final catCount = cols.length;
        const dayW = minDayW;
        var netW = minNetW;
        final leftover = (maxW - dayW - netW).clamp(0.0, maxW).toDouble();
        final canFit = catCount == 0 || leftover >= catCount * minCatW;
        final catW = catCount == 0
            ? leftover
            : (canFit ? leftover / catCount : minCatW);

        if (catCount == 0) {
          netW = (maxW - dayW).clamp(minNetW, maxW).toDouble();
        }

        Widget cell({
          required double w,
          required double h,
          required Widget child,
          Color? bg,
          Alignment alignment = Alignment.centerLeft,
          EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8),
        }) {
          return Container(
            width: w,
            height: h,
            alignment: alignment,
            padding: padding,
            color: bg,
            child: child,
          );
        }

        Widget label(String text, {Color? color, double size = 12}) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? LuminaColors.primary,
                fontSize: size,
              ),
            ),
          );
        }

        Widget dayBadge(int day) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _showDayDetails(context, day, filtered, loc, locale, whole);
              onDayTap?.call(day);
            },
            child: cell(
              w: dayW,
              h: rowH,
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LuminaColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }

        Widget amountCell(double amount, double w, {required bool income}) {
          return cell(
            w: w,
            h: rowH,
            child: amount > 0
                ? Text(
                    money(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: landscape ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: income
                          ? LuminaColors.success
                          : LuminaTheme.textColor,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }

        Widget netCell(double net, double h, {Color? bg}) {
          return cell(
            w: netW,
            h: h,
            alignment: Alignment.centerRight,
            bg: bg,
            padding: const EdgeInsets.only(right: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${net >= 0 ? '+' : '−'}${money(net)}',
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: landscape ? 12 : 13,
                  color: net >= 0 ? LuminaColors.success : LuminaColors.error,
                ),
              ),
            ),
          );
        }

        final headerBg = LuminaColors.primary.withValues(alpha: 0.08);
        final footerBg = LuminaColors.primary.withValues(alpha: 0.14);

        final dayColumn = ColoredBox(
          color: LuminaColors.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              cell(
                w: dayW,
                h: headerH,
                bg: headerBg,
                alignment: Alignment.center,
                child: label(loc.day),
              ),
              ...days.map(dayBadge),
              cell(
                w: dayW,
                h: footerH,
                bg: footerBg,
                alignment: Alignment.center,
                child: label(loc.total),
              ),
            ],
          ),
        );

        final catColumns = [
          for (final col in cols)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                cell(
                  w: catW,
                  h: headerH,
                  bg: headerBg,
                  child: InkWell(
                    onTap: () => onCategoryHeaderTap?.call(col.id),
                    child: Row(
                      children: [
                        if (col.icon != null) ...[
                          Icon(
                            col.icon,
                            size: 14,
                            color: col.color ?? LuminaColors.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            col.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: LuminaTheme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final day in days)
                  amountCell(
                    byDayCat[day]?[col.id] ?? 0,
                    catW,
                    income: col.isIncome,
                  ),
                cell(
                  w: catW,
                  h: footerH,
                  bg: footerBg,
                  child: Text(
                    (catMonth[col.id] ?? 0) > 0 ? money(catMonth[col.id]!) : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: col.isIncome
                          ? LuminaColors.success
                          : LuminaTheme.textColor,
                    ),
                  ),
                ),
              ],
            ),
        ];

        final netColumn = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell(
              w: netW,
              h: headerH,
              bg: headerBg,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 10),
              child: label(loc.matrixNet),
            ),
            for (final day in days) netCell(dayNet[day]!, rowH),
            netCell(grandNet, footerH, bg: footerBg),
          ],
        );

        final dataRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [...catColumns, netColumn],
        );

        final table = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dayColumn,
            if (canFit)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.fill,
                  alignment: Alignment.centerLeft,
                  child: dataRow,
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: dataRow,
                ),
              ),
          ],
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(color: LuminaColors.surface, child: table),
          ),
        );
      },
    );
  }

  void _showDayDetails(
    BuildContext context,
    int day,
    List<HistoryExpenseModel> records,
    AppLocalizations loc,
    String locale,
    NumberFormat whole,
  ) {
    final dayRecords = records.where((r) => r.date.day == day).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final map = {for (final c in categories) c.id: c};
    final net = dayRecords.fold<double>(0, (s, r) => s + _signed(r));

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: LuminaColors.surface,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat(
                      'd MMMM y',
                      locale,
                    ).format(DateTime(year, month, day)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${net >= 0 ? '+' : '−'}${whole.format(net.abs())} $currencySymbol',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: net >= 0
                          ? LuminaColors.success
                          : LuminaColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: dayRecords.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = dayRecords[i];
                        final cat = map[_keyOf(r)];
                        final income = r.type == TransactionType.income;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            cat?.icon ?? Icons.receipt_long_rounded,
                            color: cat?.color,
                          ),
                          title: Text(
                            cat?.localizedName(loc) ?? loc.otherCategory,
                          ),
                          trailing: Text(
                            '${income ? '+' : '−'}${whole.format(r.price)} $currencySymbol',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: income
                                  ? LuminaColors.success
                                  : LuminaColors.error,
                            ),
                          ),
                        );
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
