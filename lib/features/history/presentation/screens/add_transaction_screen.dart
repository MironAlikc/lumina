import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/domain/entities/history_expense.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/air_keyboard.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/amount_display.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/category_selector.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/note_input_field.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialName;
  final double? initialPrice;

  const AddTransactionScreen({super.key, this.initialName, this.initialPrice});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amount = '0';
  CustomCategory? _selectedCategory;
  late final TextEditingController _noteController;
  bool _didInitialize = false;
  bool _isSubmitting = false;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didInitialize) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

      final name = extra?['name'] ?? widget.initialName ?? '';
      final price = (extra?['price'] ?? widget.initialPrice ?? 0.0).toDouble();

      _amount = price > 0 ? price.toStringAsFixed(0) : '0';
      _noteController.text = name;
      _didInitialize = true;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String value) {
    setState(() {
      if (value == 'C') {
        _amount = '0';
      } else if (value == '⌫') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
      } else if (value == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        _amount = (_amount == '0')
            ? value
            : (_amount.length < 9 ? _amount + value : _amount);
      }
    });
  }

  String _getMonthName(AppLocalizations loc, int month) {
    switch (month) {
      case 1:
        return loc.january;
      case 2:
        return loc.february;
      case 3:
        return loc.march;
      case 4:
        return loc.april;
      case 5:
        return loc.may;
      case 6:
        return loc.june;
      case 7:
        return loc.july;
      case 8:
        return loc.august;
      case 9:
        return loc.september;
      case 10:
        return loc.october;
      case 11:
        return loc.november;
      case 12:
        return loc.december;
      default:
        return '';
    }
  }

  String _getWeekdayName(AppLocalizations loc, int weekday) {
    switch (weekday) {
      case 1:
        return loc.mon;
      case 2:
        return loc.tue;
      case 3:
        return loc.wed;
      case 4:
        return loc.thu;
      case 5:
        return loc.fri;
      case 6:
        return loc.sat;
      case 7:
        return loc.sun;
      default:
        return '';
    }
  }

  void _showModernDatePicker() {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: LuminaColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LuminaDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        DateTime tempDate = _selectedDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysInMonth = DateUtils.getDaysInMonth(
              tempDate.year,
              tempDate.month,
            );

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LuminaDimensions.paddingL,
                  LuminaDimensions.paddingM,
                  LuminaDimensions.paddingL,
                  MediaQuery.of(context).viewInsets.bottom +
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
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: LuminaDimensions.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(
                                () => tempDate = DateTime.now(),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _isSameDay(tempDate, DateTime.now())
                                      ? LuminaColors.primary
                                      : LuminaColors.inputFill,
                                  borderRadius:
                                      LuminaDimensions.borderRadiusMedium,
                                ),
                                child: Text(
                                  loc.today,
                                  style: TextStyle(
                                    color: _isSameDay(tempDate, DateTime.now())
                                        ? Colors.white
                                        : LuminaColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: LuminaDimensions.paddingS + 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(
                                () => tempDate = DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      _isSameDay(
                                        tempDate,
                                        DateTime.now().subtract(
                                          const Duration(days: 1),
                                        ),
                                      )
                                      ? LuminaColors.primary
                                      : LuminaColors.inputFill,
                                  borderRadius:
                                      LuminaDimensions.borderRadiusMedium,
                                ),
                                child: Text(
                                  loc.yesterday,
                                  style: TextStyle(
                                    color:
                                        _isSameDay(
                                          tempDate,
                                          DateTime.now().subtract(
                                            const Duration(days: 1),
                                          ),
                                        )
                                        ? Colors.white
                                        : LuminaColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
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
                            '${_getMonthName(loc, tempDate.month)} ${tempDate.year}',
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
                                onPressed: () => setModalState(
                                  () => tempDate = DateTime(
                                    tempDate.year,
                                    tempDate.month - 1,
                                    1,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: LuminaColors.textSecondary,
                                ),
                                onPressed: () => setModalState(
                                  () => tempDate = DateTime(
                                    tempDate.year,
                                    tempDate.month + 1,
                                    1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: LuminaDimensions.paddingS),
                      SizedBox(
                        height: 65,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: daysInMonth,
                          itemBuilder: (context, index) {
                            final dayNumber = index + 1;
                            final currentLoopDate = DateTime(
                              tempDate.year,
                              tempDate.month,
                              dayNumber,
                            );
                            final isSelected =
                                currentLoopDate.day == tempDate.day &&
                                currentLoopDate.month == tempDate.month &&
                                currentLoopDate.year == tempDate.year;

                            final weekdayStr = _getWeekdayName(
                              loc,
                              currentLoopDate.weekday,
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
                                      weekdayStr,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LuminaColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: LuminaDimensions.borderRadiusMedium,
                            ),
                          ),
                          onPressed: () {
                            setState(() => _selectedDate = tempDate);
                            Navigator.pop(context);
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _saveTransaction(bool isStateLoading) {
    if (_isSubmitting || isStateLoading || _selectedCategory == null) return;

    final double parsedAmount = double.tryParse(_amount) ?? 0.0;
    if (parsedAmount <= 0) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final newExpenseEntity = HistoryExpense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      productName: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : _selectedCategory!.name,
      price: parsedAmount,
      category: _selectedCategory!.id,
      type: _selectedCategory!.type,
      isSynced: false,
    );

    context.read<HistoryCubit>().addRecord(newExpenseEntity);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final dateString =
        '${_selectedDate.day} ${_getMonthName(loc, _selectedDate.month)} ${_selectedDate.year}';

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final canSave =
            !_isSubmitting &&
            _selectedCategory != null &&
            (double.tryParse(_amount) ?? 0) > 0;

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
                  onPressed: canSave && !(state.isLoading || _isSubmitting)
                      ? () => _saveTransaction(state.isLoading)
                      : null,
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
                  child: state.isLoading || _isSubmitting
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
                      onSelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),
                AirKeyboard(onKeyPress: _onKeyPress),
              ],
            ),
          ),
        );
      },
    );
  }
}
