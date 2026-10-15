import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/receipts/data/services/receipt_parser.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';
import 'package:lumina/features/receipts/presentation/widgets/receipt_account_picker.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class ConfirmReceiptItemsScreen extends StatefulWidget {
  const ConfirmReceiptItemsScreen({super.key, required this.receipt});

  final ScannedReceipt receipt;

  @override
  State<ConfirmReceiptItemsScreen> createState() =>
      _ConfirmReceiptItemsScreenState();
}

class _ConfirmReceiptItemsScreenState extends State<ConfirmReceiptItemsScreen> {
  late List<ScannedLine> _lines;
  final _chosenCategory = <int, String>{};
  final _selected = <int>{};
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lines = List.of(widget.receipt.lines);
    _selected.addAll(List.generate(_lines.length, (i) => i));
  }

  /// Выбор пользователя, затем подсказка парсера, затем первая категория.
  /// Считается при отрисовке, поэтому загрузка категорий позже ничего не ломает.
  CustomCategory? _effective(List<CustomCategory> expenses, int index) {
    if (expenses.isEmpty) return null;
    for (final id in [
      _chosenCategory[index],
      _lines[index].suggestedCategoryId
    ]) {
      final found = expenses.where((c) => c.id == id).firstOrNull;
      if (found != null) return found;
    }
    return expenses.first;
  }

  Future<void> _pickCategory(int index, List<CustomCategory> expenses) async {
    if (expenses.isEmpty) return;
    final loc = AppLocalizations.of(context)!;

    final picked = await showModalBottomSheet<CustomCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: LuminaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.chooseCategory,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: LuminaColors.textMain,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in expenses)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: c.color.withValues(alpha: 0.15),
                        child: Icon(c.icon, color: c.color, size: 20),
                      ),
                      title: Text(c.localizedName(loc)),
                      onTap: () => Navigator.pop(ctx, c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _chosenCategory[index] = picked.id);
  }

  Future<void> _editLine(int index) async {
    final edited = await showLuminaDialog<ScannedLine>(
      context: context,
      child: _LineEditor(line: _lines[index]),
    );
    if (edited == null || !mounted) return;
    setState(() => _lines[index] = edited);
  }

  Future<void> _save(List<CustomCategory> expenses, String? accountId) async {
    if (_saving) return;
    final chosen = _selected.toList()..sort();
    if (chosen.isEmpty) return;

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<HistoryCubit>();

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final savedIds = <String>[];
    try {
      for (final i in chosen) {
        final line = _lines[i];
        final category = _effective(expenses, i);
        if (category == null || line.price <= 0) continue;

        final id = const Uuid().v4();
        await cubit.addRecord(
          HistoryExpense(
            id: id,
            date: widget.receipt.date,
            productName: line.name,
            price: line.price,
            category: category.id,
            type: category.type,
            isSynced: false,
            accountId: accountId,
          ),
        );
        savedIds.add(id);
      }

      if (savedIds.isEmpty) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      if (mounted) navigator.pop(true);
    } catch (_) {
      // Всё или ничего: откатываем уже сохранённые позиции вместе с балансом,
      // иначе повторная попытка создаст дубли.
      for (final id in savedIds.reversed) {
        try {
          await cubit.removeRecord(id);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
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
    final accountId = ReceiptAccountPicker.resolve(accounts, _accountId);

    final money = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    final selectedTotal =
        _selected.fold<double>(0, (sum, i) => sum + _lines[i].price);
    final canSave = !_saving && _selected.isNotEmpty && expenses.isNotEmpty;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        backgroundColor: LuminaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.receipt.merchant.isEmpty
              ? loc.scanReceiptTitle
              : widget.receipt.merchant,
        ),
        actions: [
          TextButton(
            onPressed: canSave ? () => _save(expenses, accountId) : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    loc.done,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (accounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: ReceiptAccountPicker(
                accounts: accounts,
                value: accountId,
                onChanged: (id) => setState(() => _accountId = id),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Text(
                  loc.receiptLines,
                  style: const TextStyle(
                    color: LuminaColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${money.format(selectedTotal)} $symbol',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final line = _lines[index];
                final category = _effective(expenses, index);
                final on = _selected.contains(index);

                void toggle(bool? value) {
                  setState(() {
                    if (value ?? !on) {
                      _selected.add(index);
                    } else {
                      _selected.remove(index);
                    }
                  });
                }

                return Material(
                  color: LuminaColors.surface,
                  borderRadius: LuminaDimensions.borderRadiusMedium,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => toggle(null),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(value: on, onChanged: toggle),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: LuminaColors.textMain,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _pickCategory(index, expenses),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          category?.icon ??
                                              Icons.category_outlined,
                                          size: 16,
                                          color: category?.color ??
                                              LuminaColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            category?.localizedName(loc) ??
                                                loc.chooseCategory,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: category?.color ??
                                                  LuminaColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.expand_more_rounded,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${money.format(line.price)} $symbol',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: LuminaColors.textMain,
                            ),
                          ),
                          IconButton(
                            tooltip: loc.change,
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: LuminaColors.textSecondary,
                            ),
                            onPressed: () => _editLine(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Диалог правки названия и цены позиции: OCR часто ошибается.
class _LineEditor extends StatefulWidget {
  const _LineEditor({required this.line});

  final ScannedLine line;

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  bool _nameError = false;
  bool _priceError = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.line.name);
    final p = widget.line.price;
    _price = TextEditingController(
      text: p.toStringAsFixed(p == p.roundToDouble() ? 0 : 2),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final price = ReceiptParser.parseAmount(_price.text);
    setState(() {
      _nameError = name.isEmpty;
      _priceError = price == null || price <= 0;
    });
    if (_nameError || _priceError) return;
    Navigator.of(context).pop(widget.line.copyWith(name: name, price: price));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.change,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: loc.nameLabel,
              counterText: '',
              errorText: _nameError ? loc.accountNameRequired : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: loc.amountLabel,
              errorText: _priceError ? loc.amountRequired : null,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(loc.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
