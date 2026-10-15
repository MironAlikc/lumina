import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_tile.dart';
import 'package:lumina/features/transactions/data/services/export_service.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ExportSettingsTile extends StatefulWidget {
  const ExportSettingsTile({super.key});

  @override
  State<ExportSettingsTile> createState() => _ExportSettingsTileState();
}

class _ExportSettingsTileState extends State<ExportSettingsTile> {
  bool _busy = false;

  SnackBar _snack(String text) => SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        content: Text(text),
      );

  Future<void> _export() async {
    if (_busy) return;
    HapticFeedback.lightImpact();

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Данные читаются в момент нажатия: плитке не нужно перестраиваться.
    final state = context.read<HistoryCubit>().state;
    final catState = context.read<CategoriesCubit>().state;
    final categories = catState is CategoriesLoaded
        ? catState.categories
        : const <CustomCategory>[];

    // Для iPad: popover шторки «Поделиться» привязывается к плитке.
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    setState(() => _busy = true);
    try {
      await ExportService.exportMonthToCSV(
        state.allRecords,
        categories,
        state.selectedMonth,
        state.selectedYear,
        loc,
        sharePositionOrigin: origin,
      );
      messenger.showSnackBar(_snack(loc.exportSuccess));
    } on ExportEmptyException {
      messenger.showSnackBar(_snack(loc.noExpensesForMonth));
    } catch (_) {
      messenger.showSnackBar(_snack(loc.exportFailed));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final (month, year) = context.select(
      (HistoryCubit c) => (c.state.selectedMonth, c.state.selectedYear),
    );

    final raw = DateFormat.yMMMM(locale).format(DateTime(year, month));
    final period =
        raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';

    return SettingsTile(
      icon: Icons.table_chart_rounded,
      iconColor: LuminaColors.success,
      title: loc.exportToExcel,
      subtitle: period,
      trailing: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _export,
    );
  }
}
