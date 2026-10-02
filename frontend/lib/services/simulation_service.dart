import '../core/api_client.dart';
import '../models/connection.dart';
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
    } else if (response['error'] == 'CONNECTION_FAILED') {
      // Run local client-side simulation engine fallback if backend server is offline
      return _runLocalSimulationFallback(network, sourceId, destinationId);
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

  SimulationResult _runLocalSimulationFallback(
    Network network,
    String sourceId,
    String destinationId,
  ) {
    final devMap = {for (final d in network.devices) d.id: d};
    final srcDev = devMap[sourceId];
    final destDev = devMap[destinationId];

    if (srcDev == null || destDev == null) {
      return SimulationResult(
        success: false,
        error: 'DEVICE_NOT_FOUND',
        message: 'Source or destination device not found.',
      );
    }

    if (srcDev.portStatus.toLowerCase() == 'down') {
      return SimulationResult(
        success: false,
        error: 'PORT_DOWN',
        message: 'Port Administrative State DOWN: Interface on source device "${srcDev.name}" is shut down (DOWN).',
      );
    }

    if (destDev.portStatus.toLowerCase() == 'down') {
      return SimulationResult(
        success: false,
        error: 'PORT_DOWN',
        message: 'Port Administrative State DOWN: Interface on destination device "${destDev.name}" is shut down (DOWN).',
      );
    }

    // BFS Pathfinding
    final adjList = <String, List<String>>{for (final d in network.devices) d.id: []};
    for (final conn in network.connections) {
      if (conn.status == 'broken') continue;
      if (devMap.containsKey(conn.sourceDeviceId) && devMap.containsKey(conn.destinationDeviceId)) {
        adjList[conn.sourceDeviceId]?.add(conn.destinationDeviceId);
        adjList[conn.destinationDeviceId]?.add(conn.sourceDeviceId);
      }
    }

    final queue = <List<String>>[[sourceId]];
    final visited = <String>{};
    List<String>? pathFound;

    while (queue.isNotEmpty) {
      final currentPath = queue.removeAt(0);
      final lastNode = currentPath.last;

      if (lastNode == destinationId) {
        pathFound = currentPath;
        break;
      }

      if (!visited.contains(lastNode)) {
        visited.add(lastNode);
        for (final neighbor in adjList[lastNode] ?? []) {
          queue.add([...currentPath, neighbor]);
        }
      }
    }

    if (pathFound == null || pathFound.isEmpty) {
      return SimulationResult(
        success: false,
        error: 'NO_PATH',
        message: 'No active path exists between ${srcDev.name} and ${destDev.name}. Check line cable connections.',
      );
    }

    // Check Port status along path
    for (final nid in pathFound) {
      final d = devMap[nid];
      if (d != null && d.portStatus.toLowerCase() == 'down') {
        return SimulationResult(
          success: false,
          error: 'PORT_DOWN',
          message: 'Port Administrative State DOWN: Interface on node "${d.name}" is administratively shut down.',
        );
      }
    }

    // Validate Cable types along path
    for (int i = 0; i < pathFound.length - 1; i++) {
      final n1 = devMap[pathFound[i]]!;
      final n2 = devMap[pathFound[i + 1]]!;
      final conn = network.connections.firstWhere(
        (c) => (c.sourceDeviceId == n1.id && c.destinationDeviceId == n2.id) ||
               (c.sourceDeviceId == n2.id && c.destinationDeviceId == n1.id),
        orElse: () => Connection(id: '', sourceDeviceId: '', destinationDeviceId: ''),
      );
      if (conn.id.isNotEmpty && conn.cableType == 'console') {
        return SimulationResult(
          success: false,
          error: 'CABLE_TYPE_MISMATCH',
          message: '✕ Console cable between ${n1.name} and ${n2.name} cannot transmit IP packet data.',
        );
      }
    }

    // Check Subnets
    final srcSub = _getNetPrefix(srcDev.ipAddress, srcDev.subnetMask);
    final destSub = _getNetPrefix(destDev.ipAddress, destDev.subnetMask);
    final hasRouter = pathFound.any((nid) => devMap[nid]?.type.toUpperCase() == 'ROUTER');

    if (srcSub != destSub && !hasRouter) {
      return SimulationResult(
        success: false,
        error: 'SUBNET_MISMATCH',
        message: '✕ IP SUBNET MISMATCH: ${srcDev.name} ($srcSub.x) and ${destDev.name} ($destSub.x) are on different subnets with no router present.',
      );
    }

    final pathNames = pathFound.map((id) => devMap[id]!.name).toList();
    final pkt = Packet(
      sourceDeviceId: srcDev.id,
      destinationDeviceId: destDev.id,
      sourceIP: srcDev.ipAddress,
      destinationIP: destDev.ipAddress,
      sourceMAC: srcDev.macAddress,
      destinationMAC: destDev.macAddress,
      protocol: 'ICMP Echo',
      currentLayer: 3,
      status: 'ready',
      path: pathFound,
    );

    return SimulationResult(
      success: true,
      message: '✓ Path found\n${pathNames.join(" → ")}',
      path: pathNames,
      packet: pkt,
    );
  }

  String _getNetPrefix(String ip, String mask) {
    final parts = ip.split('.');
    return parts.length >= 3 ? '${parts[0]}.${parts[1]}.${parts[2]}' : ip;
  }

  Future<bool> checkBackendConnection() async {
    final res = await _apiClient.checkHealth();
    return res['status'] == 'ok';
  }

  Future<Map<String, dynamic>> saveTopologyToDb(String title, String description, String canvasJson) async {
    return await _apiClient.saveTopology(title, description, canvasJson);
  }

  Future<List<dynamic>> getSavedTopologiesFromDb() async {
    return await _apiClient.fetchTopologies();
  }

  Future<bool> deleteTopologyFromDb(int id) async {
    return await _apiClient.deleteTopology(id);
  }

  Future<Map<String, dynamic>> saveLevelProgressToDb({
    required int levelId,
    required String levelName,
    required int stars,
    required int score,
  }) async {
    return await _apiClient.saveProgress(
      levelId: levelId,
      levelName: levelName,
      stars: stars,
      score: score,
    );
  }

  Future<List<dynamic>> fetchUserProgressFromDb() async {
    return await _apiClient.fetchProgress();
  }

  Future<Map<String, dynamic>?> fetchDashboardStatsFromDb() async {
    return await _apiClient.fetchDashboardStats();
  }

  // Challenge System Methods
  Future<List<dynamic>> fetchChallengesFromDb() async {
    return await _apiClient.fetchChallenges();
  }

  Future<Map<String, dynamic>?> fetchChallengeDetails(String id) async {
    return await _apiClient.fetchChallenge(id);
  }

  Future<Map<String, dynamic>?> startChallengeOnBackend(String id) async {
    return await _apiClient.startChallenge(id);
  }

  final Map<String, Map<String, dynamic>> _localChallengeProgress = {};

  Future<Map<String, dynamic>> executeChallengeAction({
    required String challengeId,
    required String actionType,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final res = await _apiClient.executeChallengeAction(
        challengeId: challengeId,
        actionType: actionType,
        payload: payload,
      );
      if (res['success'] == true) {
        return res;
      }
    } catch (_) {}

    // Fallback to local offline simulation engine
    return _simulateLocalChallengeAction(challengeId, actionType, payload);
  }

  Map<String, dynamic> _simulateLocalChallengeAction(
    String challengeId,
    String actionType,
    Map<String, dynamic> payload,
  ) {
    _localChallengeProgress.putIfAbsent(challengeId, () => <String, dynamic>{});
    final prog = _localChallengeProgress[challengeId]!;

    switch (challengeId) {
      case 'ch01':
        prog['delivered'] = true;
        return {
          'success': true,
          'message': 'Packet successfully sent from Alice to Bob with valid IP headers!',
          'objectiveCompleted': true,
          'progress': prog,
          'path': ['Alice PC', 'Bob PC'],
          'packet': {
            'sourceDeviceId': payload['sourceDeviceId'] ?? 'pc_alice',
            'destinationDeviceId': payload['destinationDeviceId'] ?? 'pc_bob',
            'sourceIP': payload['sourceIP'] ?? '192.168.1.10',
            'destinationIP': payload['destinationIP'] ?? '192.168.1.20',
            'protocol': 'IPv4',
            'currentLayer': 3,
            'status': 'delivered',
          },
        };

      case 'ch02':
        final count = (prog['pingsCompleted'] as int? ?? 0) + 1;
        prog['pingsCompleted'] = count;
        final completed = count >= 5;
        return {
          'success': true,
          'message': 'ICMP Echo Request delivered! Echo Reply received from Google ($count/5).',
          'objectiveCompleted': completed,
          'progress': prog,
          'path': ['Alice PC', 'Google Server', 'Alice PC'],
          'packet': {
            'sourceDeviceId': 'pc_alice',
            'destinationDeviceId': 'srv_google',
            'sourceIP': '192.168.1.10',
            'destinationIP': '8.8.8.8',
            'protocol': 'ICMP',
            'currentLayer': 3,
            'status': 'delivered',
          },
        };

      case 'ch03':
        prog['delivered'] = true;
        return {
          'success': true,
          'message': 'Packet successfully routed from Bob through Router A and Router C to Carol!',
          'objectiveCompleted': true,
          'progress': prog,
          'path': ['Bob', 'Router A', 'Router C', 'Carol'],
          'packet': {
            'sourceDeviceId': 'pc_bob',
            'destinationDeviceId': 'pc_carol',
            'sourceIP': '192.168.1.10',
            'destinationIP': '192.168.3.10',
            'protocol': 'IPv4',
            'currentLayer': 3,
            'ttl': 62,
            'status': 'delivered',
          },
        };

      case 'ch04':
        final sender = payload['sourceDeviceId'] ?? 'pc_alice';
        prog['natTranslation'] = true;
        return {
          'success': true,
          'message': 'Modem translated $sender private IP to public IP (203.0.113.5)!',
          'objectiveCompleted': true,
          'progress': prog,
          'path': [sender == 'pc_alice' ? 'Alice PC' : 'Bob PC', 'Home Modem / NAT', 'Internet / Google'],
          'packet': {
            'sourceDeviceId': sender,
            'destinationDeviceId': 'srv_google',
            'sourceIP': sender == 'pc_alice' ? '192.168.1.10' : '192.168.1.20',
            'translatedSourceIP': '203.0.113.5',
            'destinationIP': '8.8.8.8',
            'protocol': 'IPv4 / NAT',
            'currentLayer': 3,
            'status': 'translated_and_delivered',
          },
        };

      case 'ch05':
        prog['spoofedPacketSent'] = true;
        return {
          'success': true,
          'message': 'IP Spoofing successful! Packet forged with Carol IP (192.168.1.30).',
          'objectiveCompleted': true,
          'progress': prog,
          'path': ['Alice (Sender)', 'Core Switch', 'Bob (Receiver)'],
          'packet': {
            'actualSenderId': 'pc_alice',
            'sourceDeviceId': 'pc_alice',
            'destinationDeviceId': 'pc_bob',
            'sourceIP': '192.168.1.30 (Carol - SPOOFED)',
            'destinationIP': '192.168.1.20',
            'protocol': 'IPv4',
            'currentLayer': 3,
            'status': 'spoofed_delivery',
          },
        };

      case 'ch06':
        prog['redirectionDemonstrated'] = true;
        return {
          'success': true,
          'message': 'Switch CAM table diverted packet to Carol port!',
          'objectiveCompleted': true,
          'progress': prog,
          'path': ['Alice', 'Learning Switch', 'Carol'],
          'packet': {
            'sourceDeviceId': 'pc_alice',
            'destinationDeviceId': 'pc_carol',
            'protocol': 'Ethernet / L2',
            'currentLayer': 2,
            'status': 'intercepted',
          },
        };

      case 'ch07':
        final count = (payload['packetCount'] as num?)?.toInt() ?? 25;
        prog['trafficGenerated'] = count;
        final overloaded = count >= 20;
        prog['serverStatus'] = overloaded ? 'OVERLOADED' : 'Normal';
        return {
          'success': true,
          'message': overloaded
              ? 'Server Overloaded! Traffic ($count pkts/tick) exceeded capacity (20).'
              : 'Traffic ($count pkts) is below capacity (20).',
          'objectiveCompleted': overloaded,
          'progress': prog,
          'path': ['Student PC', 'Google Server'],
        };

      case 'ch08':
        final a = (payload['aliceTraffic'] as num?)?.toInt() ?? 8;
        final b = (payload['bobTraffic'] as num?)?.toInt() ?? 7;
        final c = (payload['carolTraffic'] as num?)?.toInt() ?? 9;
        final d = (payload['daveTraffic'] as num?)?.toInt() ?? 6;
        final total = a + b + c + d;
        prog['totalTraffic'] = total;
        final over = total >= 20;
        prog['serverStatus'] = over ? 'OVERLOADED' : 'Normal';
        return {
          'success': true,
          'message': over
              ? 'DDoS Successful! Aggregate traffic ($total pkts) overwhelmed server.'
              : 'Total traffic ($total) is below capacity (20).',
          'objectiveCompleted': over,
          'progress': prog,
          'path': ['Core Switch', 'Google Server'],
        };

      case 'ch09':
        prog['broadcastSent'] = true;
        return {
          'success': true,
          'message': 'Smurf Attack Successful! 1 broadcast yielded 4 amplified replies to Google.',
          'objectiveCompleted': true,
          'progress': prog,
          'path': ['Attacker', 'Broadcast Switch', 'Google Server'],
          'packet': {
            'sourceDeviceId': 'pc_attacker',
            'destinationDeviceId': 'srv_google',
            'sourceIP': '8.8.8.8 (Google - SPOOFED)',
            'destinationIP': '255.255.255.255',
            'protocol': 'ICMP Echo (Amplified)',
            'currentLayer': 3,
            'status': 'amplified_flood',
          },
        };

      case 'ch10':
        final enc = payload['encrypted'] == true;
        prog['interceptionObserved'] = true;
        return {
          'success': true,
          'message': 'MITM Interception observed at Eve! ${enc ? "Encryption protected payload." : "Plaintext readable."}',
          'objectiveCompleted': true,
          'progress': prog,
          'path': ['Alice', 'Eve', 'Bob'],
          'packet': {
            'originalSender': 'Alice',
            'originalDestination': 'Bob',
            'interceptedBy': 'Eve',
            'encrypted': enc,
            'protocol': enc ? 'TLS/HTTPS' : 'HTTP',
            'currentLayer': 7,
            'status': 'intercepted_and_relayed',
          },
        };

      case 'ch11':
        final viaProxy = payload['useProxy'] == true;
        if (!viaProxy) {
          return {
            'success': false,
            'message': 'BLOCKED BY FIREWALL RULE: Direct traffic to Blocked Site is denied.',
            'objectiveCompleted': false,
            'progress': prog,
            'path': ['Alice', 'Firewall / Censor'],
            'packet': {
              'sourceDeviceId': 'pc_alice',
              'destinationDeviceId': 'site_blocked',
              'isBlocked': true,
              'status': 'dropped',
            },
          };
        } else {
          prog['proxyBypassCompleted'] = true;
          return {
            'success': true,
            'message': 'Proxy Bypass Successful! Alice routed via Proxy Server to Blocked Site.',
            'objectiveCompleted': true,
            'progress': prog,
            'path': ['Alice', 'Proxy Server', 'Blocked Site'],
            'packet': {
              'sourceDeviceId': 'pc_alice',
              'destinationDeviceId': 'site_blocked',
              'protocol': 'HTTP Proxy Tunnel',
              'currentLayer': 7,
              'status': 'proxied_delivery',
            },
          };
        }

      case 'ch12':
        final ttl = (payload['ttl'] as num?)?.toInt() ?? 1;
        final hops = List<Map<String, dynamic>>.from(prog['discoveredHops'] ?? []);
        final names = ['Router 1 (10.1.1.1)', 'Router 2 (10.2.2.1)', 'Router 3 (10.3.3.1)', 'Router 4 (10.4.4.1)', 'Google Server (8.8.8.8)'];
        final idx = (ttl - 1).clamp(0, 4);
        if (!hops.any((h) => h['hop'] == ttl)) {
          hops.add({'hop': ttl, 'name': names[idx]});
        }
        prog['discoveredHops'] = hops;
        final done = hops.length >= 4 || ttl >= 5;
        return {
          'success': true,
          'message': ttl < 5
              ? 'TTL=$ttl reached ${names[idx]}: TTL Expired! Hop $ttl discovered.'
              : 'TTL=$ttl reached destination Google Server! Full path mapped.',
          'objectiveCompleted': done,
          'progress': prog,
          'path': ['Alice PC', ...names.sublist(0, idx + 1)],
          'packet': {
            'sourceDeviceId': 'pc_alice',
            'destinationDeviceId': 'srv_google',
            'currentTTL': ttl,
            'protocol': 'ICMP / Traceroute',
            'currentLayer': 3,
            'status': ttl < 5 ? 'ttl_expired' : 'reached_destination',
          },
        };

      default:
        return {
          'success': true,
          'message': 'Action completed.',
          'objectiveCompleted': true,
          'progress': prog,
        };
    }
  }

  Future<Map<String, dynamic>?> resetChallengeOnBackend(String id) async {
    return await _apiClient.resetChallenge(id);
  }

  Future<Map<String, dynamic>> validateChallengeOnBackend(String id) async {
    return await _apiClient.validateChallenge(id);
  }
}



