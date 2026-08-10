import '../core/api_client.dart';
import '../models/network.dart';
import '../models/packet.dart';

class SimulationResult {
  final bool success;
  final String? error;
  final String message;
  final List<String>? path;
  final Packet? packet;

  SimulationResult({
    required this.success,
    this.error,
    required this.message,
    this.path,
    this.packet,
  });
}

class SimulationService {
  final ApiClient _apiClient = ApiClient();

  Future<SimulationResult> runPing(
    Network network,
    String sourceId,
    String destinationId,
  ) async {
    if (sourceId.isEmpty || destinationId.isEmpty) {
      return SimulationResult(
        success: false,
        message: 'Select a source and destination device.',
      );
    }

    if (sourceId == destinationId) {
      return SimulationResult(
        success: false,
        error: 'INVALID_DESTINATION',
        message: 'Source and destination devices must be different.',
      );
    }

    final response = await _apiClient.simulate(
      network: network,
      sourceDeviceId: sourceId,
      destinationDeviceId: destinationId,
    );

    if (response['success'] == true) {
      final pathList = (response['path'] as List? ?? []).map((e) => e as String).toList();
      Packet? packet;
      if (response['packet'] != null) {
        packet = Packet.fromJson(response['packet'] as Map<String, dynamic>);
      }

      return SimulationResult(
        success: true,
        message: '✓ Path found\n${pathList.join(" → ")}',
        path: pathList,
        packet: packet,
      );
    } else {
      final error = response['error'] as String? ?? 'UNKNOWN_ERROR';
      final message = response['message'] as String? ?? response['error'] as String? ?? 'Simulation failed';
      return SimulationResult(
        success: false,
        error: error,
        message: message,
      );
    }
  }

  Future<bool> checkBackendConnection() async {
    final res = await _apiClient.checkHealth();
    return res['status'] == 'ok';
  }
}
