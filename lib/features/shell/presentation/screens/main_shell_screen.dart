import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/constants/app_tabs.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/widgets/lumina_nav_bar_widget.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.child});

  final Widget child;

  AppTab _getActiveTab(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    if (path.startsWith('/analytics')) return AppTab.analytics;
    if (path.startsWith('/settings')) return AppTab.settings;
    return AppTab.dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaColors.background,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          LuminaNavBarWidget(
            activeTab: _getActiveTab(context),
            onTabSelected: (tab) {
              switch (tab) {
                case AppTab.dashboard:
                  context.go('/dashboard');
                case AppTab.analytics:
                  context.go('/analytics');
                case AppTab.settings:
                  context.go('/settings');
              }
            },
            onAddPressed: () => context.push('/add-transaction'),
          ),
        ],
      ),
    );
  }
}
