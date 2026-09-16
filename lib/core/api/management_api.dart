import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import 'management_api_client.dart';

class ManagementApi {
  final ManagementApiClient _client;

  ManagementApi({required ManagementApiClient client}) : _client = client;

  Future<List<Project>> getProjects() async {
    final List<dynamic> data = await _client.get('/projects');
    return data.map((json) => Project.fromJson(json)).toList();
  }

  Future<Map<String, String>> getApiKeys(String projectRef) async {
    final List<dynamic> data = await _client.get('/projects/$projectRef/api-keys');
    
    String anonKey = '';
    String serviceRoleKey = '';
    
    for (var keyObj in data) {
      if (keyObj['name'] == 'anon' || keyObj['tags'] == 'anon') {
        anonKey = keyObj['api_key'] ?? '';
      } else if (keyObj['name'] == 'service_role' || keyObj['tags'] == 'service_role') {
        serviceRoleKey = keyObj['api_key'] ?? '';
      }
    }
    
    return {
      'anon': anonKey,
      'service_role': serviceRoleKey,
    };
  }

  Future<Map<String, dynamic>> getAllUsage(String projectRef, {String interval = '7d'}) async {
    final results = await Future.wait([
      _client.get('/projects/$projectRef/analytics/endpoints/usage.api-counts', queryParams: {'interval': interval}),
      _client.get('/projects/$projectRef/analytics/endpoints/usage.api-requests-count', queryParams: {'interval': interval}),
    ]);

    return {
      'api_counts': (results[0] as Map<String, dynamic>)['result'] ?? [],
      'summary_count': (results[1] as Map<String, dynamic>)['result'] ?? [],
    };
  }



  Future<Map<String, double>> getHostMetrics(String projectRef, String serviceRoleKey) async {
    final response = await http.get(
      Uri.parse('https://$projectRef.supabase.co/customer/v1/privileged/metrics'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'apikey': serviceRoleKey,
      },
    );

    if (response.statusCode == 200) {
      return _parsePrometheus(response.body);
    }
    return {};
  }

  Future<int> getAuthUserCount(String projectRef, String serviceRoleKey) async {
    final response = await http.get(
      Uri.parse('https://$projectRef.supabase.co/auth/v1/admin/users?page=1&per_page=1'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'apikey': serviceRoleKey,
      },
    );

    if (response.statusCode == 200) {
      final count = response.headers['x-total-count'];
      return int.tryParse(count ?? '0') ?? 0;
    }
    return 0;
  }

  Map<String, double> _parsePrometheus(String data) {
    final Map<String, double> metrics = {};
    final lines = data.split('\n');
    for (var line in lines) {
      if (line.startsWith('#') || line.trim().isEmpty) continue;
      final parts = line.split(' ');
      if (parts.length >= 2) {
        final name = parts[0].split('{')[0];
        final value = double.tryParse(parts[1]);
        if (value != null) metrics[name] = value;
      }
    }
    return metrics;
  }

  Future<List<dynamic>> runLogQuery(String projectRef, String sql) async {
    final Map<String, dynamic> data = await _client.get(
      '/projects/$projectRef/analytics/endpoints/logs.all',
      queryParams: {'sql': sql},
    );
    return data['result'] ?? [];
  }

  Future<List<dynamic>> getFunctions(String projectRef) async {
    final dynamic data = await _client.get('/projects/$projectRef/functions');
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getSecrets(String projectRef) async {
    final dynamic data = await _client.get('/projects/$projectRef/secrets');
    return data as List<dynamic>;
  }

  Future<List<dynamic>> runQuery(String projectRef, String query) async {
    final dynamic data = await _client.post('/projects/$projectRef/database/query', body: {'query': query});
    return data as List<dynamic>;
  }

  Future<List<dynamic>> getLogs(String projectRef, String collection, {String? query}) async {
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
