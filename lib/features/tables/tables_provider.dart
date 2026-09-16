import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/management_api.dart';
import '../../core/api/project_api.dart';
import '../../core/providers/core_providers.dart';

import '../../core/providers/analytics_providers.dart';

final tableListProvider = FutureProvider.family<List<dynamic>, String>((ref, projectRef) async {
  final pat = await ref.watch(patProvider.future);
  if (pat == null || pat.isEmpty) {
    throw Exception('MANAGEMENT_ERROR: Experimental Access Token (PAT) not found. Please configure it in Project Settings.');
  }

  final api = ref.watch(managementApiProvider);
  const query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';";
  return api.runQuery(projectRef, query);
});

// Use ValueNotifier for maximum build-stability
final tableActionsStateProvider = Provider.autoDispose<ValueNotifier<AsyncValue<void>>>((ref) => ValueNotifier(const AsyncData(null)));

class TableActions {
  final Ref ref;
  TableActions(this.ref);

  Future<void> renameTable(String projectRef, String oldName, String newName) async {
    ref.read(tableActionsStateProvider).value = const AsyncLoading();
    try {
      final api = ref.read(managementApiProvider);
      final query = 'ALTER TABLE "$oldName" RENAME TO "$newName";';
      await api.runQuery(projectRef, query);
      
      ref.invalidate(tableListProvider(projectRef));
      ref.read(tableActionsStateProvider).value = const AsyncData(null);
    } catch (e, s) {
      ref.read(tableActionsStateProvider).value = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> deleteTable(String projectRef, String tableName) async {
    ref.read(tableActionsStateProvider).value = const AsyncLoading();
    try {
      final api = ref.read(managementApiProvider);
      final query = 'DROP TABLE "$tableName";';
      await api.runQuery(projectRef, query);
      
      ref.invalidate(tableListProvider(projectRef));
      ref.read(tableActionsStateProvider).value = const AsyncData(null);
    } catch (e, s) {
      ref.read(tableActionsStateProvider).value = AsyncError(e, s);
      rethrow;
    }
  }
}

final tableActionsProvider = Provider((ref) => TableActions(ref));

final tableDataProvider = FutureProvider.family<List<dynamic>, ({String projectRef, String tableName})>((ref, arg) async {
  final serviceKey = await ref.watch(serviceRoleKeyProvider(arg.projectRef).future);
  if (serviceKey == null) throw Exception('Service role key not found');

  final api = ProjectApi(projectRef: arg.projectRef, serviceRoleKey: serviceKey);
  return api.getTableData(arg.tableName);
});

