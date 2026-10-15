import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/constants/app_tabs.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Нижняя панель. Позиционирует её родитель (MainShellScreen).
/// Размытие фона убрано: при прозрачности 0.9 оно почти не видно, зато
/// нагружает GPU на слабых устройствах.
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LuminaColors.cardMint.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: LuminaColors.cardMintBorder.withValues(alpha: 0.8),
        ),
        boxShadow: LuminaTheme.premiumShadow,
      ),
      child: SizedBox(
        height: 64,
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

    // isSelected передаёт состояние «выбрано» экранным дикторам.
    return IconButton(
      tooltip: tooltip,
      isSelected: isActive,
      icon: Icon(icon, size: 22, color: LuminaColors.textSecondary),
      selectedIcon: Icon(icon, size: 22, color: LuminaColors.accent),
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
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: LuminaColors.accent,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: LuminaColors.accent.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
