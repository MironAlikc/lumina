import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/lumina_nav_bar_widget.dart';

// Убедись, что AppTab определен в проекте (импортируй его оттуда)
// Если он был в NavigationCubit, перемести его в отдельный файл или в NavBar
import 'package:lumina/core/constants/app_tabs.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  AppTab _getActiveTab(BuildContext context) {
    // Получаем текущий путь из GoRouter
    final String location = GoRouterState.of(context).uri.toString();

    if (location.contains('/analytics')) return AppTab.analytics;
    if (location.contains('/settings')) return AppTab.settings;
    return AppTab.dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaTheme.backgroundColor,
      extendBody: true,
      // Stack позволяет Nav Bar "плавать" поверх контента
      body: Stack(
        children: [
          Positioned.fill(child: child),

          LuminaNavBarWidget(
            activeTab: _getActiveTab(context),
            onTabSelected: (tab) {
              switch (tab) {
                case AppTab.dashboard:
                  context.go('/dashboard');
                  break;
                case AppTab.analytics:
                  context.go('/analytics');
                  break;
                case AppTab.settings:
                  context.go('/settings');
                  break;
              }
            },
            onAddPressed: () => context.push('/add-transaction'),
          ),
        ],
      ),
    );
  }
}
