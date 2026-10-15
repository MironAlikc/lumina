import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/widgets/error_view.dart';
import 'package:lumina/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:lumina/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:lumina/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:lumina/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lumina/features/goals/presentation/screens/goals_screen.dart';
import 'package:lumina/features/recurring/presentation/screens/recurring_screen.dart';
import 'package:lumina/features/settings/presentation/screens/settings_screen.dart';
import 'package:lumina/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:lumina/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:lumina/features/transactions/presentation/screens/history_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  debugLogDiagnostics: kDebugMode,
  errorBuilder: (context, state) => Scaffold(
    body: ErrorView(
      // Технический текст ошибки пользователю не нужен.
      message: kDebugMode ? state.error?.toString() : null,
      onRetry: () => context.go('/dashboard'),
    ),
  ),
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/dashboard'),

    // Вкладки: состояние каждой сохраняется при переключении
    // (скролл, фильтры), а экраны не пересоздаются.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShellScreen(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'dashboard',
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'analytics',
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'settings',
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Экраны поверх вкладок: без нижней панели.
    GoRoute(
      name: 'goals',
      path: '/goals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalsScreen(),
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
      name: 'accounts',
      path: '/accounts',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccountsScreen(),
    ),
    GoRoute(
      name: 'budgets',
      path: '/budgets',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BudgetsScreen(),
    ),
    GoRoute(
      name: 'add-transaction',
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra is Map ? state.extra as Map : null;
        return AddTransactionScreen(
          initialName:
              extra?['name'] is String ? extra!['name'] as String : null,
          initialPrice: extra?['price'] is num
              ? (extra!['price'] as num).toDouble()
              : null,
          editingId: extra?['id'] is String ? extra!['id'] as String : null,
        );
      },
    ),
  ],
);
