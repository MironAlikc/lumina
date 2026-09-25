import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ConfirmReceiptScreen extends StatefulWidget {
  const ConfirmReceiptScreen({super.key, required this.receipt});

  final ScannedReceipt receipt;

  @override
  State<ConfirmReceiptScreen> createState() => _ConfirmReceiptScreenState();
}

class _ConfirmReceiptScreenState extends State<ConfirmReceiptScreen> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late DateTime _date;
  CustomCategory? _category;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.receipt.merchant);
    _amount = TextEditingController(
      text: widget.receipt.amount > 0
          ? widget.receipt.amount.toStringAsFixed(
              widget.receipt.amount == widget.receipt.amount.roundToDouble()
                  ? 0
                  : 2,
            )
          : '',
    );
    _date = widget.receipt.date;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_category != null) return;
    final state = context.read<CategoriesCubit>().state;
    if (state is CategoriesLoaded) {
      final expenses = state.categories.where((c) => c.type == 'expense');
      _category = expenses.isNotEmpty ? expenses.first : null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final amount =
        double.tryParse(_amount.text.replaceAll(',', '.').trim()) ?? 0;
    if (amount <= 0 || _category == null) {
      HapticFeedback.heavyImpact();
      if (amount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.scanNothingFound)));
      }
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final note = _name.text.trim();
    final entity = HistoryExpense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _date,
      productName: note.isNotEmpty ? note : _category!.localizedName(loc),
      price: amount,
      category: _category!.id,
      type: _category!.type,
      isSynced: false,
    );

    try {
      await context.read<HistoryCubit>().addRecord(entity);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    final catState = context.watch<CategoriesCubit>().state;
    final categories = catState is CategoriesLoaded
        ? catState.categories.where((c) => c.type == 'expense').toList()
        : const <CustomCategory>[];

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        backgroundColor: LuminaColors.background,
        elevation: 0,
        title: Text(
          loc.scanReceiptTitle,
          style: const TextStyle(
            color: LuminaColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: LuminaColors.textMain),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: loc.merchantHint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: loc.goalsDepositAmount(symbol),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: Colors.white,
            leading: const Icon(
              Icons.calendar_today_rounded,
              color: LuminaColors.primary,
            ),
            title: Text(
              DateFormat('d MMMM y', locale).format(_date),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: LuminaColors.textMain,
              ),
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          Text(
            loc.chooseCategory,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: LuminaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in categories)
                ChoiceChip(
                  selected: cat.id == _category?.id,
                  label: Text(cat.localizedName(loc)),
                  avatar: Icon(
                    cat.icon,
                    size: 16,
                    color: cat.id == _category?.id ? Colors.white : cat.color,
                  ),
                  selectedColor: LuminaColors.primary,
                  labelStyle: TextStyle(
                    color: cat.id == _category?.id
                        ? Colors.white
                        : LuminaColors.textMain,
                  ),
                  onSelected: (_) => setState(() => _category = cat),
                ),
            ],
          ),
          if (widget.receipt.lines.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              loc.receiptLines,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: LuminaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in widget.receipt.lines)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(line.name),
                trailing: Text(
                  '${line.amount.toStringAsFixed(2)} $symbol',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: LuminaColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: LuminaDimensions.borderRadiusMedium,
                ),
              ),
              child: Text(
                loc.confirmReceipt,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
