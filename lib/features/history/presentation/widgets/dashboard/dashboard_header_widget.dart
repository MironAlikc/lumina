import 'package:flutter/material.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/dashboard_filter_row.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/month_chips_bar.dart';

class DashboardHeaderWidget extends StatelessWidget {
  const DashboardHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonthChipsBar(),
            SizedBox(height: 10),
            DashboardFilterRow(),
          ],
        ),
      ),
    );
  }
}
