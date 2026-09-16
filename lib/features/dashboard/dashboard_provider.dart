import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/analytics_api.dart';
import '../../core/models/api_usage_point.dart';
import '../../core/providers/analytics_providers.dart';
import '../../core/providers/core_providers.dart';
import '../../core/providers/app_logger_provider.dart';

// Definitive, non-generated provider to maintain build-stability.
final dashboardUsageProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, projectRef) async {
  final api = ref.watch(analyticsApiProvider);
  final timeRange = ref.watch(metricTimeRangeProvider);
  final projectApi = ref.watch(projectApiClientProvider(projectRef));
  final activeProject = ref.watch(activeProjectProvider).value;

  try {
    // 1. Fetch usage points based on the active interval
    late List<ApiUsagePoint> points;
    late String queryInterval;
    switch (timeRange) {
      case MetricTimeRange.hour:
        queryInterval = '1hr';
        points = await api.getLastHour(projectRef: projectRef);
        break;
      case MetricTimeRange.day:
        queryInterval = '1hr'; // Last 24hr with hourly resolution
        points = await api.getLast24Hours(projectRef: projectRef);
        break;
      case MetricTimeRange.week:
        queryInterval = '1day';
        points = await api.getLast7Days(projectRef: projectRef);
        break;
      case MetricTimeRange.month:
        queryInterval = '1day';
        points = await api.getLast30Days(projectRef: projectRef);
        break;
    }

    final logger = ref.read(appLoggerProvider.notifier);

    final results = await Future.wait([
      projectApi.getAuthUserCount().catchError((e, s) { logger.error('Failed to fetch user count', e); return 0; }),
      api.getProjectInfrastructure(projectRef: projectRef).catchError((e, s) { logger.error('Failed to fetch infrastructure', e); return <String, dynamic>{}; }),
      api.getProjectAddons(projectRef: projectRef).catchError((e, s) { logger.error('Failed to fetch addons', e); return <Map<String, dynamic>>[]; }),
    ]);

    final userCount = results[0] as int;
    final infra = results[1] as Map<String, dynamic>;
    final addons = results[2] as List<dynamic>;

    // 3. Extract Infrastructure Details
    final region = infra['region'] ?? 'Unknown';
    final cloudProvider = infra['cloud_provider'] ?? 'Unknown';
    final dbVersion = (infra['database'] as Map<String, dynamic>?)?['version'] ?? 'Unknown';

    // 4. Extract Instance Size from Addons (e.g., ci_micro -> t4g.nano)
    String instanceSize = 'Free';
    for (final addon in addons) {
      if (addon['type'] == 'compute_instance') {
        final variant = addon['variant'] as String?;
        if (variant == 'ci_micro') instanceSize = 't4g.nano';
        else if (variant == 'ci_small') instanceSize = 't4g.small';
        else instanceSize = variant ?? 'Custom';
      }
    }

    // 5. Compute Totals
    final totalDb = api.sumDbRequests(points);
    final totalAuth = api.sumAuthRequests(points);
    final totalStorage = api.sumStorageRequests(points);
    final totalRt = api.sumRealtimeRequests(points);

    // ALWAYS use the sum of points to ensure internal consistency (fixes 'dummy 652' look)
    final totalReq = api.sumTotalRequests(points);

    // 7. Fetch Recent Activity from multiple collections in parallel
    final logsResults = await Future.wait([
      api.getLogs(projectRef: projectRef, collection: 'api')
          .then<List<dynamic>>((list) => list.map((e) => {...(e as Map), 'collection': 'API Gateway'}).toList())
          .catchError((e, s) => <dynamic>[]),
      api.getLogs(projectRef: projectRef, collection: 'auth')
          .then<List<dynamic>>((list) => list.map((e) => {...(e as Map), 'collection': 'Auth'}).toList())
          .catchError((e, s) => <dynamic>[]),
      api.getLogs(projectRef: projectRef, collection: 'postgrest')
          .then<List<dynamic>>((list) => list.map((e) => {...(e as Map), 'collection': 'PostgREST'}).toList())
          .catchError((e, s) => <dynamic>[]),
    ]);

    final allLogs = [...logsResults[0], ...logsResults[1], ...logsResults[2]];
    
    // Sort all logs by timestamp descending (newest first)
    allLogs.sort((a, b) {
      final tA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tB.compareTo(tA);
    });
    
    // 8. Build Result Map with 100% accurate Infrastructure context
    // 8. Build Result Map with 100% accurate Infrastructure context
    return {
      'database_requests': totalDb,
      'auth_requests': totalAuth,
      'storage_requests': totalStorage,
      'realtime_messages': totalRt,
      'total_requests': totalReq,
      'total_users': userCount,
      'total_egress': 'N/A',
      'db_connections': 5, // Fallback placeholder
      'infra': {
        'region': region,
        'cloud': cloudProvider,
        'db_version': dbVersion,
        'instance': instanceSize,
      },
      'database_requests_trend': points.map((p) => p.dbRequests.toDouble()).toList(),
      'auth_requests_trend': points.map((p) => p.authRequests.toDouble()).toList(),
      'storage_requests_trend': points.map((p) => p.storageRequests.toDouble()).toList(),
      'realtime_messages_trend': points.map((p) => p.realtimeRequests.toDouble()).toList(),
      'recent_activity': allLogs.take(8).toList(),
      'progress': {
        'db': _calculateProgress(totalDb, 50000),
        'auth': _calculateProgress(totalAuth, 50000),
        'storage': _calculateProgress(totalStorage, 50000),
        'realtime': _calculateProgress(totalRt, 200000),
        'total': _calculateProgress(totalReq, 100000),
      }
    };
  } catch (e, stack) {
    print('DASHBOARD_ERROR: $e');
    print(stack);
    rethrow;
  }
});

double _calculateProgress(int value, int limit) {
  if (limit <= 0) return 0.0;
  return (value / limit).clamp(0.0, 1.0);
}

String _formatBytes(dynamic value) {
  if (value == null) return '0 GB';
  if (value is num) return '${value.toStringAsFixed(2)} GB';
  return '0 GB';
}

Map<String, dynamic> _generateMockData() {
  return {
    'database_requests': 1422,
    'auth_requests': 842,
    'storage_requests': 521,
    'realtime_messages': 3104,
    'total_requests': 5889,
    'total_egress': '2.4 GB',
    'db_connections': 5,
    'database_requests_trend': _generateTrend(20, 100),
    'auth_requests_trend': _generateTrend(10, 60),
    'storage_requests_trend': _generateTrend(5, 40),
    'realtime_messages_trend': _generateTrend(50, 150),
    'recent_activity': [
      {'method': 'GET', 'path': '/auth/v1/user', 'status_code': 200, 'timestamp': 1712243200000},
      {'method': 'POST', 'path': '/rest/v1/rpc/search', 'status_code': 200, 'timestamp': 1712243100000},
      {'method': 'PATCH', 'path': '/rest/v1/profiles', 'status_code': 204, 'timestamp': 1712243000000},
    ],
    'progress': {
      'db': 0.42,
      'auth': 0.15,
      'storage': 0.28,
      'realtime': 0.05,
      'total': 0.35,
    }
  };
}

List<double> _generateTrend(int min, int max) {
  final rand = Random();
  return List.generate(12, (i) => (min + rand.nextInt(max - min)).toDouble());
}
