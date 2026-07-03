import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/lumina_localizations.dart';
import '../cubits/history_cubit.dart';
import '../cubits/history_state.dart';
import 'expense_item.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = LuminaLocalizations.of(context);
    final String currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            if (state.expenses.isEmpty) {
              return Center(
                child: Text(
                  loc.translate('noExpenses') ?? 'Нет расходов',
                  style: const TextStyle(color: Colors.black38, fontSize: 16),
                ),
              );
            }

            // УРОВЕНЬ 2 UX: Умный расчет цвета прогресса лимита бюджета
            final double usageRatio = state.budgetLimit > 0
                ? (state.totalSpent / state.budgetLimit)
                : 0.0;

            Color progressColor = Colors.white.withOpacity(
              0.8,
            ); // До 80% — белый/светло-голубой
            if (usageRatio >= 1.0) {
              progressColor = const Color(
                0xFFEF4444,
              ); // Превышен — Ярко-Красный
            } else if (usageRatio >= 0.8) {
              progressColor = const Color(
                0xFFF59E0B,
              ); // В зоне риска (>=80%) — Оранжевый
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.translate('appName') ?? 'Lumina',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.language_rounded,
                            color: Color(0xFF0F172A),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 42,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.dateFilters.length,
                      itemBuilder: (context, index) {
                        final filter = state.dateFilters[index];
                        final isSelected = state.selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.lightImpact();
                              context.read<HistoryCubit>().changeFilter(
                                filter,
                                currentLocale,
                              );
                            },
                            // ИСПРАВЛЕНО: Современный способ задания цветов для ChoiceChip во Flutter 3+
                            color: WidgetStateProperty.resolveWith<Color?>((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFFDBEAFE);
                              }
                              return Colors.white;
                            }),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors
                                        .black54, // ИСПРАВЛЕНО: Colors.black65 -> Colors.black54
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.black12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // СИНЯЯ КАРТОЧКА С ДОБАВЛЕННЫМ БЮДЖЕТНЫМ ЛИМИТОМ И ПРОГРЕСС-БАРОМ
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.translate('totalSpentByFilter') ??
                                    'Всього витрачено за фільтром',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Лимит: ${state.budgetLimit.toStringAsFixed(0)} ₴',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${state.totalSpent.toStringAsFixed(2)} ₴',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // УРОВЕНЬ 2 UX: Тонкий красивый LinearProgressIndicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: state.budgetProgress,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          if (usageRatio >= 1.0)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                '⚠️ Бюджет превышен!',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 100,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          ExpenseItemWidget(item: state.expenses[index]),
                      childCount: state.expenses.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
