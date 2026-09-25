import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/data/services/export_service.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ExportSettingsTile extends StatefulWidget {
  const ExportSettingsTile({super.key, required this.state});

  final HistoryState state;

  @override
  State<ExportSettingsTile> createState() => _ExportSettingsTileState();
}

class _ExportSettingsTileState extends State<ExportSettingsTile> {
  var _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final state = widget.state;

    try {
      final catState = context.read<CategoriesCubit>().state;
      final categories = catState is CategoriesLoaded
          ? catState.categories
          : const <CustomCategory>[];

      await ExportService.exportMonthToCSV(
        state.allRecords.map(HistoryExpenseModel.fromEntity).toList(),
        categories,
        state.selectedMonth,
        state.selectedYear,
        loc,
      );

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          content: Text(loc.exportSuccess),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          content: Text(loc.exportFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SettingsTile(
      icon: Icons.table_chart_rounded,
      iconColor: LuminaColors.success,
      title: loc.exportToExcel,
      trailing: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _busy ? () {} : _export,
    );
  }
}
