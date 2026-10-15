import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:lumina/core/di/injection_container.dart';
import 'package:lumina/core/services/supabase_sync_service.dart';
import 'package:lumina/features/transactions/domain/repositories/history_repository.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';

/// Запускает синхронизацию, когда появляется сеть.
abstract final class SyncService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static Timer? _debounce;
  static bool _running = false;

  /// Можно вызывать повторно: предыдущая подписка отменяется.
  static void init() {
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.any((r) => r != ConnectivityResult.none)) return;
      // Сеть часто «мигает» несколькими событиями подряд.
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), syncPendingData);
    });
  }

  static Future<void> syncPendingData() async {
    final cloud = SupabaseSyncService.instance;
    if (_running || !cloud.isAuthenticated) return;
    _running = true;
    try {
      await sl<IHistoryRepository>().syncUnsyncedRecords();
      await cloud.syncNow();
      sl<HistoryCubit>().refresh(); // обновить значки синхронизации
    } catch (e, st) {
      debugPrint('Sync failed: $e\n$st');
    } finally {
      _running = false;
    }
  }

  static Future<void> dispose() async {
    _debounce?.cancel();
    await _subscription?.cancel();
    _subscription = null;
  }
}
