import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/providers/analytics_providers.dart';
import '../../core/api/management_api.dart';

// The pattern used throughout this project: Provider of ValueNotifier
// This ensures maximum compatibility and avoids "Type Not Found" errors in Riverpod 3.x
final sqlResultProvider = Provider.autoDispose<ValueNotifier<AsyncValue<List<dynamic>?>>>((ref) {
  return ValueNotifier(const AsyncData<List<dynamic>?>(null));
});

class SqlEditorActions {
  final Ref ref;
  SqlEditorActions(this.ref);

  Future<void> executeQuery(String projectRef, String query) async {
    final notifier = ref.read(sqlResultProvider);
    notifier.value = const AsyncLoading<List<dynamic>?>();
    
    try {
      final pat = await ref.read(patProvider.future);
      if (pat == null || pat.isEmpty) {
        throw Exception('MANAGEMENT_ERROR: Experimental Access Token (PAT) not found. Please configure it in Project Settings.');
      }

      final api = ref.read(managementApiProvider);
      final results = await api.runQuery(projectRef, query);
      
      print('SQL_DEBUG: Success, count: ${results.length}');
      notifier.value = AsyncData(results);
    } catch (e, s) {
      print('SQL_DEBUG: Error: $e');
      notifier.value = AsyncError(e, s);
    }
  }

  Future<void> saveQuery(String name, String query) async {
    final storage = ref.read(secureStorageProvider);
    await storage.saveSqlSnippet(name, query);
    ref.invalidate(savedQueriesProvider);
  }

  Future<void> deleteQuery(String name) async {
    final storage = ref.read(secureStorageProvider);
    await storage.deleteSqlSnippet(name);
    ref.invalidate(savedQueriesProvider);
  }
}

// Global actions provider
final sqlEditorProvider = Provider((ref) => SqlEditorActions(ref));

// Saved snippets provider
final savedQueriesProvider = FutureProvider<Map<String, String>>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return await storage.getSqlSnippets();
});

