import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Top-level function for background JSON decoding
dynamic _parseJson(String text) => jsonDecode(text);

class ManagementApiClient {
  static const String _baseUrl = 'https://api.supabase.com/v1';
  final String pat; // Experimental Access Token

  ManagementApiClient({required this.pat});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $pat',
    'Content-Type': 'application/json',
  };

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParams,
    );
    
    try {
      print('API_DEBUG: GET $uri');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      print('API_DEBUG: GET $path responded with ${response.statusCode}');

      if (response.statusCode == 401) {
        throw Exception('UNAUTHORIZED: PAT is invalid or expired');
      }
      if (response.statusCode == 429) {
        final resetMs = response.headers['x-ratelimit-reset'] ?? '60000';
        throw Exception('RATE_LIMITED: Retry after $resetMs ms');
      }
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      if (response.body.isEmpty) return null;

      // Parallel processing: Decode JSON on a separate thread
      return await compute(_parseJson, response.body);
    } catch (e) {
      print('API_DEBUG: GET $path failed: $e');
      rethrow;
    }
  }

  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParams,
    );
    
    try {
      print('API_DEBUG: POST $uri');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      print('API_DEBUG: POST $path responded with ${response.statusCode}');

      if (response.statusCode == 401) {
        throw Exception('UNAUTHORIZED: PAT is invalid or expired');
      }
      // SQL Queries usually return 200 or 201
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      if (response.body.isEmpty) return [];

      // Parallel processing: Decode JSON on a separate thread
      return await compute(_parseJson, response.body);
    } catch (e) {
      print('API_DEBUG: POST $path failed: $e');
      rethrow;
    }
  }
}
