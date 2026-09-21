import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';

class MonthChipsBar extends StatefulWidget {
  const MonthChipsBar({super.key});

  @override
  State<MonthChipsBar> createState() => _MonthChipsBarState();
}

class _MonthChipsBarState extends State<MonthChipsBar> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final month = context.read<HistoryCubit>().state.selectedMonth;
      _scrollToMonth(month);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMonth(int month) {
    if (!_scrollController.hasClients) return;
    const itemExtent = 64.0;
    final offset = ((month - 1) * itemExtent).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return BlocBuilder<HistoryCubit, HistoryState>(
      buildWhen: (p, n) =>
          p.selectedMonth != n.selectedMonth ||
          p.selectedYear != n.selectedYear,
      builder: (context, historyState) {
        return SizedBox(
          height: 38,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthNum = index + 1;
              final monthName = DateFormat.MMM(
                locale,
              ).format(DateTime(historyState.selectedYear, monthNum, 1));
              final isSelected = historyState.selectedMonth == monthNum;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<HistoryCubit>().changeMonth(
                      monthNum,
                      historyState.selectedYear,
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
