import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/features/history/domain/entities/history_expense.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:uuid/uuid.dart';

class QuickAddView extends StatefulWidget {
  const QuickAddView({super.key});

  @override
  State<QuickAddView> createState() => _QuickAddViewState();
}

class _QuickAddViewState extends State<QuickAddView> {
  bool _isIncome = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (_priceController.text.isEmpty ||
        _nameController.text.isEmpty ||
        price == null ||
        _selectedCategoryId == null) {
      return;
    }

    final String type = _isIncome ? 'income' : 'expense';

    final newRecord = HistoryExpense(
      id: const Uuid().v4(),
      date: DateTime.now(),
      productName: _nameController.text.trim(),
      price: price,
      category: _selectedCategoryId!,
      type: type,
      isSynced: false,
    );

    context.read<HistoryCubit>().addRecord(newRecord);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab(
                  label: 'Расход',
                  isSelected: !_isIncome,
                  activeColor: const Color(0xFFEF4444),
                  onTap: () => setState(() => _isIncome = false),
                ),
                _buildTab(
                  label: 'Доход',
                  isSelected: _isIncome,
                  activeColor: const Color(0xFF10B981),
                  onTap: () => setState(() => _isIncome = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoaded) {
                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  hint: const Text('Выберите категорию'),
                  items: state.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Сумма',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
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
