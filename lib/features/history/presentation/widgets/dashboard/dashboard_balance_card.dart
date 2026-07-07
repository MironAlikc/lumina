import 'package:flutter/material.dart';
import 'package:lumina/core/localization/lumina_localizations.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';

class DashboardBalanceCard extends StatelessWidget {
  final HistoryState state;
  final LuminaLocalizations loc;
  const DashboardBalanceCard({
    super.key,
    required this.state,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final double usageRatio = state.budgetLimit > 0
        ? (state.totalExpenses / state.budgetLimit)
        : 0.0;
    final Color progressColor = usageRatio >= 1.0
        ? const Color(0xFFEF4444)
        : const Color(0xFFFF9F43);

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LuminaTheme.accentColor, Color(0xFF0096B4)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: LuminaTheme.accentColor.withValues(alpha: 0.3),
                blurRadius: 20,
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
                    loc.translate('pureBalance'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    '${loc.translate('limit')}: ${state.budgetLimit.toStringAsFixed(0)} ₴',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${state.totalBalance.toStringAsFixed(2)} ₴',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _TrendItem(
                    icon: Icons.south_east_rounded,
                    text: '+${state.totalIncomes.toStringAsFixed(0)} ₴',
                    color: const Color(0xFF4ADE80),
                  ),
                  const SizedBox(width: 20),
                  _TrendItem(
                    icon: Icons.north_east_rounded,
                    text: '-${state.totalExpenses.toStringAsFixed(0)} ₴',
                    color: const Color(0xFFFF8787),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: usageRatio.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _TrendItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
