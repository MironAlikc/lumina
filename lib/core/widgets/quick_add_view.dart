import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:uuid/uuid.dart'; // Добавь пакет uuid в pubspec.yaml

class QuickAddView extends StatefulWidget {
  const QuickAddView({super.key});

  @override
  State<QuickAddView> createState() => _QuickAddViewState();
}

class _QuickAddViewState extends State<QuickAddView> {
  bool _isIncome = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = 'food';

  void _submit() {
    if (_priceController.text.isEmpty || _nameController.text.isEmpty) return;

    final newRecord = HistoryExpenseModel(
      id: const Uuid().v4(),
      date: DateTime.now(),
      productName: _nameController.text,
      price: double.parse(_priceController.text),
      category: _selectedCategory,
      type: _isIncome ? 'income' : 'expense',
      isSynced: false,
    );

    context.read<HistoryCubit>().addRecord(newRecord);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Переключатель Доход/Расход
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab(
                  'Расход',
                  !_isIncome,
                  const Color(0xFFEF4444),
                  () => setState(() => _isIncome = false),
                ),
                _buildTab(
                  'Доход',
                  _isIncome,
                  const Color(0xFF10B981),
                  () => setState(() => _isIncome = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Сумма'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _submit, child: const Text('Сохранить')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTab(
    String label,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
