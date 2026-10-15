import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Диалог общего месячного лимита расходов.
class BudgetLimitSheet extends StatefulWidget {
  const BudgetLimitSheet({super.key, required this.currentLimit});

  final double currentLimit;

  static Future<void> show(BuildContext context, double currentLimit) {
    return showLuminaDialog<void>(
      context: context,
      child: BudgetLimitSheet(currentLimit: currentLimit),
    );
  }

  @override
  State<BudgetLimitSheet> createState() => _BudgetLimitSheetState();
}

class _BudgetLimitSheetState extends State<BudgetLimitSheet> {
  late final TextEditingController _controller;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLimit > 0 ? Money.forInput(widget.currentLimit) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = Money.parse(_controller.text);
    if (value == null || value <= 0) {
      HapticFeedback.heavyImpact();
      setState(() => _error = true);
      return;
    }
    context.read<HistoryCubit>().updateBudgetLimit(value);
    Navigator.of(context).pop();
  }

  void _clear() {
    context.read<HistoryCubit>().updateBudgetLimit(0);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.monthlyLimit,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.monthlyLimitLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: LuminaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
            onChanged: (_) {
              if (_error) setState(() => _error = false);
            },
            onSubmitted: (_) => _save(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: LuminaColors.textMain,
            ),
            decoration: InputDecoration(
              suffixText: symbol,
              errorText: _error ? loc.amountRequired : null,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(
                loc.saveLimit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (widget.currentLimit > 0) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clear,
              child: Text(
                loc.limitNotSet,
                style: const TextStyle(color: LuminaColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
