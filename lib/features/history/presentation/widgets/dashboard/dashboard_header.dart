import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_theme.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  const DashboardHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    sliver: SliverToBoxAdapter(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: LuminaTheme.textColor,
          letterSpacing: -0.5,
        ),
      ),
    ),
  );
}
