import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';

class MonthTabsWidget extends StatefulWidget {
  const MonthTabsWidget({super.key});

  @override
  State<MonthTabsWidget> createState() => _MonthTabsWidgetState();
}

class _MonthTabsWidgetState extends State<MonthTabsWidget> {
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, Object>> _months = [
    {'month': 1, 'name': 'Янв'},
    {'month': 2, 'name': 'Фев'},
    {'month': 3, 'name': 'Мар'},
    {'month': 4, 'name': 'Апр'},
    {'month': 5, 'name': 'Май'},
    {'month': 6, 'name': 'Июн'},
    {'month': 7, 'name': 'Июл'},
    {'month': 8, 'name': 'Авг'},
    {'month': 9, 'name': 'Сен'},
    {'month': 10, 'name': 'Окт'},
    {'month': 11, 'name': 'Ноя'},
    {'month': 12, 'name': 'Дек'},
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, historyState) {
        return SizedBox(
          height: 38,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _months.length,
            itemBuilder: (context, index) {
              final item = _months[index];
              final monthNum = item['month'] as int;
              final monthName = item['name'] as String;
              final isSelected =
                  historyState.selectedMonth == monthNum &&
                  historyState.selectedYear == currentYear;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<HistoryCubit>().changeMonth(
                      monthNum,
                      currentYear,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? LuminaTheme.accentColor
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: LuminaTheme.accentColor.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.015),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        monthName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : LuminaTheme.textColor.withValues(alpha: 0.8),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
