import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/dashboard_balance_card.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/dashboard_filter_row.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/dashboard_transaction_list.dart';
import '../../../../core/localization/lumina_localizations.dart';
import '../cubits/history_cubit.dart';
import '../cubits/history_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LuminaLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                DashboardHeader(title: loc.translate('appName')),
                DashboardFilterRow(state: state, loc: loc),
                DashboardBalanceCard(state: state, loc: loc),
                DashboardTransactionList(records: state.filteredRecords),
              ],
            );
          },
        ),
      ),
    );
  }
}
