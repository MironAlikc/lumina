import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import '../../data/models/goal_expense_model.dart';

/// Сервис для работы с копилками через Hive
class GoalService {
  static const String boxName = 'savings_goals_box';

  static Future<Box<GoalExpenseModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<GoalExpenseModel>(boxName);
    }
    return Hive.box<GoalExpenseModel>(boxName);
  }

  static Future<void> addGoal({
    required String title,
    required double targetAmount,
    required String icon,
    required int colorValue,
  }) async {
    final box = await _openBox();
    final goal = GoalExpenseModel(
      id: const Uuid().v4(),
      title: title,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      icon: icon,
      colorValue: colorValue,
    );
    await box.add(goal);
  }

  static Future<void> depositToGoal(
    GoalExpenseModel goal,
    double amount,
  ) async {
    final newCurrent = goal.currentAmount + amount;
    final updated = goal.copyWith(currentAmount: newCurrent);
    await updated.save();
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late Box<GoalExpenseModel> _box;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen(GoalService.boxName)) {
      _box = await Hive.openBox<GoalExpenseModel>(GoalService.boxName);
    } else {
      _box = Hive.box<GoalExpenseModel>(GoalService.boxName);
    }
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        title: const Text(
          'Цели и копилки',
          style: TextStyle(
            color: LuminaColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: LuminaColors.textMain),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box<GoalExpenseModel> box, _) {
                final goals = box.values.toList();

                if (goals.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'У вас пока нет активных целей.\nСоздайте копилку, чтобы начать откладывать.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LuminaColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = (goal.currentAmount / goal.targetAmount)
                        .clamp(0.0, 1.0);
                    final percentage = (progress * 100).toStringAsFixed(0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: LuminaColors.surface,
                        borderRadius: LuminaDimensions.borderRadiusLarge,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    goal.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    goal.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: LuminaColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$percentage%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: LuminaColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: LuminaColors.inputFill,
                            color: LuminaColors.primary,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Накоплено: ${goal.currentAmount.toStringAsFixed(0)} ₴',
                                style: const TextStyle(
                                  color: LuminaColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Цель: ${goal.targetAmount.toStringAsFixed(0)} ₴',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LuminaColors.textMain,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: LuminaColors.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          LuminaDimensions.borderRadiusMedium,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showDepositDialog(context, goal),
                                  child: const Text(
                                    'Пополнить',
                                    style: TextStyle(
                                      color: LuminaColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  goal.delete();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: LuminaColors.error,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          backgroundColor: LuminaColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Новая цель',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showAddGoalBottomSheet(context);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showDepositDialog(BuildContext context, GoalExpenseModel goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Пополнить «${goal.title}»'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Сумма пополнения (₴)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount > 0) {
                await GoalService.depositToGoal(goal, amount);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Внести'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String selectedIcon = '🎯';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuminaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Создать новую копилку',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText:
                            'Название цели (например: Отпуск, Новый iPhone)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Целевая сумма (₴)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Иконка:',
                      style: TextStyle(color: LuminaColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['🎯', '✈️', '💻', '🚗', '🏠', '🎁'].map((
                        icon,
                      ) {
                        return GestureDetector(
                          onTap: () => setStateModal(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selectedIcon == icon
                                  ? LuminaColors.primary.withValues(alpha: 0.2)
                                  : LuminaColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuminaColors.primary,
                        ),
                        onPressed: () async {
                          if (titleController.text.isNotEmpty &&
                              targetController.text.isNotEmpty) {
                            final target =
                                double.tryParse(targetController.text) ?? 0.0;
                            await GoalService.addGoal(
                              title: titleController.text,
                              targetAmount: target,
                              icon: selectedIcon,
                              colorValue: 0xFF4CAF50,
                            );
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Создать цель',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
