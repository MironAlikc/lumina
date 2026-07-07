import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/localization/lumina_localizations.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';

class DashboardFilterRow extends StatelessWidget {
  final HistoryState state;
  final LuminaLocalizations loc;
  const DashboardFilterRow({super.key, required this.state, required this.loc});

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: SizedBox(
      height: 42,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            state: state,
            type: HistoryFilterType.all,
            label: loc.translate('allFilter'),
          ),
          _FilterChip(
            state: state,
            type: HistoryFilterType.expense,
            label: loc.translate('expenseFilter'),
          ),
          _FilterChip(
            state: state,
            type: HistoryFilterType.income,
            label: loc.translate('incomeFilter'),
          ),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final HistoryState state;
  final HistoryFilterType type;
  final String label;
  const _FilterChip({
    required this.state,
    required this.type,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = state.activeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          HapticFeedback.lightImpact();
          context.read<HistoryCubit>().changeFilter(type);
        },
        color: WidgetStateProperty.resolveWith(
          (states) => isSelected
              ? LuminaTheme.accentColor.withValues(alpha: 0.12)
              : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9),
          ),
        ),
      ),
    );
  }
}
