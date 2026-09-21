import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/constants/app_tabs.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/l10n/app_localizations.dart';

class LuminaNavBarWidget extends StatelessWidget {
  const LuminaNavBarWidget({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Positioned(
      left: 20,
      right: 20,
      bottom: MediaQuery.paddingOf(context).bottom + 14,
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
                color: LuminaColors.cardMint.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: LuminaColors.cardMintBorder.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    tab: AppTab.dashboard,
                    icon: Icons.grid_view_rounded,
                    tooltip: loc.pureBalance,
                    activeTab: activeTab,
                    onSelected: onTabSelected,
                  ),
                  _NavBarItem(
                    tab: AppTab.analytics,
                    icon: Icons.analytics_outlined,
                    tooltip: loc.expenses,
                    activeTab: activeTab,
                    onSelected: onTabSelected,
                  ),
                  _AddButton(onTap: onAddPressed, tooltip: loc.create),
                  _NavBarItem(
                    tab: AppTab.settings,
                    icon: Icons.settings_rounded,
                    tooltip: loc.settingsTitle,
                    activeTab: activeTab,
                    onSelected: onTabSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.tab,
    required this.icon,
    required this.tooltip,
    required this.activeTab,
    required this.onSelected,
  });

  final AppTab tab;
  final IconData icon;
  final String tooltip;
  final AppTab activeTab;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == tab;
    return IconButton(
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 22,
        color: isActive ? LuminaTheme.accentColor : LuminaTheme.subTitleColor,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onSelected(tab);
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: LuminaTheme.accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LuminaTheme.accentColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
