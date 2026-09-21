import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/domain/entities/history_expense.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/air_keyboard.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/amount_display.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/category_selector.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/note_input_field.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.initialName, this.initialPrice});

  final String? initialName;
  final double? initialPrice;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amount = '0';
  CustomCategory? _selectedCategory;
  late final TextEditingController _noteController;
  var _didInitialize = false;
  var _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;

    final extra = GoRouterState.of(context).extra;
    final map = extra is Map<String, dynamic> ? extra : null;
    final name = (map?['name'] ?? widget.initialName ?? '') as String;
    final rawPrice = map?['price'] ?? widget.initialPrice ?? 0;
    final price = rawPrice is num ? rawPrice.toDouble() : 0.0;

    _amount = _formatInitialAmount(price);
    _noteController.text = name;
    _didInitialize = true;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatInitialAmount(double price) {
    if (price <= 0) return '0';
    if (price == price.roundToDouble()) return price.toStringAsFixed(0);
    return price.toStringAsFixed(2);
  }

  void _onKeyPress(String value) {
    setState(() {
      if (value == 'C') {
        _amount = '0';
        return;
      }
      if (value == '⌫') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
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

  String _weekdayName(AppLocalizations loc, int weekday) {
    return switch (weekday) {
      1 => loc.mon,
      2 => loc.tue,
      3 => loc.wed,
      4 => loc.thu,
      5 => loc.fri,
      6 => loc.sat,
      7 => loc.sun,
      _ => '',
    };
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _withCurrentTime(DateTime day) {
    final now = DateTime.now();
    if (_isSameDay(day, now)) return now;
    return DateTime(day.year, day.month, day.day);
  }

  void _showModernDatePicker() {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LuminaColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LuminaDimensions.radiusLarge),
        ),
      ),
      builder: (sheetContext) {
        var tempDate = _selectedDate;
        final daysController = ScrollController(
          initialScrollOffset: ((_selectedDate.day - 1) * 58.0),
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysInMonth = DateUtils.getDaysInMonth(
              tempDate.year,
              tempDate.month,
            );
            final now = DateTime.now();
            final yesterday = now.subtract(const Duration(days: 1));
            final monthLabel = DateFormat('LLLL y', locale).format(tempDate);
            final capitalizedMonth =
                monthLabel[0].toUpperCase() + monthLabel.substring(1);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LuminaDimensions.paddingL,
                  LuminaDimensions.paddingM,
                  LuminaDimensions.paddingL,
                  MediaQuery.viewInsetsOf(context).bottom +
                      LuminaDimensions.paddingL,
                ),
                child: SingleChildScrollView(
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
                            icon: const Icon(
                              Icons.close_rounded,
                              color: LuminaColors.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: LuminaDimensions.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickDateChip(
                              label: loc.today,
                              selected: _isSameDay(tempDate, now),
                              onTap: () => setModalState(() => tempDate = now),
                            ),
                          ),
                          const SizedBox(width: LuminaDimensions.paddingS + 4),
                          Expanded(
                            child: _QuickDateChip(
                              label: loc.yesterday,
                              selected: _isSameDay(tempDate, yesterday),
                              onTap: () => setModalState(
                                () => tempDate = DateTime(
                                  yesterday.year,
                                  yesterday.month,
                                  yesterday.day,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            capitalizedMonth,
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
                                onPressed: () => setModalState(() {
                                  final targetMonth = DateTime(
                                    tempDate.year,
                                    tempDate.month - 1,
                                  );
                                  final last = DateUtils.getDaysInMonth(
                                    targetMonth.year,
                                    targetMonth.month,
                                  );
                                  tempDate = DateTime(
                                    targetMonth.year,
                                    targetMonth.month,
                                    tempDate.day.clamp(1, last),
                                  );
                                }),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: LuminaColors.textSecondary,
                                ),
                                onPressed: () => setModalState(() {
                                  final targetMonth = DateTime(
                                    tempDate.year,
                                    tempDate.month + 1,
                                  );
                                  final last = DateUtils.getDaysInMonth(
                                    targetMonth.year,
                                    targetMonth.month,
                                  );
                                  tempDate = DateTime(
                                    targetMonth.year,
                                    targetMonth.month,
                                    tempDate.day.clamp(1, last),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: LuminaDimensions.paddingS),
                      SizedBox(
                        height: 65,
                        child: ListView.builder(
                          controller: daysController,
                          scrollDirection: Axis.horizontal,
                          itemCount: daysInMonth,
                          itemBuilder: (context, index) {
                            final dayNumber = index + 1;
                            final currentLoopDate = DateTime(
                              tempDate.year,
                              tempDate.month,
                              dayNumber,
                            );
                            final isSelected = _isSameDay(
                              currentLoopDate,
                              tempDate,
                            );

                            return GestureDetector(
                              onTap: () => setModalState(
                                () => tempDate = currentLoopDate,
                              ),
                              child: Container(
                                width: 50,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? LuminaColors.primary
                                      : LuminaColors.background,
                                  borderRadius:
                                      LuminaDimensions.borderRadiusMedium,
                                  border: Border.all(
                                    color: isSelected
                                        ? LuminaColors.primary
                                        : LuminaColors.border,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _weekdayName(
                                        loc,
                                        currentLoopDate.weekday,
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white70
                                            : LuminaColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$dayNumber',
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
                            setState(
                              () => _selectedDate = _withCurrentTime(tempDate),
                            );
                            Navigator.pop(sheetContext);
                          },
                          child: Text(
                            loc.confirm,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveTransaction() async {
    if (_isSubmitting || _selectedCategory == null) return;

    final parsedAmount = double.tryParse(_amount) ?? 0;
    if (parsedAmount <= 0) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.amountRequired)));
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final loc = AppLocalizations.of(context)!;
    final note = _noteController.text.trim();
    final entity = HistoryExpense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      productName: note.isNotEmpty
          ? note
          : _selectedCategory!.localizedName(loc),
      price: parsedAmount,
      category: _selectedCategory!.id,
      type: _selectedCategory!.type,
      isSynced: false,
    );

    try {
      await context.read<HistoryCubit>().addRecord(entity);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
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
    final parsedAmount = double.tryParse(_amount) ?? 0;
    final canSave =
        !_isSubmitting &&
        !isLoading &&
        _selectedCategory != null &&
        parsedAmount > 0;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        backgroundColor: LuminaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: LuminaColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: LuminaColors.textMain,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: canSave ? _saveTransaction : null,
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
                      loc.done,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: canSave
                            ? LuminaColors.primary
                            : LuminaColors.textSecondary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountDisplay(amount: _amount),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: LuminaDimensions.paddingL,
                vertical: 2,
              ),
              child: InkWell(
                onTap: _showModernDatePicker,
                borderRadius: LuminaDimensions.borderRadiusMedium,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LuminaDimensions.paddingM,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: LuminaColors.surface,
                    borderRadius: LuminaDimensions.borderRadiusMedium,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              color: LuminaColors.textSecondary,
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
                          borderRadius: BorderRadius.circular(10),
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
            NoteInputField(controller: _noteController),
            Expanded(
              child: Center(
                child: CategorySelector(
                  selectedCategory: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),
            ),
            AirKeyboard(onKeyPress: _onKeyPress),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? LuminaColors.primary : LuminaColors.inputFill,
          borderRadius: LuminaDimensions.borderRadiusMedium,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : LuminaColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
