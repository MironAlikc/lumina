import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

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

  String _keyOf(HistoryExpenseModel r) =>
      r.categoryId.isNotEmpty ? r.categoryId : (r.categoryName ?? 'other');

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

    final visible = categories.where((c) => (catMonth[c.id] ?? 0) > 0).toList()
      ..sort((a, b) {
        final t = a.type.compareTo(b.type);
        return t != 0
            ? t
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final days = dayNet.keys.toList()..sort();
    final grandNet = dayNet.values.fold<double>(0, (s, v) => s + v);

    final headerH = landscape ? 36.0 : 44.0;
    final rowH = landscape ? 34.0 : 42.0;
    final footerH = landscape ? 38.0 : 44.0;
    const dayW = 46.0;
    const netW = 96.0;

    String money(double v) => '${whole.format(v.abs())} $currencySymbol';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final catCount = visible.length;
        final leftover = maxW - dayW - netW;
        final fits = catCount == 0 || leftover / catCount >= 72;
        final colW = catCount == 0
            ? 80.0
            : (fits ? leftover / catCount : (landscape ? 84.0 : 96.0));

        Widget headerCell(Widget child, double w, {Color? bg}) {
          return Container(
            width: w,
            height: headerH,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: bg,
            child: child,
          );
        }

        Widget dayBadge(int day) {
          return GestureDetector(
            onTap: () {
              _showDayDetails(context, day, filtered, loc, locale, whole);
              onDayTap?.call(day);
            },
            child: Container(
              width: dayW,
              height: rowH,
              alignment: Alignment.center,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LuminaColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }

        Widget amountCell(double amount, double w, {required bool income}) {
          return Container(
            width: w,
            height: rowH,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: amount > 0
                ? Text(
                    money(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: landscape ? 11.5 : 13,
                      fontWeight: FontWeight.w600,
                      color: income
                          ? LuminaColors.success
                          : LuminaTheme.textColor,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }

        Widget netCell(double net, double h) {
          return Container(
            width: netW,
            height: h,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${net >= 0 ? '+' : '−'}${money(net)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: landscape ? 11.5 : 13,
                color: net >= 0 ? LuminaColors.success : LuminaColors.error,
              ),
            ),
          );
        }

        final dayColumn = ColoredBox(
          color: LuminaColors.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              headerCell(
                Text(
                  loc.day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.primary,
                    fontSize: 12,
                  ),
                ),
                dayW,
                bg: LuminaColors.primary.withValues(alpha: 0.08),
              ),
              ...days.map(dayBadge),
              headerCell(
                Text(
                  loc.total,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.primary,
                    fontSize: 12,
                  ),
                ),
                dayW,
                bg: LuminaColors.primary.withValues(alpha: 0.15),
              ),
            ],
          ),
        );

        final dataColumns = Row(
          children: [
            for (final cat in visible)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  headerCell(
                    InkWell(
                      onTap: () => onCategoryHeaderTap?.call(cat.id),
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 14, color: cat.color),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cat.localizedName(loc),
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
                    colW,
                    bg: LuminaColors.primary.withValues(alpha: 0.08),
                  ),
                  for (final day in days)
                    amountCell(
                      byDayCat[day]?[cat.id] ?? 0,
                      colW,
                      income: cat.isIncome,
                    ),
                  headerCell(
                    Text(
                      (catMonth[cat.id] ?? 0) > 0
                          ? money(catMonth[cat.id]!)
                          : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: cat.isIncome
                            ? LuminaColors.success
                            : LuminaTheme.textColor,
                      ),
                    ),
                    colW,
                    bg: LuminaColors.primary.withValues(alpha: 0.15),
                  ),
                ],
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                headerCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      loc.matrixNet,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  netW,
                  bg: LuminaColors.primary.withValues(alpha: 0.08),
                ),
                for (final day in days) netCell(dayNet[day]!, rowH),
                netCell(grandNet, footerH),
              ],
            ),
          ],
        );

        final table = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dayColumn,
            if (fits)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: dataColumns,
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: dataColumns,
                ),
              ),
          ],
        );

        if (days.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              loc.noExpensesForMonth,
              style: TextStyle(
                color: LuminaTheme.textColor.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            landscape ? 8 : 12,
            0,
            landscape ? 8 : 12,
            8,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: table,
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(ctx).bottom + 16,
          ),
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
                  color: net >= 0 ? LuminaColors.success : LuminaColors.error,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dayRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = dayRecords[i];
                    final cat = map[r.categoryId];
                    final income = r.type == TransactionType.income;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        cat?.icon ?? Icons.receipt_long_rounded,
                        color: cat?.color,
                      ),
                      title: Text(cat?.localizedName(loc) ?? loc.otherCategory),
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
        );
      },
    );
  }
}
