import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/lumina_theme.dart';
import '../../../presentation/cubits/navigation/navigation_cubit.dart';
import '../../history/presentation/views/dashboard_view.dart';
import '../../analytics/presentation/views/analytics_view.dart';
import '../../profile/presentation/views/settings_view.dart';
import '../../history/presentation/views/add_transaction_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  static void openQuickAdd(
    BuildContext context, {
    String? name,
    double? price,
  }) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    state?.openQuickAddScreenFromExternal(name: name, price: price);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void openQuickAddScreenFromExternal({String? name, double? price}) {
    _navigateToChooseTransactionScreen(context);
  }

  void _navigateToChooseTransactionScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (modalContext) => const AddTransactionView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaTheme.backgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: BlocBuilder<NavigationCubit, AppTab>(
              builder: (context, tab) {
                return IndexedStack(
                  index: AppTab.values.indexOf(tab),
                  children: const [
                    DashboardView(),
                    AnalyticsView(),
                    SettingsView(),
                  ],
                );
              },
            ),
          ),

          // Воздушная капсула нижней панели навигации
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: LuminaTheme.premiumShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      // Современный стандарт с withValues
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.04),
                        width: 1.0,
                      ),
                    ),
                    child: BlocBuilder<NavigationCubit, AppTab>(
                      builder: (context, activeTab) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              context,
                              AppTab.history,
                              Icons.grid_view_rounded,
                              activeTab,
                            ),
                            _buildNavItem(
                              context,
                              AppTab.analytics,
                              Icons.analytics_outlined,
                              activeTab,
                            ),

                            // Центральная кнопка
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _navigateToChooseTransactionScreen(context);
                              },
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: LuminaTheme.accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: LuminaTheme.accentColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
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

                            _buildNavItem(
                              context,
                              AppTab.settings,
                              Icons.settings_rounded,
                              activeTab,
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

  Widget _buildNavItem(
    BuildContext context,
    AppTab tab,
    IconData icon,
    AppTab activeTab,
  ) {
    return IconButton(
      icon: Icon(
        icon,
        size: 22,
        color: activeTab == tab
            ? LuminaTheme.accentColor
            : LuminaTheme.subTitleColor,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        context.read<NavigationCubit>().selectTab(tab);
      },
    );
  }
}
