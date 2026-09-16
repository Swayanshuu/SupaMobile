import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/management_api.dart';
import '../../core/providers/core_providers.dart';

import '../../core/providers/analytics_providers.dart';

final databaseMetadataProvider = FutureProvider.family<List<dynamic>, ({String projectRef, String entityType})>((ref, arg) async {
  final api = ref.watch(managementApiProvider);

  String query = '';
  switch (arg.entityType.toLowerCase()) {
    case 'triggers':
      query = '''
        SELECT 
          trigger_name as name,
          event_object_table as table,
          action_statement as definition,
          action_timing as timing,
          event_manipulation as event
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
        ORDER BY trigger_name ASC;
      ''';
      break;
    case 'indexes':
      query = '''
        SELECT 
          indexname as name,
          tablename as table,
          indexdef as definition
        FROM pg_indexes
        WHERE schemaname = 'public'
        ORDER BY indexname ASC;
      ''';
      break;
    case 'functions':
      query = '''
        SELECT 
          p.proname as name,
          n.nspname as schema,
          pg_get_function_arguments(p.oid) as arguments,
          t.typname as return_type
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        JOIN pg_type t ON p.prorettype = t.oid
        WHERE n.nspname = 'public'
        ORDER BY p.proname ASC;
      ''';
      break;
    case 'publications':
      query = '''
        SELECT 
          pubname as name,
          puballtables as all_tables,
          pubinsert as "insert",
          pubupdate as "update",
          pubdelete as "delete"
        FROM pg_publication
        ORDER BY pubname ASC;
      ''';
      break;
    default:
      return [];
  }

  return api.runQuery(arg.projectRef, query);
});

