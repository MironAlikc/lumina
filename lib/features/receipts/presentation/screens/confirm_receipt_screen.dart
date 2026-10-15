import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/receipts/data/services/receipt_parser.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';
import 'package:lumina/features/receipts/presentation/screens/confirm_receipt_items_screen.dart';
import 'package:lumina/features/receipts/presentation/widgets/receipt_account_picker.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// Выбирает экран подтверждения: список позиций или одна операция.
class ConfirmReceiptScreen extends StatelessWidget {
  const ConfirmReceiptScreen({super.key, required this.receipt});

  final ScannedReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return receipt.lines.length >= 2
        ? ConfirmReceiptItemsScreen(receipt: receipt)
        : _SingleReceiptView(receipt: receipt);
  }
}

class _SingleReceiptView extends StatefulWidget {
  const _SingleReceiptView({required this.receipt});

  final ScannedReceipt receipt;

  @override
  State<_SingleReceiptView> createState() => _SingleReceiptViewState();
}

class _SingleReceiptViewState extends State<_SingleReceiptView> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late DateTime _date;
  String? _categoryId;
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final receipt = widget.receipt;
    _name = TextEditingController(text: receipt.merchant);
    final value = receipt.amount;
    _amount = TextEditingController(
      text: value > 0
          ? value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)
          : '',
    );
    _date = receipt.date;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Выбор пользователя, затем подсказка из чека, затем первая категория.
  CustomCategory? _effectiveCategory(List<CustomCategory> expenses) {
    if (expenses.isEmpty) return null;
    final suggested = widget.receipt.lines.firstOrNull?.suggestedCategoryId;
    for (final id in [_categoryId, suggested]) {
      final found = expenses.where((c) => c.id == id).firstOrNull;
      if (found != null) return found;
    }
    return expenses.first;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(2000);
    final last = DateTime(now.year, now.month, now.day);

    // initialDate вне диапазона роняет showDatePicker.
    var initial = DateUtils.dateOnly(_date);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    // Время из чека сохраняем: меняется только день.
    setState(
      () => _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      ),
    );
  }

  Future<void> _save(CustomCategory? category, String? accountId) async {
    if (_saving) return;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<HistoryCubit>();

    final amount = ReceiptParser.parseAmount(_amount.text) ?? 0;
    if (amount <= 0 || category == null) {
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Text(amount <= 0 ? loc.amountRequired : loc.chooseCategory),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final note = _name.text.trim();
    try {
      await cubit.addRecord(
        HistoryExpense(
          id: const Uuid().v4(),
          date: _date,
          productName: note.isNotEmpty ? note : category.localizedName(loc),
          price: amount,
          category: category.id,
          type: category.type,
          isSynced: false,
          accountId: accountId,
        ),
      );
      if (mounted) navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  InputDecoration _decoration(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: LuminaColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    final catState = context.watch<CategoriesCubit>().state;
    final accounts = context.watch<AccountCubit>().state.accounts;

    final expenses = catState is CategoriesLoaded
        ? [
            for (final c in catState.categories)
              if (c.type == CustomCategory.typeExpense) c,
          ]
        : const <CustomCategory>[];
    final category = _effectiveCategory(expenses);
    final accountId = ReceiptAccountPicker.resolve(accounts, _accountId);

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        backgroundColor: LuminaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(loc.merchantHint).copyWith(counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: _decoration(loc.amountLabel, suffix: symbol),
          ),
          const SizedBox(height: 12),
          ReceiptAccountPicker(
            accounts: accounts,
            value: accountId,
            onChanged: (id) => setState(() => _accountId = id),
          ),
          if (accounts.isNotEmpty) const SizedBox(height: 12),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: LuminaColors.surface,
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
              for (final cat in expenses)
                ChoiceChip(
                  selected: cat.id == category?.id,
                  label: Text(cat.localizedName(loc)),
                  avatar: Icon(
                    cat.icon,
                    size: 16,
                    color: cat.id == category?.id ? Colors.white : cat.color,
                  ),
                  showCheckmark: false,
                  selectedColor: LuminaColors.primary,
                  labelStyle: TextStyle(
                    color: cat.id == category?.id
                        ? Colors.white
                        : LuminaColors.textMain,
                  ),
                  onSelected: (_) => setState(() => _categoryId = cat.id),
                ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: LuminaDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _save(category, accountId),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
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
