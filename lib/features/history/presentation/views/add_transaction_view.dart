import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/lumina_theme.dart';
import '../../../../core/localization/lumina_localizations.dart';
import '../../data/models/history_expense_model.dart';
import '../../data/models/custom_category_model.dart';
import '../cubits/history_cubit.dart';
import '../cubits/history_state.dart';
import '../cubits/categories_cubit.dart';
import 'create_category_view.dart';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({Key? key}) : super(key: key);

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  String _amount = '0';
  CustomCategory? _selectedCategory;
  final TextEditingController _noteController = TextEditingController();

  void _onKeyPress(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == 'C') {
        _amount = '0';
      } else if (value == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          if (_amount.length < 9) _amount += value;
        }
      }
    });
  }

  void _saveTransaction(bool isLoading) {
    if (isLoading) return;

    final double parsedAmount = double.tryParse(_amount) ?? 0.0;
    if (parsedAmount <= 0 || _selectedCategory == null) return;

    HapticFeedback.mediumImpact();
    final loc = LuminaLocalizations.of(context);

    final newRecord = HistoryExpenseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      productName: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : (loc.translate(_selectedCategory!.name) ?? _selectedCategory!.name),
      price: parsedAmount,
      category: _selectedCategory!.name,
      type: _selectedCategory!.type,
      isSynced: false,
    );

    context.read<HistoryCubit>().addRecord(newRecord);
    Navigator.pop(context);
  }

  void _showDeleteConfirmation(BuildContext context, CustomCategory category) {
    if (category.id.startsWith('default_')) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Системные категории нельзя удалить'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Удалить категорию?'),
        content: Text(
          'Вы действительно хотите удалить категорию "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.black45),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<CategoriesCubit>().deleteCategory(category.id);
              if (_selectedCategory?.id == category.id) {
                setState(() => _selectedCategory = null);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Удалить',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LuminaLocalizations.of(context);

    // ИСПРАВЛЕНО: Более плотный серый цвет для идеального контраста белых карточек
    const Color premiumBgColor = Color(0xFFEEF2F6);

    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, historyState) {
        final bool isLoading = historyState.isLoading;

        return Scaffold(
          backgroundColor: premiumBgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: LuminaTheme.textColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                LuminaTheme.accentColor,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: () => _saveTransaction(isLoading),
                            child: Text(
                              loc.translate('done') ?? 'Готово',
                              style: TextStyle(
                                color:
                                    _selectedCategory == null ||
                                        double.tryParse(_amount) == 0
                                    ? Colors.black26
                                    : LuminaTheme.accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ДИСПЛЕЙ СУММЫ
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _amount,
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: LuminaTheme.textColor,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '₴',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ПОЛЕ ПРИМЕЧАНИЯ
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 1,
                      cursorColor: LuminaTheme.accentColor,
                      enableSuggestions: false,
                      autocorrect: false,
                      style: const TextStyle(
                        fontSize: 16,
                        color: LuminaTheme.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            loc.translate('noteHint') ?? 'Добавить нотатку...',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // ДИНАМИЧЕСКИЙ БЛОК ВЫБОРА КАТЕГОРИЙ
                Container(
                  height: 110,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, state) {
                      if (state is CategoriesLoading) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }

                      List<CustomCategory> categories = [];
                      if (state is CategoriesLoaded) {
                        categories = state.categories;
                      }

                      if (_selectedCategory == null && categories.isNotEmpty) {
                        _selectedCategory = categories.first;
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ), // Синхронизировано с клавиатурой
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          // КНОПКА ДОБАВЛЕНИЯ КАТЕГОРИИ
                          if (index == categories.length) {
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (modalContext) =>
                                        BlocProvider.value(
                                          value: context
                                              .read<CategoriesCubit>(),
                                          child: const CreateCategoryView(),
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 88,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF64748B),
                                      size: 26,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Создать',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final category = categories[index];
                          final isSelected =
                              _selectedCategory?.id == category.id;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedCategory = category);
                            },
                            onLongPress: () =>
                                _showDeleteConfirmation(context, category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              width: 88,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? category.color
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? category.color.withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.05),
                                    blurRadius: isSelected ? 16 : 10,
                                    offset: isSelected
                                        ? const Offset(0, 8)
                                        : const Offset(0, 4),
                                  ),
                                  if (!isSelected)
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(-2, -2),
                                    ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      category.icon,
                                      color: isSelected
                                          ? Colors.white
                                          : category.color,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      loc.translate(category.name) ??
                                          category.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // ПАРЯЩАЯ ВОЗДУШНАЯ КЛАВИАТУРА
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    top: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildKeyboardRow(['1', '2', '3']),
                        const SizedBox(height: 14),
                        _buildKeyboardRow(['4', '5', '6']),
                        const SizedBox(height: 14),
                        _buildKeyboardRow(['7', '8', '9']),
                        const SizedBox(height: 14),
                        _buildKeyboardRow(['.', '0', '⌫']),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return Expanded(
          child: _AirKeyboardKey(keyLabel: key, onTap: () => _onKeyPress(key)),
        );
      }).toList(),
    );
  }
}

class _AirKeyboardKey extends StatelessWidget {
  final String keyLabel;
  final VoidCallback onTap;

  const _AirKeyboardKey({Key? key, required this.keyLabel, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDeleteKey = keyLabel == '⌫';
    final bool isDotKey = keyLabel == '.';

    final Color backgroundColor = isDeleteKey
        ? const Color(0xFFFFF1F2)
        : const Color(0xFFF8FAFC);
    final Color textColor = isDeleteKey
        ? const Color(0xFFEF4444)
        : LuminaTheme.textColor;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: backgroundColor,
          boxShadow: [
            // ИСПРАВЛЕНО: Чуть более выразительная тень для сочного неоморфного эффекта на новом фоне
            BoxShadow(
              color: isDeleteKey
                  ? const Color(0xFFFCA5A5).withValues(alpha: 0.18)
                  : const Color(0xFF1E293B).withValues(alpha: 0.09),
              blurRadius: 10,
              offset: const Offset(4, 5),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 6,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            splashColor: isDeleteKey
                ? const Color(0xFFFFE4E6)
                : const Color(0xFFE2E8F0),
            highlightColor: Colors.transparent,
            child: Center(
              child: isDeleteKey
                  ? Icon(Icons.backspace_rounded, color: textColor, size: 22)
                  : Text(
                      keyLabel,
                      style: TextStyle(
                        fontSize: isDotKey ? 28 : 24,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
