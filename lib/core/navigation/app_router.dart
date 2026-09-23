import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/domain/entities/history_expense.dart';
import 'package:lumina/features/history/presentation/screens/add_transaction_screen.dart';
import 'package:lumina/features/history/presentation/screens/budgets_screen.dart';
import 'package:lumina/features/history/presentation/screens/dashboard_screen.dart';
import 'package:lumina/features/history/presentation/screens/goals_screen.dart';
import 'package:lumina/features/history/presentation/screens/history_screen.dart';
import 'package:lumina/features/history/presentation/screens/recurring_screen.dart';
import 'package:lumina/features/profile/presentation/screens/settings_screen.dart';
import 'package:lumina/features/shell/presentation/screens/main_shell_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  debugLogDiagnostics: kDebugMode,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(
          name: 'dashboard',
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          name: 'analytics',
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          name: 'settings',
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          name: 'goals',
          path: '/goals',
          builder: (context, state) => const GoalsScreen(),
        ),
      ],
    ),
    GoRoute(
      name: 'history',
      path: '/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      name: 'recurring',
      path: '/recurring',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RecurringScreen(),
    ),
    GoRoute(
      name: 'budgets',
      path: '/budgets',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;

        // Безопасно получаем категории
        final rawCategories = extra?['categories'];
        final categories = rawCategories is List
            ? rawCategories.whereType<CustomCategory>().toList()
            : const <CustomCategory>[];

        // Безопасно получаем и конвертируем список записей в нужный тип для BudgetsScreen
        final rawRecords = extra?['allRecords'];
        List<HistoryExpenseModel> allRecords = const [];

        if (rawRecords is List) {
          allRecords = rawRecords
              .map((e) {
                if (e is HistoryExpenseModel) return e;
                if (e is HistoryExpense)
                  return HistoryExpenseModel.fromEntity(e);
                return null;
              })
              .whereType<HistoryExpenseModel>()
              .toList();
        }

        return BudgetsScreen(categories: categories, allRecords: allRecords);
      },
    ),
    GoRoute(
      name: 'add-transaction',
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddTransactionScreen(
          initialName: extra?['name'] as String?,
          initialPrice: (extra?['price'] as num?)?.toDouble(),
        );
      },
    ),
  ],
);
