import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/features/analytics/presentation/screens/analytics_screen.dart';
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
      ],
    ),
    GoRoute(
      name: 'history',
      path: '/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      name: 'goals',
      path: '/goals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalsScreen(),
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
        return BudgetsScreen(
          categories: extra?['categories'] ?? const [],
          allRecords: extra?['allRecords'] ?? const [],
        );
      },
    ),
    GoRoute(
      name: 'add-transaction',
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddTransactionScreen(
          initialName: extra?['name'],
          initialPrice: (extra?['price'] as num?)?.toDouble(),
        );
      },
    ),
  ],
);
