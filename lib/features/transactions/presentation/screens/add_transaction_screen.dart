import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_state.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/categories/presentation/widgets/category_selector.dart';
import 'package:lumina/features/receipts/presentation/screens/confirm_receipt_screen.dart';
import 'package:lumina/features/receipts/presentation/widgets/scan_receipt_sheet.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/widgets/quick_add/air_keyboard.dart';
import 'package:lumina/features/transactions/presentation/widgets/quick_add/amount_display.dart';
import 'package:lumina/features/transactions/presentation/widgets/quick_add/note_input_field.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialName,
    this.initialPrice,
    this.editingId,
  });

  final String? initialName;
  final double? initialPrice;

  /// Если задан и запись найдена, экран работает в режиме редактирования.
  final String? editingId;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late final TextEditingController _noteController;

  String _amount = '0';
  CustomCategory? _selectedCategory;
  String? _pendingCategoryId;
  String? _selectedAccountId;
  String? _selectedTargetAccountId;
  HistoryExpense? _editing;
  DateTime _selectedDate = DateTime.now();
  bool _didInitialize = false;
  bool _isSubmitting = false;

  int _selectedSegment = 0;

  bool get _isEditing => _editing != null;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;

    final id = widget.editingId;
    if (id != null) {
      _editing = context
          .read<HistoryCubit>()
          .state
          .allRecords
          .where((r) => r.id == id)
          .firstOrNull;
    }

    final editing = _editing;
    if (editing != null) {
      _amount = _formatAmount(editing.price);
      _noteController.text = editing.productName;
      _selectedDate = editing.date;
      _selectedAccountId = editing.accountId;
      _selectedTargetAccountId = editing.targetAccountId;
      _pendingCategoryId = editing.category;
    } else {
      _amount = _formatAmount(widget.initialPrice ?? 0);
      _noteController.text = widget.initialName ?? '';
    }

    _ensureAccounts(context.read<AccountCubit>().state);
    _resolveCategory(context.read<CategoriesCubit>().state);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatAmount(double price) {
    if (price <= 0) return '0';
    if (price == price.roundToDouble()) return price.toStringAsFixed(0);
    return price.toStringAsFixed(2);
  }

  void _ensureAccounts(AccountState state) {
    final accounts = state.accounts;
    if (accounts.isEmpty) return;

    bool exists(String? id) => id != null && accounts.any((a) => a.id == id);

    if (!exists(_selectedAccountId)) {
      _selectedAccountId = accounts.first.id;
    }
    _fixTarget(accounts);
  }

  void _fixTarget(List<AccountModel> accounts) {
    final isTransfer = _selectedCategory?.type == 'transfer';
    if (!isTransfer && _selectedTargetAccountId == null) return;

    final valid = _selectedTargetAccountId != null &&
        _selectedTargetAccountId != _selectedAccountId &&
        accounts.any((a) => a.id == _selectedTargetAccountId);
    if (valid) return;

    final other = accounts.where((a) => a.id != _selectedAccountId);
    _selectedTargetAccountId = other.isEmpty ? null : other.first.id;
  }

  void _resolveCategory(CategoriesState state) {
    final pending = _pendingCategoryId;
    if (pending == null || state is! CategoriesLoaded) return;

    final found = state.categories.where((c) => c.id == pending).firstOrNull;
    if (found == null) return;

    _selectedCategory = found;
    _pendingCategoryId = null;

    final loc = AppLocalizations.of(context);
    if (loc != null && _noteController.text == found.localizedName(loc)) {
      _noteController.clear();
    }
  }

  void _onKeyPress(String value) {
    setState(() {
      if (value == 'C') {
        _amount = '0';
        return;
      }
      if (value == '⌫') {
        _amount =
            _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
        return;
      }
      if (value == '.') {
        if (!_amount.contains('.')) _amount += '.';
        return;
      }
      if (_amount == '0') {
        _amount = value;
        return;
      }
      final parts = _amount.split('.');
      if (parts.length == 2 && parts[1].length >= 2) return;
      if (_amount.replaceAll('.', '').length >= 9) return;
      _amount += value;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _withTime(DateTime day) {
    final original = _editing?.date;
    if (original != null && _isSameDay(day, original)) return original;
    final now = DateTime.now();
    if (_isSameDay(day, now)) return now;
    return DateTime(day.year, day.month, day.day);
  }

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: LuminaColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LuminaDimensions.radiusLarge),
        ),
      ),
      builder: (_) => _DatePickerSheet(initial: _selectedDate),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = _withTime(picked));
  }

  Future<void> _scanReceipt() async {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final receipt = await ScanReceiptSheet.pick(context);
    if (!mounted || receipt == null) return;

    if (receipt.amount <= 0 && receipt.lines.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(loc.scanNothingFound)));
      return;
    }

    final saved = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => ConfirmReceiptScreen(receipt: receipt),
        fullscreenDialog: true,
      ),
    );
    if (saved == true && mounted) context.pop();
  }

  Future<void> _save() async {
    final category = _selectedCategory;
    final accountId = _selectedAccountId;
    if (_isSubmitting || category == null || accountId == null) return;

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<HistoryCubit>();

    final amount = double.tryParse(_amount) ?? 0;
    if (amount <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(loc.amountRequired)));
      return;
    }

    final isTransfer = category.type == 'transfer';
    if (isTransfer &&
        (_selectedTargetAccountId == null ||
            _selectedTargetAccountId == accountId)) {
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final note = _noteController.text.trim();
    final entity = HistoryExpense(
      id: _editing?.id ?? const Uuid().v4(),
      date: _selectedDate,
      productName: note.isNotEmpty ? note : category.localizedName(loc),
      price: amount,
      category: category.id,
      type: category.type,
      isSynced: false,
      accountId: accountId,
      targetAccountId: isTransfer ? _selectedTargetAccountId : null,
    );

    try {
      if (_isEditing) {
        await cubit.updateRecord(entity);
      } else {
        await cubit.addRecord(entity);
      }
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateString = DateFormat('d MMMM y', locale).format(_selectedDate);

    final isLoading = context.select(
      (HistoryCubit cubit) => cubit.state.isLoading,
    );
    final accounts = context.watch<AccountCubit>().state.accounts;

    final parsedAmount = double.tryParse(_amount) ?? 0;
    final isTransfer = _selectedCategory?.type == 'transfer';
    final validAccounts = _selectedAccountId != null &&
        (!isTransfer ||
            (_selectedTargetAccountId != null &&
                _selectedTargetAccountId != _selectedAccountId));

    final canSave = !_isSubmitting &&
        !isLoading &&
        _selectedCategory != null &&
        parsedAmount > 0 &&
        validAccounts;

    return MultiBlocListener(
      listeners: [
        BlocListener<AccountCubit, AccountState>(
          listener: (_, state) => setState(() => _ensureAccounts(state)),
        ),
        BlocListener<CategoriesCubit, CategoriesState>(
          listener: (_, state) => setState(() => _resolveCategory(state)),
        ),
      ],
      child: Scaffold(
        backgroundColor: LuminaColors.background,
        appBar: AppBar(
          backgroundColor: LuminaColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: _isEditing ? Text(loc.change) : null,
          leading: Center(
            child: Semantics(
              button: true,
              label: loc.cancel,
              child: Material(
                color: LuminaColors.surface,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: LuminaColors.textMain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            if (!_isEditing)
              IconButton(
                tooltip: loc.scanReceipt,
                onPressed: _isSubmitting ? null : _scanReceipt,
                icon: const Icon(
                  Icons.document_scanner_rounded,
                  color: LuminaColors.primary,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: canSave ? _save : null,
                style: TextButton.styleFrom(
                  foregroundColor: canSave
                      ? LuminaColors.primary
                      : LuminaColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: canSave
                      ? LuminaColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: isLoading || _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LuminaColors.primary,
                        ),
                      )
                    : Text(
                        _isEditing ? loc.save : loc.done,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              AmountDisplay(amount: _amount),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: LuminaColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSegment = 0);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedSegment == 0
                                  ? LuminaColors.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedSegment == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Категории',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedSegment == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedSegment == 0
                                    ? LuminaColors.primary
                                    : LuminaColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSegment = 1);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedSegment == 1
                                  ? LuminaColors.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedSegment == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Детали',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedSegment == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedSegment == 1
                                    ? LuminaColors.primary
                                    : LuminaColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedSegment == 0
                      ? Center(
                          key: const ValueKey(0),
                          child: CategorySelector(
                            selectedCategory: _selectedCategory,
                            onSelected: (cat) => setState(() {
                              _selectedCategory = cat;
                              _pendingCategoryId = null;
                              _fixTarget(accounts);
                            }),
                          ),
                        )
                      : SingleChildScrollView(
                          key: const ValueKey(1),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              if (accounts.isEmpty)
                                _NoAccountsHint(
                                    onCreate: () => context.push('/accounts'))
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: _AccountDropdown(
                                        hint: loc.accountLabel,
                                        value: _selectedAccountId,
                                        accounts: accounts,
                                        onChanged: (id) => setState(() {
                                          _selectedAccountId = id;
                                          _fixTarget(accounts);
                                        }),
                                      ),
                                    ),
                                    if (isTransfer) ...[
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                          color: LuminaColors.textSecondary,
                                        ),
                                      ),
                                      Expanded(
                                        child: _AccountDropdown(
                                          hint: loc.targetAccountLabel,
                                          value: _selectedTargetAccountId,
                                          accounts: accounts
                                              .where((a) =>
                                                  a.id != _selectedAccountId)
                                              .toList(),
                                          onChanged: (id) => setState(() =>
                                              _selectedTargetAccountId = id),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Material(
                                color: LuminaColors.surface,
                                borderRadius:
                                    LuminaDimensions.borderRadiusMedium,
                                elevation: 0.5,
                                child: InkWell(
                                  onTap: _pickDate,
                                  borderRadius:
                                      LuminaDimensions.borderRadiusMedium,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: LuminaDimensions.paddingM,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 18,
                                              color: LuminaColors.primary,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              loc.transactionDate,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    LuminaColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: LuminaColors.inputFill,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            dateString,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: LuminaColors.textMain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              NoteInputField(controller: _noteController),
                            ],
                          ),
                        ),
                ),
              ),
              AirKeyboard(onKeyPress: _onKeyPress),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ sub-widgets

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.hint,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = accounts.any((a) => a.id == value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        border: Border.all(color: LuminaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          hint: Text(hint),
          borderRadius: LuminaDimensions.borderRadiusMedium,
          items: [
            for (final acc in accounts)
              DropdownMenuItem<String>(
                value: acc.id,
                child: Text(
                  acc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: LuminaColors.textMain,
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NoAccountsHint extends StatelessWidget {
  const _NoAccountsHint({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: LuminaColors.errorSoft,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        child: InkWell(
          onTap: onCreate,
          borderRadius: LuminaDimensions.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: LuminaColors.errorDeep,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.createAccountFirst,
                    style: const TextStyle(
                      color: LuminaColors.errorDeep,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: LuminaColors.errorDeep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ ИСПРАВЛЕННЫЙ КАЛЕНДАРЬ

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({required this.initial});

  final DateTime initial;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  static const _dayExtent = 58.0;

  late DateTime _selectedDate;
  late DateTime _viewMonth;
  late final ScrollController _daysScrollController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initial;
    _viewMonth = DateTime(widget.initial.year, widget.initial.month);
    _daysScrollController = ScrollController(
      initialScrollOffset: (_selectedDate.day - 1) * _dayExtent,
    );
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _shiftMonth(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
      final daysInNewMonth =
          DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);
      final newDay = _selectedDate.day.clamp(1, daysInNewMonth).toInt();
      _selectedDate = DateTime(_viewMonth.year, _viewMonth.month, newDay);
    });
    _scrollToDay(_selectedDate.day);
  }

  void _scrollToDay(int day) {
    if (_daysScrollController.hasClients) {
      final targetOffset = (day - 1) * _dayExtent;
      _daysScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _selectQuickDate(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = date;
      _viewMonth = DateTime(date.year, date.month);
    });
    _scrollToDay(date.day);
  }

  String _weekday(AppLocalizations loc, int weekday) => switch (weekday) {
        1 => loc.mon,
        2 => loc.tue,
        3 => loc.wed,
        4 => loc.thu,
        5 => loc.fri,
        6 => loc.sat,
        7 => loc.sun,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final daysInMonth =
        DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);

    final rawLabel = DateFormat('LLLL y', locale).format(_viewMonth);
    final monthLabel = rawLabel.isEmpty
        ? rawLabel
        : '${rawLabel[0].toUpperCase()}${rawLabel.substring(1)}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LuminaDimensions.paddingL,
          LuminaDimensions.paddingM,
          LuminaDimensions.paddingL,
          MediaQuery.viewInsetsOf(context).bottom + LuminaDimensions.paddingL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.transactionDate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                  ),
                ),
                IconButton(
                  tooltip: loc.cancel,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: LuminaColors.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: LuminaDimensions.paddingM),
            Row(
              children: [
                Expanded(
                  child: _QuickDateChip(
                    label: loc.today,
                    selected: _sameDay(_selectedDate, now),
                    onTap: () => _selectQuickDate(now),
                  ),
                ),
                const SizedBox(width: LuminaDimensions.paddingS + 4),
                Expanded(
                  child: _QuickDateChip(
                    label: loc.yesterday,
                    selected: _sameDay(_selectedDate, yesterday),
                    onTap: () => _selectQuickDate(yesterday),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: LuminaColors.textSecondary,
                      ),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: LuminaColors.textSecondary,
                      ),
                      onPressed: () => _shiftMonth(1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: LuminaDimensions.paddingS),
            SizedBox(
              height: 65,
              child: ListView.builder(
                controller: _daysScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final dayDate =
                      DateTime(_viewMonth.year, _viewMonth.month, day);
                  final isSelected = _sameDay(dayDate, _selectedDate);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: isSelected
                          ? LuminaColors.primary
                          : LuminaColors.background,
                      clipBehavior: Clip.antiAlias,
                      // Исправлено: передаем shape с borderRadius вместо прямого borderRadius
                      shape: RoundedRectangleBorder(
                        borderRadius: LuminaDimensions.borderRadiusMedium,
                        side: BorderSide(
                          color: isSelected
                              ? LuminaColors.primary
                              : LuminaColors.border,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedDate = dayDate;
                          });
                        },
                        child: SizedBox(
                          width: 50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weekday(loc, dayDate.weekday),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white70
                                      : LuminaColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : LuminaColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: LuminaDimensions.paddingXL),
            SizedBox(
              width: double.infinity,
              height: LuminaDimensions.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop(_selectedDate);
                },
                child: Text(
                  loc.confirm,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LuminaColors.primary : LuminaColors.inputFill,
      borderRadius: LuminaDimensions.borderRadiusMedium,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : LuminaColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
