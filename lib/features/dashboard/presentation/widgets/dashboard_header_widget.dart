import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/widgets/month_selector_widget.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';

/// Выбор месяца: от него зависят итоги, список и фильтры на дашборде.
class DashboardHeaderWidget extends StatelessWidget {
  const DashboardHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      buildWhen: (p, n) =>
          p.selectedMonth != n.selectedMonth ||
          p.selectedYear != n.selectedYear,
      builder: (context, s) => MonthSelectorWidget(
        selectedMonth: s.selectedMonth,
        selectedYear: s.selectedYear,
        onMonthChanged: (month, year) =>
            context.read<HistoryCubit>().changeMonth(month, year),
      ),
    );
  }
}
