import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/receipts/presentation/widgets/receipt_account_picker.dart';
import 'package:lumina/features/recurring/data/models/recurring_expense_model.dart';
import 'package:lumina/features/recurring/data/services/recurring_service.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

typedef _RecurringInput = ({
  String name,
  double price,
  String categoryId,
  bool isIncome,
  int day,
  String? accountId,
});

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  /// Удалённые шаблоны скрываются сразу: запись в Hive асинхронна, а
  /// Dismissible требует убрать элемент из дерева в том же кадре.
  final _hidden = <String>{};

  List<CustomCategory> _categories() {
    final state = context.read<CategoriesCubit>().state;
    return state is CategoriesLoaded ? state.categories : const [];
  }

  Future<void> _openEditor({RecurringExpenseModel? item}) async {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final history = context.read<HistoryCubit>();
    final symbol = context.read<CurrencyCubit>().state.symbol;

    final input = await showLuminaDialog<_RecurringInput>(
      context: context,
      child: _RecurringEditor(
        symbol: symbol,
        categories: _categories(),
        item: item,
      ),
    );
    if (input == null) return;

    try {
      if (item == null) {
        await RecurringService.addRecurring(
          productName: input.name,
          price: input.price,
          categoryId: input.categoryId,
          isIncome: input.isIncome,
          dayOfMonth: input.day,
          accountId: input.accountId,
        );
      } else {
        await RecurringService.update(
          id: item.id,
          productName: input.name,
          price: input.price,
          categoryId: input.categoryId,
          isIncome: input.isIncome,
          dayOfMonth: input.day,
          accountId: input.accountId,
        );
      }
      // Если день уже наступил, платёж проводится сразу, а не при
      // следующем запуске приложения.
      await history.processRecurring();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  void _delete(RecurringExpenseModel item) {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    HapticFeedback.mediumImpact();
    setState(() => _hidden.add(item.id));

    RecurringService.delete(item.id).catchError((_) {
      if (mounted) setState(() => _hidden.remove(item.id));
    });

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(loc.recurringDeleted),
          action: SnackBarAction(
            label: loc.undo,
            onPressed: () async {
              await RecurringService.restore(item);
              if (mounted) setState(() => _hidden.remove(item.id));
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    final catState = context.watch<CategoriesCubit>().state;
    final categories = <String, CustomCategory>{
      if (catState is CategoriesLoaded)
        for (final c in catState.categories) c.id: c,
    };
    final accountNames = {
      for (final a in context.watch<AccountCubit>().state.accounts)
        a.id: a.name,
    };

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(title: Text(loc.recurringPayments)),
      body: ValueListenableBuilder<Box<RecurringExpenseModel>>(
        valueListenable:
            Hive.box<RecurringExpenseModel>(RecurringService.boxName)
                .listenable(),
        builder: (context, box, _) {
          final items = [
            for (final r in box.values)
              if (!_hidden.contains(r.id)) r,
          ]..sort((a, b) {
              final byDay = a.dayOfMonth.compareTo(b.dayOfMonth);
              return byDay != 0
                  ? byDay
                  : a.productName
                      .toLowerCase()
                      .compareTo(b.productName.toLowerCase());
            });

          if (items.isEmpty) {
            return _EmptyState(onCreate: () => _openEditor());
          }

          var expenses = 0.0;
          var income = 0.0;
          for (final r in items) {
            if (r.isIncome) {
              income += r.price;
            } else {
              expenses += r.price;
            }
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              _Summary(
                expenses: expenses > 0
                    ? loc.recurringMonthlyExpenses(
                        Money.format(expenses, locale, symbol: symbol),
                      )
                    : null,
                income: income > 0
                    ? loc.recurringMonthlyIncome(
                        Money.format(income, locale, symbol: symbol),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              for (final item in items)
                Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: LuminaColors.errorSoft,
                      borderRadius: LuminaDimensions.borderRadiusLarge,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: LuminaColors.error,
                    ),
                  ),
                  onDismissed: (_) => _delete(item),
                  child: _RecurringCard(
                    item: item,
                    category: categories[item.categoryId],
                    accountName: item.accountId == null
                        ? null
                        : accountNames[item.accountId],
                    symbol: symbol,
                    locale: locale,
                    onTap: () => _openEditor(item: item),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ValueListenableBuilder<Box<RecurringExpenseModel>>(
        valueListenable:
            Hive.box<RecurringExpenseModel>(RecurringService.boxName)
                .listenable(),
        builder: (context, box, _) => box.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                backgroundColor: LuminaColors.primary,
                foregroundColor: Colors.white,
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  loc.addTemplate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.repeat_rounded,
              size: 54,
              color: LuminaColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              loc.noRecurringPayments,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LuminaColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                loc.addTemplate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({this.expenses, this.income});

  final String? expenses;
  final String? income;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuminaColors.cardMint,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        border: Border.all(color: LuminaColors.cardMintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expenses != null)
            Text(
              expenses!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: LuminaColors.accentDeep,
              ),
            ),
          if (income != null)
            Text(
              income!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: LuminaColors.success,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.category,
    required this.accountName,
    required this.symbol,
    required this.locale,
    required this.onTap,
  });

  final RecurringExpenseModel item;
  final CustomCategory? category;
  final String? accountName;
  final String symbol;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final color = item.isIncome ? LuminaColors.success : LuminaColors.error;

    // Локальная переменная: поле нельзя «повысить» до non-null в if.
    final account = accountName;
    final subtitle = [
      category?.localizedName(loc) ?? loc.otherCategory,
      '${loc.day} ${item.dayOfMonth}',
      if (account != null) account,
    ].join(' · ');

    final amount = '${item.isIncome ? '+' : '−'}'
        '${Money.format(item.price, locale, symbol: symbol)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: LuminaDimensions.borderRadiusLarge,
          boxShadow: LuminaTheme.premiumShadow,
        ),
        child: Material(
          color: LuminaColors.surface,
          borderRadius: LuminaDimensions.borderRadiusLarge,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category?.icon ??
                          (item.isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded),
                      color: category?.color ?? color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: LuminaColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LuminaColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: item.isIncome
                          ? LuminaColors.success
                          : LuminaColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ editor

class _RecurringEditor extends StatefulWidget {
  const _RecurringEditor({
    required this.symbol,
    required this.categories,
    this.item,
  });

  final String symbol;
  final List<CustomCategory> categories;
  final RecurringExpenseModel? item;

  @override
  State<_RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends State<_RecurringEditor> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late bool _isIncome;
  late int _day;
  String? _categoryId;
  String? _accountId;
  bool _nameError = false;
  bool _priceError = false;
  bool _categoryError = false;

  bool get _editing => widget.item != null;

  List<CustomCategory> get _visible => [
        for (final c in widget.categories)
          if (c.type ==
              (_isIncome
                  ? CustomCategory.typeIncome
                  : CustomCategory.typeExpense))
            c,
      ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.productName ?? '');
    _price = TextEditingController(
      text: item == null ? '' : Money.forInput(item.price),
    );
    _isIncome = item?.isIncome ?? false;
    _day = item?.dayOfMonth.clamp(1, 31) ?? 1;
    _accountId = item?.accountId;

    final visible = _visible;
    _categoryId = visible.any((c) => c.id == item?.categoryId)
        ? item!.categoryId
        : (visible.isEmpty ? null : visible.first.id);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit(String? accountId) {
    final name = _name.text.trim();
    final price = Money.parse(_price.text);

    setState(() {
      _nameError = name.isEmpty;
      _priceError = price == null || price <= 0;
      _categoryError = _categoryId == null;
    });
    if (_nameError || _priceError || _categoryError) {
      HapticFeedback.heavyImpact();
      return;
    }

    Navigator.of(context).pop<_RecurringInput>((
      name: name,
      price: price!,
      categoryId: _categoryId!,
      isIncome: _isIncome,
      day: _day,
      accountId: accountId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accounts = context.watch<AccountCubit>().state.accounts;
    final accountId = ReceiptAccountPicker.resolve(accounts, _accountId);
    final categories = _visible;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editing ? loc.editRecurring : loc.addTemplate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(loc.expense)),
                ButtonSegment(value: true, label: Text(loc.incomeType)),
              ],
              selected: {_isIncome},
              onSelectionChanged: (selection) {
                HapticFeedback.selectionClick();
                setState(() {
                  _isIncome = selection.first;
                  final next = _visible;
                  _categoryId = next.isEmpty ? null : next.first.id;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_nameError) setState(() => _nameError = false);
            },
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
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
            onChanged: (_) {
              if (_priceError) setState(() => _priceError = false);
            },
            decoration: InputDecoration(
              labelText: loc.goalsDepositAmount(widget.symbol),
              errorText: _priceError ? loc.amountRequired : null,
            ),
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ReceiptAccountPicker(
              accounts: accounts,
              value: accountId,
              onChanged: (id) => setState(() => _accountId = id),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            loc.chooseCategory,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: LuminaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (categories.isEmpty)
            Text(
              loc.noExpenseCategories,
              style: const TextStyle(color: LuminaColors.error),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categories)
                  ChoiceChip(
                    selected: cat.id == _categoryId,
                    label: Text(cat.localizedName(loc)),
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: cat.id == _categoryId ? Colors.white : cat.color,
                    ),
                    showCheckmark: false,
                    selectedColor: LuminaColors.primary,
                    labelStyle: TextStyle(
                      color: cat.id == _categoryId
                          ? Colors.white
                          : LuminaColors.textMain,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _categoryId = cat.id;
                        _categoryError = false;
                      });
                    },
                  ),
              ],
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _day,
            isExpanded: true,
            menuMaxHeight: 320,
            decoration: InputDecoration(labelText: loc.day),
            items: [
              for (var d = 1; d <= 31; d++)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _day = value);
            },
          ),
          if (_day > 28)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                loc.recurringShortMonthNote,
                style: const TextStyle(
                  fontSize: 12,
                  color: LuminaColors.textSecondary,
                ),
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
                  onPressed: () => _submit(accountId),
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
