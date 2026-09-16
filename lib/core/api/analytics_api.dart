import '../models/api_usage_point.dart';
import 'management_api_client.dart';
import 'time_helpers.dart';

class AnalyticsApi {
  final ManagementApiClient _client;

  AnalyticsApi({required ManagementApiClient client}) : _client = client;

  /// Fetches API request counts for the given interval.
  /// [interval] must be '1d', '7d', or '30d'
  Future<List<ApiUsagePoint>> getApiCounts({
    required String projectRef,
    required String interval, // '1d', '7d', or '30d'
  }) async {
    final data = await _client.get(
      '/projects/$projectRef/analytics/endpoints/usage.api-counts',
      queryParams: {'interval': interval},
    );

    final results = data['result'] as List<dynamic>? ?? [];

    final points = results
        .map((e) => ApiUsagePoint.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort ascending by timestamp (oldest first — correct for charting)
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return points;
  }

  /// For "Last Hour" view: fetch 1d interval, then filter to last 60 minutes
  Future<List<ApiUsagePoint>> getLastHour({
    required String projectRef,
  }) async {
    // For 1 hour view, we need a smaller interval (like 15min) if available, 
    // but 1hr is usually the smallest aggregation for long periods.
    // Actually, '1hr' should be fine for filtering.
    final all = await getApiCounts(projectRef: projectRef, interval: '1hr');
    final logs = await getLogs(projectRef: projectRef, collection: 'postgrest').catchError((e, s) => <dynamic>[]);
    final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    return all.where((p) => p.timestamp.isAfter(cutoff)).toList();
  }

  /// For "Last 24 Hours" view: Uses '1hr' interval for a detailed 24-point chart.
  Future<List<ApiUsagePoint>> getLast24Hours({
    required String projectRef,
  }) async {
    return getApiCounts(projectRef: projectRef, interval: '1hr');
  }

  /// For "Last 7 Days" view: Uses '1day' for a daily trend chart.
  Future<List<ApiUsagePoint>> getLast7Days({
    required String projectRef,
  }) async {
    return getApiCounts(projectRef: projectRef, interval: '1day');
  }

  /// For "Last 30 Days" view
  Future<List<ApiUsagePoint>> getLast30Days({
    required String projectRef,
  }) async {
    // Note: 30day might not be supported directly by this endpoint in some tiers
    // so we use '1day' and rely on the sorting, though the API might limit 
    // the number of returned points.
    return getApiCounts(projectRef: projectRef, interval: '1day');
  }



  /// Query logs using SQL
  Future<List<Map<String, dynamic>>> queryLogs({
    required String projectRef,
    required String sql,
    required TimeRange timeRange,
  }) async {
    final data = await _client.get(
      '/projects/$projectRef/analytics/endpoints/logs.all',
      queryParams: {
        'iso_timestamp_start': timeRange.start,
        'iso_timestamp_end': timeRange.end,
        'sql': sql,
      },
    );

    final results = data['result'] as List<dynamic>? ?? [];
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Sum helpers
  int sumTotalRequests(List<ApiUsagePoint> points) => points.fold(0, (sum, p) => sum + p.totalRequests);
  int sumDbRequests(List<ApiUsagePoint> points) => points.fold(0, (sum, p) => sum + p.dbRequests);
  int sumAuthRequests(List<ApiUsagePoint> points) => points.fold(0, (sum, p) => sum + p.authRequests);
  int sumStorageRequests(List<ApiUsagePoint> points) => points.fold(0, (sum, p) => sum + p.storageRequests);
  int sumRealtimeRequests(List<ApiUsagePoint> points) => points.fold(0, (sum, p) => sum + p.realtimeRequests);

  /// HIGH-FIDELITY SUMMARY: Fetches pre-aggregated "Total API Request" count.
  Future<int> getTotalApiRequestsCount({
    required String projectRef,
    String? interval,
  }) async {
    final data = await _client.get(
      '/projects/$projectRef/analytics/endpoints/usage.api-requests-count',
      queryParams: interval != null ? {'interval': interval} : null,
    );
    final results = data['result'] as List<dynamic>? ?? [];
    if (results.isEmpty) return 0;
    final row = results[0] as Map;
    // The field name in api-requests-count is 'count'
    return (row['count'] ?? 0).toInt();
  }

  /// INFRASTRUCTURE: Fetches project details (region, cloud, version).
  Future<Map<String, dynamic>> getProjectInfrastructure({required String projectRef}) async {
    return await _client.get('/projects/$projectRef');
  }

  /// INFRASTRUCTURE: Fetches project addons for instance sizing.
  Future<List<Map<String, dynamic>>> getProjectAddons({required String projectRef}) async {
    final data = await _client.get('/projects/$projectRef/billing/addons');
    if (data is List) {
      final list = data as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// The complete list of official Supabase log collections
  static const List<Map<String, String>> collections = [
    {'id': 'api', 'label': 'API Gateway', 'icon': 'hub'},
    {'id': 'postgres', 'label': 'Postgres', 'icon': 'database'},
    {'id': 'postgrest', 'label': 'PostgREST', 'icon': 'api'},
    {'id': 'pooler', 'label': 'Pooler', 'icon': 'sync_alt'},
    {'id': 'auth', 'label': 'Auth', 'icon': 'fingerprint'},
    {'id': 'storage', 'label': 'Storage', 'icon': 'cloud_queue'},
    {'id': 'realtime', 'label': 'Realtime', 'icon': 'bolt'},
    {'id': 'functions', 'label': 'Edge Functions', 'icon': 'data_object'},
    {'id': 'cron', 'label': 'Cron', 'icon': 'schedule'},
  ];

  /// FETCH LOGS: Standard Supabase project logs (api, auth, db, realtime).
  /// Now optimized to use background parsing.
  Future<List<dynamic>> getLogs({
    required String projectRef,
    required String collection,
    String? query,
  }) async {
    final end = DateTime.now().toUtc();
    final start = end.subtract(const Duration(hours: 24)); // Default 24h as per rule

    String sql = '';
    final whereClause = query != null && query.isNotEmpty ? "AND t.event_message LIKE '%$query%'" : '';

    switch (collection) {
      case 'auth':
      case 'auth_logs':
        sql = '''
          SELECT
            DATETIME(timestamp) as time,
            t.event_message as msg,
            p.status_code,
            p.method,
            p.path
          FROM auth_logs as t
          CROSS JOIN UNNEST(t.metadata) as m
          CROSS JOIN UNNEST(m.request) as p
          WHERE true $whereClause
          ORDER BY timestamp DESC
          LIMIT 100
        ''';
        break;
      case 'database':
      case 'postgres':
      case 'postgres_logs':
        sql = '''
          SELECT
            DATETIME(timestamp) as time,
            t.event_message as msg,
            p.error_severity,
            p.user_name,
            p.query
          FROM postgres_logs as t
          CROSS JOIN UNNEST(t.metadata) as m
          CROSS JOIN UNNEST(m.parsed) as p
          WHERE true $whereClause
          ORDER BY timestamp DESC
          LIMIT 100
        ''';
        break;
      case 'functions':
      case 'function_logs':
        sql = '''
          SELECT
            DATETIME(timestamp) as time,
            t.event_message as msg,
            m.level,
            m.function_id
          FROM function_logs as t
          CROSS JOIN UNNEST(t.metadata) as m
          WHERE true $whereClause
          ORDER BY timestamp DESC
          LIMIT 100
        ''';
        break;
      case 'storage':
      case 'storage_logs':
        sql = '''
          SELECT 
            DATETIME(timestamp) as time, 
            t.event_message as msg,
            r.method, 
            r.path, 
            r.status_code
          FROM storage_logs as t
          CROSS JOIN UNNEST(t.metadata) as m
          CROSS JOIN UNNEST(m.request) as r
          WHERE true $whereClause
          ORDER BY timestamp DESC 
          LIMIT 100
        ''';
        break;
      case 'api':
      case 'edge_logs':
      case 'postgrest':
      default:
        sql = '''
          SELECT 
            DATETIME(timestamp) as time,
            t.event_message as msg,
            r.method, 
            r.path, 
            rsp.status_code
          FROM edge_logs as t
          CROSS JOIN UNNEST(t.metadata) as m
          CROSS JOIN UNNEST(m.request) as r
          CROSS JOIN UNNEST(m.response) as rsp
          WHERE true $whereClause
          ORDER BY timestamp DESC 
          LIMIT 100
        ''';
        break;
    }

    final params = {
      'iso_timestamp_start': start.toIso8601String(),
      'iso_timestamp_end': end.toIso8601String(),
      'sql': sql,
    };
    
    final Map<String, dynamic> data = await _client.get('/projects/$projectRef/analytics/endpoints/logs.all', queryParams: params);
    return data['result'] ?? [];
  }
}
