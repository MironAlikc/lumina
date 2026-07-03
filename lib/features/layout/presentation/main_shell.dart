import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Добавлен для HapticFeedback
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/lumina_localizations.dart';
import '../../../presentation/cubits/navigation/navigation_cubit.dart';
import '../../history/presentation/cubits/history_cubit.dart';
import '../../history/presentation/cubits/history_state.dart';
import '../../history/presentation/views/dashboard_view.dart';
import '../../analytics/presentation/views/analytics_view.dart';
import '../../analytics/presentation/cubits/analytics_cubit.dart';

class MainShell extends StatelessWidget {
  const MainShell({Key? key}) : super(key: key);

  // Внутренний метод открытия нижней шторки с параметрами инициализации
  void _openQuickAddBottomSheet(
    BuildContext context, {
    String? initialName,
    double? initialPrice,
  }) {
    final nameController = TextEditingController(text: initialName);
    final priceController = TextEditingController(
      text: initialPrice != null && initialPrice > 0
          ? initialPrice.toStringAsFixed(2)
          : '',
    );

    final historyCubit = context.read<HistoryCubit>();
    final analyticsCubit = context.read<AnalyticsCubit>();
    final loc = LuminaLocalizations.of(context);
    final String currentLocale = Localizations.localeOf(context).languageCode;

    if (initialName != null && initialName.isNotEmpty) {
      historyCubit.searchAutocomplete(initialName);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: historyCubit),
          BlocProvider.value(value: analyticsCubit),
        ],
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.translate('addPurchase'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                BlocBuilder<HistoryCubit, HistoryState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          onChanged: (val) {
                            context.read<HistoryCubit>().searchAutocomplete(
                              val,
                            );
                            setModalState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: loc.translate('productName'),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (state.autocompleteSuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 45,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.autocompleteSuggestions.length,
                              itemBuilder: (context, i) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ActionChip(
                                    label: Text(
                                      state.autocompleteSuggestions[i],
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      nameController.text =
                                          state.autocompleteSuggestions[i];
                                      context
                                          .read<HistoryCubit>()
                                          .searchAutocomplete(
                                            nameController.text,
                                          );
                                      if (context
                                              .read<HistoryCubit>()
                                              .state
                                              .suggestedPrice >
                                          0) {
                                        priceController.text = context
                                            .read<HistoryCubit>()
                                            .state
                                            .suggestedPrice
                                            .toString();
                                      }
                                      setModalState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        if (state.suggestedPrice > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4),
                            child: Text(
                              'Предыдущая цена: ${state.suggestedPrice.toStringAsFixed(2)} ₴',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.translate('price'),
                    suffixText: '₴',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty &&
                          priceController.text.isNotEmpty) {
                        final price =
                            double.tryParse(priceController.text) ?? 0.0;

                        HapticFeedback.mediumImpact();

                        await historyCubit.addRecord(
                          nameController.text,
                          price,
                          currentLocale,
                        );

                        analyticsCubit.executeSearch(
                          analyticsCubit.state.searchQuery,
                        );

                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      loc.translate('addButton'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ИСПРАВЛЕНО: Безопасный поиск виджета-предка MainShell по дереву виджетов
  static void openQuickAdd(
    BuildContext context, {
    String? name,
    double? price,
  }) {
    final mainShell = context.findAncestorWidgetOfExactType<MainShell>();
    if (mainShell != null) {
      mainShell._openQuickAddBottomSheet(
        context,
        initialName: name,
        initialPrice: price,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: BlocBuilder<NavigationCubit, AppTab>(
              builder: (context, tab) {
                return tab == AppTab.history
                    ? const DashboardView()
                    : const AnalyticsView();
              },
            ),
          ),

          // Воздушная капсула навигации
          Positioned(
            left: 32,
            right: 32,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.06),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1.0,
                      ),
                    ),
                    child: BlocBuilder<NavigationCubit, AppTab>(
                      builder: (context, activeTab) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view_rounded,
                                size: 23,
                                color: activeTab == AppTab.history
                                    ? const Color(0xFF3B82F6)
                                    : Colors.black45,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.read<NavigationCubit>().selectTab(
                                  AppTab.history,
                                );
                              },
                            ),

                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _openQuickAddBottomSheet(context);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B82F6),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x333B82F6),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),

                            IconButton(
                              icon: Icon(
                                Icons.analytics_outlined,
                                size: 23,
                                color: activeTab == AppTab.analytics
                                    ? const Color(0xFF3B82F6)
                                    : Colors.black45,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.read<NavigationCubit>().selectTab(
                                  AppTab.analytics,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
