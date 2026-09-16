import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/management_api.dart';
import '../../core/providers/core_providers.dart';

import '../../core/providers/analytics_providers.dart';
import '../../core/api/analytics_api.dart'; // Import to use the collections constant

final logsProvider = FutureProvider.family<List<dynamic>, ({String projectRef, String collection})>((ref, arg) async {
  final api = ref.watch(managementApiProvider);

  // Map user-friendly tab names to Supabase collection IDs
  final String collectionId = _mapToCollectionId(arg.collection);

  return api.getLogs(arg.projectRef, collectionId);
});

String _mapToCollectionId(String tabName) {
  switch (tabName.toLowerCase()) {
    case 'api': return 'api';
    case 'postgres': return 'database';
    case 'postgrest': return 'postgrest';
    case 'pooler': return 'supavisor';
    case 'auth': return 'auth';
    case 'storage': return 'storage';
    case 'realtime': return 'realtime';
    case 'functions': return 'functions';
    default: return 'api';
  }
}

List<dynamic> _generateMockLogs(String category) {
  return List.generate(10, (i) => {
    'id': 'log_$i',
    'timestamp': DateTime.now().subtract(Duration(minutes: i * 5)).toIso8601String(),
    'event_message': '[$category] Routine health check completed successfully. System status: healthy.',
    'metadata': {'status': 200, 'method': 'GET', 'path': '/v1/$category'}
  });
}

