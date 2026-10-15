import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSyncService {
  SupabaseSyncService._();

  static final SupabaseSyncService instance = SupabaseSyncService._();

  static const _batchSize = 200;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null; // Supabase не инициализирован: локальный режим.
    }
  }

  bool get isAuthenticated => _client?.auth.currentUser != null;
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Отправка несинхронизированных счетов. Ошибки пробрасываются.
  Future<void> syncNow() async {
    final supabase = _client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return;
    await _syncAccountsToCloud(supabase, userId);
  }

  Future<void> _syncAccountsToCloud(
    SupabaseClient supabase,
    String userId,
  ) async {
    if (!Hive.isBoxOpen(HiveClient.accountsBox)) return;
    final box = Hive.box<AccountModel>(HiveClient.accountsBox);
    final pending = box.values.where((a) => !a.isSynced).toList();
    if (pending.isEmpty) return;

    await supabase
        .from('accounts')
        .upsert(pending.map((a) => a.toSupabaseMap(userId)).toList());

    // Счёт могли изменить, пока шла отправка: помечаем синхронизированным
    // только тот, что не менялся, иначе правка потеряется.
    final updates = <String, AccountModel>{};
    for (final sent in pending) {
      final current = box.get(sent.id);
      if (current != null && _sameContent(current, sent)) {
        updates[sent.id] = current.copyWith(isSynced: true);
      }
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }

  static bool _sameContent(AccountModel a, AccountModel b) =>
      a.balance == b.balance &&
      a.name == b.name &&
      a.iconCode == b.iconCode &&
      a.colorValue == b.colorValue;

  Future<bool> syncRecord(HistoryExpenseModel expense) async {
    final supabase = _client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return false;

    try {
      await supabase.from('expenses').upsert(expense.toSupabaseMap(userId));
      return true;
    } catch (e, st) {
      debugPrint('Supabase sync error ${expense.id}: $e\n$st');
      return false;
    }
  }

  /// Отправляет пачками. Возвращает id успешно отправленных записей.
  Future<List<String>> syncPool(List<HistoryExpenseModel> items) async {
    final supabase = _client;
    final userId = currentUserId;
    if (supabase == null || userId == null || items.isEmpty) return const [];

    final synced = <String>[];
    for (var i = 0; i < items.length; i += _batchSize) {
      final chunk = items.sublist(i, math.min(i + _batchSize, items.length));
      try {
        await supabase
            .from('expenses')
            .upsert(chunk.map((e) => e.toSupabaseMap(userId)).toList());
        synced.addAll(chunk.map((e) => e.id));
      } catch (e, st) {
        debugPrint('Supabase batch sync error: $e\n$st');
        break; // остальное уйдёт при следующей синхронизации
      }
    }
    return synced;
  }

  Future<bool> deleteRecord(String id) async {
    final supabase = _client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return false;

    try {
      await supabase
          .from('expenses')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      return true;
    } catch (e, st) {
      debugPrint('Supabase delete error $id: $e\n$st');
      return false;
    }
  }
}
