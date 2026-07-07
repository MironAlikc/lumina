import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/localization/lumina_localizations.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/add_app_bar.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/air_keyboard.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/amount_display.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/category_selector.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/note_input_field.dart';

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
  bool _didInitialize = false; // Флаг для однократной инициализации

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Инициализируем один раз, чтобы не сбрасывать состояние при ребилдах
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

  void _saveTransaction(bool isLoading) {
    if (isLoading || _selectedCategory == null) return;

    final double parsedAmount = double.tryParse(_amount) ?? 0.0;
    if (parsedAmount <= 0) return;

    HapticFeedback.mediumImpact();

    final loc = LuminaLocalizations.of(context);
    final categoryName = _selectedCategory!.name;
    final TransactionType transactionType = _selectedCategory!.type == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    final newRecord = HistoryExpenseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      productName: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : (loc.translate(categoryName)),
      price: parsedAmount,
      category: categoryName,
      type: transactionType,
      isSynced: false,
    );

    context.read<HistoryCubit>().addRecord(newRecord);
    context.pop(); // Используем GoRouter для выхода
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final canSave =
            _selectedCategory != null && (double.tryParse(_amount) ?? 0) > 0;

        return Scaffold(
          backgroundColor: const Color(0xFFEEF2F6),
          appBar: AddAppBar(
            isLoading: state.isLoading,
            onDone: () => _saveTransaction(state.isLoading),
            canSave: canSave,
          ),
          body: SafeArea(
            child: Column(
              children: [
                AmountDisplay(amount: _amount),
                NoteInputField(controller: _noteController),
                CategorySelector(
                  selectedCategory: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
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
