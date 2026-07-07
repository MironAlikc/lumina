import 'package:flutter/material.dart';
import 'package:lumina/features/history/presentation/widgets/expense_item_widget.dart';

class DashboardTransactionList extends StatelessWidget {
  final List<dynamic> records;
  const DashboardTransactionList({super.key, required this.records});

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ExpenseItemWidget(item: records[index]),
        ),
        childCount: records.length,
      ),
    ),
  );
}
