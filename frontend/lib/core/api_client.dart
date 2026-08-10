import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/network.dart';

class ApiClient {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> simulate({
    required Network network,
    required String sourceDeviceId,
    required String destinationDeviceId,
  }) async {
    try {
      final bodyMap = {
        'devices': network.devices.map((d) => d.toJson()).toList(),
        'connections': network.connections.map((c) => c.toJson()).toList(),
        'sourceDeviceId': sourceDeviceId,
        'destinationDeviceId': destinationDeviceId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/simulate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(bodyMap),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'error': 'SERVER_ERROR',
          'message': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'CONNECTION_FAILED',
        'message': 'Failed to connect to backend: $e'
      };
    }
  }
}
