import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/constants/app_tabs.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';

class LuminaNavBarWidget extends StatelessWidget {
  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onAddPressed;

  const LuminaNavBarWidget({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                color: LuminaColors.cardMint.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: LuminaColors.cardMintBorder.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    AppTab.dashboard,
                    Icons.grid_view_rounded,
                    activeTab,
                    onTabSelected,
                  ),
                  _NavBarItem(
                    AppTab.analytics,
                    Icons.analytics_outlined,
                    activeTab,
                    onTabSelected,
                  ),
                  _AddButton(onTap: onAddPressed),
                  _NavBarItem(
                    AppTab.settings,
                    Icons.settings_rounded,
                    activeTab,
                    onTabSelected,
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
  final AppTab tab;
  final IconData icon;
  final AppTab activeTab;
  final ValueChanged<AppTab> onSelected;

  const _NavBarItem(this.tab, this.icon, this.activeTab, this.onSelected);

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == tab;
    return IconButton(
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
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}
