import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/network.dart';

class ApiClient {
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

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

  Future<Map<String, dynamic>> saveTopology(String title, String description, String canvasJson) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/topologies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'description': description,
          'canvas_json': canvasJson,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> fetchTopologies() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/topologies'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteTopology(int topologyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/topologies/$topologyId'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> saveProgress({
    required int levelId,
    required String levelName,
    required int stars,
    required int score,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/progress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'level_id': levelId,
          'level_name': levelName,
          'completed': true,
          'stars': stars,
          'score': score,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> fetchProgress() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/progress'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/stats'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Challenges API endpoints
  Future<List<dynamic>> fetchChallenges() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/challenges'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchChallenge(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/challenges/$id'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> startChallenge(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenges/$id/start'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> executeChallengeAction({
    required String challengeId,
    required String actionType,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenges/$challengeId/action'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'actionType': actionType,
          'payload': payload,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {
        'success': false,
        'message': 'HTTP ${response.statusCode}: ${response.body}',
        'objectiveCompleted': false,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to communicate with challenge engine: $e',
        'objectiveCompleted': false,
      };
    }
  }

  Future<Map<String, dynamic>?> resetChallenge(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenges/$id/reset'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> validateChallenge(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenges/$id/validate'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

