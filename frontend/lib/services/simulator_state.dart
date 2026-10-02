import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/connection.dart';
import '../models/network.dart';
import '../models/packet.dart';
import '../models/queued_packet.dart';
import '../models/challenge.dart';
import '../models/challenge_data.dart';
import 'simulation_service.dart';
import 'topology_file_helper.dart';


class SimulatorState extends ChangeNotifier {
  final SimulationService _simulationService = SimulationService();
  StreamSubscription<dynamic>? _healthCheckSub;

  final List<Device> _devices = [];
  final List<Connection> _connections = [];

  // Challenges System state
  List<Challenge> _challenges = getDefaultChallenges();
  Challenge? _activeChallenge;
  int _challengeHintsUsed = 0;

  // Custom User Packet Queue
  final List<QueuedPacket> _packetQueue = [];

  // History Stacks for Undo/Redo
  final List<Network> _undoStack = [];
  final List<Network> _redoStack = [];

  // Time Attack State
  bool _timeAttackActive = false;
  int _timeAttackSeconds = 60;
  Timer? _timeAttackTimer;

  Device? _selectedDevice;
  Connection? _selectedConnection;

  bool _connectionMode = false;
  Device? _firstSelectedDeviceForConnection;

  String _sourceDeviceId = '';
  String _destinationDeviceId = '';

  String _simulationStatus = 'READY'; // READY, SIMULATING, SUCCESS, FAILED
  String _simulationMessage = '';
  List<String> _simulationPath = [];
  Packet? _simulationPacket;


  // Step 4 Animation state
  bool _isAnimating = false;
  bool _isPaused = false;
  Device? _currentFromDevice;
  Device? _currentToDevice;
  String? _activeConnectionId;
  double _animationProgress = 0.0;
  int _currentSegmentIndex = 0;

  // Troubleshooting & Session state
  int? _activeLevelIndex;
  int _levelXp = 100;
  int _hintsUsed = 0;
  bool _levelCompleted = false;
  int? _requestedTab;
  bool _isBackendConnected = false;

  // Level 1: "Getting started" Objectives tracking
  final Map<String, bool> _level1Objectives = {
    'restart': false, // Objective 1: Use the restart button in the top left to start the simulation over
    'pause': false,   // Objective 2: Pause the simulation
    'inspect_pc': false, // Objective 3: Click on a computer to see its properties
    'inspect_packet': false, // Objective 4: Click on a packet (the circles) to see its properties
    'add_packet': false, // Objective 5: Click the + button and add a new packet
    'send_packet': false, // Objective 6: Click the send arrow beside the packet you just added
  };

  // Database State
  Map<String, dynamic>? _dbStats;
  Map<int, Map<String, dynamic>> _completedDbLevels = {};
  List<dynamic> _dbTopologiesList = [];


  SimulatorState() {
    _startBackendHealthCheck();
    fetchDatabaseStats();
    fetchChallenges();
  }

  void _startBackendHealthCheck() {
    checkBackendHealth();
    _healthCheckSub = Stream.periodic(const Duration(seconds: 5)).listen((_) {
      checkBackendHealth();
    });
  }

  bool _isDisposed = false;
  Timer? _level1InitialTimer;

  @override
  void dispose() {
    _isDisposed = true;
    _healthCheckSub?.cancel();
    _level1InitialTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> checkBackendHealth() async {
    try {
      _isBackendConnected = await _simulationService.checkBackendConnection();
      if (_isBackendConnected) {
        await fetchDatabaseStats();
      }
    } catch (_) {
      _isBackendConnected = false;
    }
    notifyListeners();
  }

  Future<void> fetchDatabaseStats() async {
    try {
      final stats = await _simulationService.fetchDashboardStatsFromDb();
      if (stats != null) {
        _dbStats = stats;
      }

      final progressList = await _simulationService.fetchUserProgressFromDb();
      final Map<int, Map<String, dynamic>> newMap = {};
      for (final item in progressList) {
        if (item is Map<String, dynamic>) {
          final levelId = item['level_id'] as int?;
          if (levelId != null) {
            newMap[levelId] = item;
          }
        }
      }
      _completedDbLevels = newMap;

      final tops = await _simulationService.getSavedTopologiesFromDb();
      _dbTopologiesList = tops;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching DB stats: $e');
    }
  }

  // Database Getters
  Map<String, dynamic>? get dbStats => _dbStats;
  Map<int, Map<String, dynamic>> get completedDbLevels => _completedDbLevels;
  List<dynamic> get dbTopologiesList => _dbTopologiesList;


  // Getters
  List<Device> get devices => _devices;
  List<Connection> get connections => _connections;
  Device? get selectedDevice => _selectedDevice;
  Connection? get selectedConnection => _selectedConnection;
  bool get connectionMode => _connectionMode;
  Device? get firstSelectedDeviceForConnection => _firstSelectedDeviceForConnection;
  String get sourceDeviceId => _sourceDeviceId;
  String get destinationDeviceId => _destinationDeviceId;
  String get simulationStatus => _simulationStatus;
  String get simulationMessage => _simulationMessage;
  List<String> get simulationPath => _simulationPath;
  Packet? get simulationPacket => _simulationPacket;

  // Animation getters
  bool get isAnimating => _isAnimating;
  bool get isPaused => _isPaused;
  Device? get currentFromDevice => _currentFromDevice;
  Device? get currentToDevice => _currentToDevice;
  String? get activeConnectionId => _activeConnectionId;
  double get animationProgress => _animationProgress;
  int get currentSegmentIndex => _currentSegmentIndex;

  int get currentActiveOsiLayer {
    if (!_isAnimating) return 3;
    if (_animationProgress < 0.12) return 7; // Application Payload
    if (_animationProgress < 0.22) return 6; // Presentation
    if (_animationProgress < 0.30) return 5; // Session
    if (_animationProgress < 0.38) return 4; // Transport Segment
    if (_animationProgress < 0.46) return 3; // Network Packet (IPv4)
    if (_animationProgress < 0.54) return 2; // Data Link Frame (MAC)
    if (_animationProgress < 0.78) return 1; // Physical Cable Bitstream
    if (_animationProgress < 0.86) return 2; // Frame Decapsulation
    if (_animationProgress < 0.94) return 3; // Packet Inspection
    return 7; // Application Payload Unwrapped
  }

  String get currentEncapsulationPhase {
    if (!_isAnimating) return 'READY / IDLE';
    if (_animationProgress < 0.54) return 'ENCAPSULATING (L7 ➔ L1)';
    if (_animationProgress < 0.78) return 'PHYSICAL BITSTREAM (L1 CABLE)';
    return 'DECAPSULATING (L1 ➔ L7)';
  }


  // Troubleshooting & Level 1 getters
  int? get activeLevelIndex => _activeLevelIndex;
  int get levelXp => _levelXp;
  int get hintsUsed => _hintsUsed;
  bool get levelCompleted => _levelCompleted;
  int? get requestedTab => _requestedTab;
  bool get isBackendConnected => _isBackendConnected;

  // Challenge System Getters
  List<Challenge> get challenges => _challenges;
  Challenge? get activeChallenge => _activeChallenge;
  int get challengeHintsUsed => _challengeHintsUsed;

  // Level 1 Objectives & Packet Queue Getters
  Map<String, bool> get level1Objectives => _level1Objectives;
  int get level1CompletedCount => _level1Objectives.values.where((v) => v).length;
  List<QueuedPacket> get packetQueue => _packetQueue;

  void completeObjective(String key) {
    if (_activeLevelIndex == 1 && _level1Objectives.containsKey(key)) {
      if (_level1Objectives[key] == false) {
        _level1Objectives[key] = true;
        _checkLevel1Completion();
        notifyListeners();
      }
    }
  }

  void _checkLevel1Completion() {
    if (_activeLevelIndex == 1 && !_levelCompleted) {
      final allDone = _level1Objectives.values.every((v) => v);
      if (allDone) {
        _levelCompleted = true;
        _simulationMessage = '🎉 Level 1 Complete! All objectives achieved. Great job!';
        _simulationService.saveLevelProgressToDb(
          levelId: 1,
          levelName: 'Getting started',
          stars: 3,
          score: 100,
        ).then((_) {
          fetchDatabaseStats();
        });
      }
    }
  }

  void addPacketToQueue({
    String? sourceId,
    String? destId,
    String protocol = 'ICMP',
    String payload = 'Ping Packet',
  }) {
    final src = (sourceId != null && sourceId.isNotEmpty)
        ? sourceId
        : (_devices.isNotEmpty ? _devices.first.id : '');
    final dst = (destId != null && destId.isNotEmpty)
        ? destId
        : (_devices.length > 1 ? _devices[1].id : (_devices.isNotEmpty ? _devices.first.id : ''));

    final srcDev = _devices.firstWhere(
      (d) => d.id == src,
      orElse: () => Device(id: src, type: 'PC', name: 'PC1', x: 0, y: 0, ipAddress: '', macAddress: ''),
    );
    final dstDev = _devices.firstWhere(
      (d) => d.id == dst,
      orElse: () => Device(id: dst, type: 'PC', name: 'PC2', x: 0, y: 0, ipAddress: '', macAddress: ''),
    );

    final newPkt = QueuedPacket(
      id: 'pkt_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Packet ${_packetQueue.length + 1}',
      sourceDeviceId: src,
      destinationDeviceId: dst,
      sourceName: srcDev.name,
      destName: dstDev.name,
      protocol: protocol.isEmpty ? 'ICMP' : protocol,
      payload: payload.isEmpty ? 'Ping Packet' : payload,
    );

    _packetQueue.add(newPkt);
    _simulationMessage = '✓ Added ${newPkt.name} (${newPkt.sourceName} → ${newPkt.destName}) to queue.';
    if (_activeLevelIndex == 1) {
      completeObjective('add_packet');
    }
    notifyListeners();
  }

  void removePacketFromQueue(String id) {
    _packetQueue.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void dispatchPacketFromQueue(QueuedPacket pkt) {
    setSourceDevice(pkt.sourceDeviceId);
    setDestinationDevice(pkt.destinationDeviceId);
    runPingSimulation();
    if (_activeLevelIndex == 1) {
      completeObjective('send_packet');
    }
  }

  void inspectPacketCircle() {
    _selectedDevice = null;
    _selectedConnection = null;
    if (!_isPaused && _isAnimating) {
      pauseAnimation();
    }
    if (_activeLevelIndex == 1) {
      completeObjective('inspect_packet');
    }
    notifyListeners();
  }

  void restartSimulationOver() {
    if (_activeLevelIndex != null) {
      startLevel(_activeLevelIndex!);
      if (_activeLevelIndex == 1) {
        completeObjective('restart');
      }
    } else {
      clearCanvas();
    }
  }

  void clearTabRequest() {
    _requestedTab = null;
  }

  void requestTab(int tabIndex) {
    _requestedTab = tabIndex;
    notifyListeners();
  }

  Network get network => Network(devices: _devices, connections: _connections);

  // Actions
  void addDevice(String type, double x, double y) {
    if (_isAnimating) return; // Safeguard during animation

    saveUndoSnapshot();

    final typeUpper = type.toUpperCase();
    final count = _devices.where((d) => d.type == typeUpper).length + 1;
    final name = '$typeUpper$count';
    final id = '${typeUpper.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';

    final newDevice = Device.create(
      id: id,
      type: typeUpper,
      name: name,
      x: x,
      y: y,
    );

    _devices.add(newDevice);
    
    // Automatically select the new device
    selectDevice(newDevice.id);
    notifyListeners();
  }

  void moveDevice(String id, double x, double y) {
    if (_isAnimating) return; // Safeguard during animation

    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index].x = x;
      _devices[index].y = y;
      notifyListeners();
    }
  }

  void selectDevice(String id) {
    if (_connectionMode && _isAnimating) return;

    _selectedConnection = null;
    final device = _devices.firstWhere((d) => d.id == id);
    
    if (_connectionMode) {
      _handleConnectionModeSelection(device);
    } else {
      _selectedDevice = device;
      if (_activeLevelIndex == 1 && device.type.toUpperCase() == 'PC') {
        completeObjective('inspect_pc');
      }
      notifyListeners();
    }
  }

  void selectConnection(String id) {
    if (_isAnimating) return; // Safeguard during animation

    _selectedDevice = null;
    _selectedConnection = _connections.firstWhere((c) => c.id == id);
    notifyListeners();
  }

  void deselectAll() {
    _selectedDevice = null;
    _selectedConnection = null;
    notifyListeners();
  }

  void toggleConnectionMode() {
    if (_isAnimating) return; // Safeguard during animation

    _connectionMode = !_connectionMode;
    if (!_connectionMode) {
      _firstSelectedDeviceForConnection = null;
    } else {
      _selectedDevice = null;
      _selectedConnection = null;
    }
    notifyListeners();
  }

  void _handleConnectionModeSelection(Device secondDevice) {
    if (_firstSelectedDeviceForConnection == null) {
      _firstSelectedDeviceForConnection = secondDevice;
      _simulationMessage = 'Connection Mode: Select destination device';
      notifyListeners();
    } else {
      final firstDevice = _firstSelectedDeviceForConnection!;
      
      // Validate: self connection
      if (firstDevice.id == secondDevice.id) {
        _simulationMessage = 'Connection not allowed: Cannot connect device to itself.';
        _simulationStatus = 'FAILED';
        _connectionMode = false;
        _firstSelectedDeviceForConnection = null;
        notifyListeners();
        return;
      }

      // Validate: duplicate connection
      final duplicate = _connections.any((c) =>
          (c.sourceDeviceId == firstDevice.id && c.destinationDeviceId == secondDevice.id) ||
          (c.sourceDeviceId == secondDevice.id && c.destinationDeviceId == firstDevice.id));

      if (duplicate) {
        _simulationMessage = 'Duplicate connection prevented.';
        _simulationStatus = 'FAILED';
        _connectionMode = false;
        _firstSelectedDeviceForConnection = null;
        notifyListeners();
        return;
      }

      // Create connection
      final connId = 'conn_${DateTime.now().millisecondsSinceEpoch}';
      final newConn = Connection(
        id: connId,
        sourceDeviceId: firstDevice.id,
        destinationDeviceId: secondDevice.id,
        status: 'active',
      );

      _connections.add(newConn);
      _simulationMessage = 'Cable connected between ${firstDevice.name} and ${secondDevice.name}.';
      _simulationStatus = 'READY';
      
      // Exit connection mode
      _connectionMode = false;
      _firstSelectedDeviceForConnection = null;
      
      // Select the newly created connection
      _selectedConnection = newConn;
      notifyListeners();
    }
  }

  void deleteSelected() {
    if (_isAnimating) return; // Safeguard during animation

    if (_selectedDevice != null) {
      final devId = _selectedDevice!.id;
      
      // Remove device
      _devices.removeWhere((d) => d.id == devId);
      
      // Remove attached connections (cascading delete)
      _connections.removeWhere((c) => c.sourceDeviceId == devId || c.destinationDeviceId == devId);
      
      // Clear source/destination if they match deleted device
      if (_sourceDeviceId == devId) _sourceDeviceId = '';
      if (_destinationDeviceId == devId) _destinationDeviceId = '';

      _selectedDevice = null;
      notifyListeners();
    } else if (_selectedConnection != null) {
      final connId = _selectedConnection!.id;
      _connections.removeWhere((c) => c.id == connId);
      _selectedConnection = null;
      notifyListeners();
    }
  }

  void clearCanvas() {
    if (_isAnimating) return; // Safeguard during animation

    _devices.clear();
    _connections.clear();
    _selectedDevice = null;
    _selectedConnection = null;
    _firstSelectedDeviceForConnection = null;
    _connectionMode = false;
    _sourceDeviceId = '';
    _destinationDeviceId = '';
    _simulationStatus = 'READY';
    _simulationMessage = '';
    _simulationPath = [];
    _simulationPacket = null;
    
    // Clear animation state
    _isAnimating = false;
    _isPaused = false;
    _currentFromDevice = null;
    _currentToDevice = null;
    _activeConnectionId = null;
    _animationProgress = 0.0;
    _currentSegmentIndex = 0;

    notifyListeners();
  }

  void resetCanvas() {
    clearCanvas();
  }

  void setSourceDevice(String id) {
    if (_isAnimating) return;
    if (id == _destinationDeviceId && id.isNotEmpty) {
      _simulationMessage = 'Source and destination must be different devices.';
      _simulationStatus = 'FAILED';
      notifyListeners();
      return;
    }
    _sourceDeviceId = id;
    _simulationStatus = 'READY';
    _simulationMessage = '';
    notifyListeners();
  }

  void setDestinationDevice(String id) {
    if (_isAnimating) return;
    if (id == _sourceDeviceId && id.isNotEmpty) {
      _simulationMessage = 'Source and destination must be different devices.';
      _simulationStatus = 'FAILED';
      notifyListeners();
      return;
    }
    _destinationDeviceId = id;
    _simulationStatus = 'READY';
    _simulationMessage = '';
    notifyListeners();
  }

  // Toggles connection state (for test/troubleshoot purposes in Step 2/3/4)
  void toggleConnectionStatus(String connId) {
    if (_isAnimating) return; // Safeguard during animation

    final idx = _connections.indexWhere((c) => c.id == connId);
    if (idx != -1) {
      final current = _connections[idx];
      final nextStatus = current.status == 'active' ? 'broken' : 'active';
      _connections[idx] = current.copyWith(status: nextStatus);
      if (_selectedConnection?.id == connId) {
        _selectedConnection = _connections[idx];
      }
      notifyListeners();
    }
  }

  // Hands-on cable replacement: allows user to select the cable type manually
  void updateConnectionCableType(String connId, String newCableType) {
    if (_isAnimating) return;

    final idx = _connections.indexWhere((c) => c.id == connId);
    if (idx != -1) {
      final current = _connections[idx];
      _connections[idx] = current.copyWith(cableType: newCableType);
      if (_selectedConnection?.id == connId) {
        _selectedConnection = _connections[idx];
      }
      _simulationMessage = 'Cable type updated to $newCableType';
      notifyListeners();
    }
  }


  // Step 4 Animation Triggers
  void startAnimation() {
    _isAnimating = true;
    _isPaused = false;
    _selectedDevice = null;
    _selectedConnection = null;
    _simulationStatus = 'SIMULATING';
    _simulationMessage = 'PACKET TRAVELLING';
    notifyListeners();
  }

  void updateAnimationProgress(double progress) {
    _animationProgress = progress;
    notifyListeners();
  }

  void setAnimationSegment({required Device from, required Device to, required int index}) {
    _currentFromDevice = from;
    _currentToDevice = to;
    _currentSegmentIndex = index;
    
    // Resolve which connection links these two devices to highlight it
    final connIdx = _connections.indexWhere((c) =>
        (c.sourceDeviceId == from.id && c.destinationDeviceId == to.id) ||
        (c.sourceDeviceId == to.id && c.destinationDeviceId == from.id));
    if (connIdx != -1) {
      _activeConnectionId = _connections[connIdx].id;
    } else {
      _activeConnectionId = null;
    }

    notifyListeners();
  }

  void pauseAnimation() {
    _isPaused = true;
    if (_activeLevelIndex == 1) {
      completeObjective('pause');
    }
    notifyListeners();
  }

  void resumeAnimation() {
    _isPaused = false;
    notifyListeners();
  }

  void completeAnimation() {
    _isAnimating = false;
    _isPaused = false;
    _currentFromDevice = null;
    _currentToDevice = null;
    _activeConnectionId = null;
    _animationProgress = 0.0;
    _simulationStatus = 'SUCCESS';
    _simulationMessage = '✓ PACKET DELIVERED\nPath: ${_simulationPath.join(" → ")}';
    
    if (_activeLevelIndex != null) {
      if (_activeLevelIndex == 1) {
        _checkLevel1Completion();
      } else {
        _levelCompleted = true;
        final int stars = _hintsUsed == 0 ? 3 : (_hintsUsed == 1 ? 2 : 1);
        final int lvlId = _activeLevelIndex!;
        final lvlName = lvlId == 2
            ? 'Broken Cable'
            : (lvlId == 3 ? 'Incorrect IP' : 'Port Down');
        _simulationService.saveLevelProgressToDb(
          levelId: lvlId,
          levelName: lvlName,
          stars: stars,
          score: _levelXp,
        ).then((_) {
          fetchDatabaseStats();
        });
      }
    }

    // Refresh database stats for packet trace counter
    fetchDatabaseStats();
    
    notifyListeners();
  }

  Future<void> recordQuizProgressToDb(int levelId, int xpEarned) async {
    try {
      await _simulationService.saveLevelProgressToDb(
        levelId: levelId,
        levelName: 'OSI Journey Quiz',
        stars: 3,
        score: xpEarned,
      );
      await fetchDatabaseStats();
    } catch (e) {
      debugPrint('Error recording quiz progress to DB: $e');
    }
  }

  void cancelAnimation() {
    _isAnimating = false;
    _isPaused = false;
    _currentFromDevice = null;
    _currentToDevice = null;
    _activeConnectionId = null;
    _animationProgress = 0.0;
    _simulationStatus = 'READY';
    notifyListeners();
  }

  Future<void> runPingSimulation() async {
    if (_isAnimating) return;

    if (_sourceDeviceId.isEmpty || _destinationDeviceId.isEmpty) {
      _simulationStatus = 'FAILED';
      _simulationMessage = 'Select a source and destination device.';
      notifyListeners();
      return;
    }

    _simulationStatus = 'SIMULATING';
    _simulationMessage = 'Sending ping packet...';
    _simulationPath = [];
    _simulationPacket = null;
    notifyListeners();

    final result = await _simulationService.runPing(
      network,
      _sourceDeviceId,
      _destinationDeviceId,
    );

    if (result.success) {
      // Set simulating status and save path data; the screen controller will start visual tracer
      _simulationStatus = 'SIMULATING';
      _simulationMessage = 'PACKET TRAVELLING';
      _simulationPath = result.path ?? [];
      _simulationPacket = result.packet;
    } else {
      _simulationStatus = 'FAILED';
      _simulationMessage = '✕ DELIVERY FAILED\n${result.message}';
      _simulationPath = [];
      _simulationPacket = null;
    }
    notifyListeners();
  }

  // Troubleshooting Level Actions
  void startLevel(int index) {
    _activeLevelIndex = index;
    _levelCompleted = false;
    _levelXp = 100;
    _hintsUsed = 0;
    
    _devices.clear();
    _connections.clear();
    _selectedDevice = null;
    _selectedConnection = null;
    _firstSelectedDeviceForConnection = null;
    _connectionMode = false;
    _isAnimating = false;
    _isPaused = false;

    if (index == 1) {
      // Basic Level: Getting started
      final pc1 = Device(
        id: 'pc1_level1',
        type: 'PC',
        name: 'PC1',
        owner: 'Alice (Research Lab)',
        x: 160,
        y: 220,
        ipAddress: '192.168.1.10',
        macAddress: 'AA:AA:AA:00:00:10',
      );
      final sw1 = Device(
        id: 'sw1_level1',
        type: 'SWITCH',
        name: 'Switch1',
        owner: 'IT Department (Central Switch)',
        x: 380,
        y: 220,
        ipAddress: '192.168.1.50',
        macAddress: 'BB:BB:BB:00:00:50',
      );
      final pc2 = Device(
        id: 'pc2_level1',
        type: 'PC',
        name: 'PC2',
        owner: 'Bob (Design Dept)',
        x: 600,
        y: 220,
        ipAddress: '192.168.1.20',
        macAddress: 'AA:AA:AA:00:00:20',
      );
      _devices.addAll([pc1, sw1, pc2]);

      _connections.add(Connection(
        id: 'conn1_level1',
        sourceDeviceId: pc1.id,
        destinationDeviceId: sw1.id,
        status: 'active',
      ));
      _connections.add(Connection(
        id: 'conn2_level1',
        sourceDeviceId: sw1.id,
        destinationDeviceId: pc2.id,
        status: 'active',
      ));

      _sourceDeviceId = pc1.id;
      _destinationDeviceId = pc2.id;
      _simulationStatus = 'READY';
      _simulationMessage = 'Welcome to Level 1: Getting started! Follow the objectives in the top HUD.';

      _level1Objectives.updateAll((k, v) => false);

      // Trigger initial packet transmission after brief layout pause so user sees packet travelling
      _level1InitialTimer?.cancel();
      _level1InitialTimer = Timer(const Duration(milliseconds: 300), () {
        if (!_isDisposed && _activeLevelIndex == 1 && _devices.length >= 2) {
          runPingSimulation();
        }
      });
    } else if (index == 2) {
      // Level 2: Broken Cable
      final pc1 = Device(
        id: 'pc1_level2',
        type: 'PC',
        name: 'PC1',
        owner: 'Alice (Research Lab)',
        x: 150,
        y: 220,
        ipAddress: '192.168.1.10',
        macAddress: 'AA:AA:AA:00:00:10',
      );
      final sw1 = Device(
        id: 'sw1_level2',
        type: 'SWITCH',
        name: 'Switch1',
        owner: 'IT Department',
        x: 350,
        y: 220,
        ipAddress: '192.168.1.50',
        macAddress: 'BB:BB:BB:00:00:50',
      );
      final pc2 = Device(
        id: 'pc2_level2',
        type: 'PC',
        name: 'PC2',
        owner: 'Bob (Design Dept)',
        x: 550,
        y: 220,
        ipAddress: '192.168.1.20',
        macAddress: 'AA:AA:AA:00:00:20',
      );
      _devices.addAll([pc1, sw1, pc2]);

      _connections.add(Connection(
        id: 'conn1_level2',
        sourceDeviceId: pc1.id,
        destinationDeviceId: sw1.id,
        status: 'active',
      ));
      _connections.add(Connection(
        id: 'conn2_level2',
        sourceDeviceId: sw1.id,
        destinationDeviceId: pc2.id,
        status: 'broken',
      ));

      _sourceDeviceId = pc1.id;
      _destinationDeviceId = pc2.id;
      _simulationStatus = 'READY';
      _simulationMessage = 'Level 2: PC2 is offline. Inspect the cables to diagnose the issue.';
    } else if (index == 3) {
      // Level 3: Incorrect IP
      final pc1 = Device(
        id: 'pc1_level3',
        type: 'PC',
        name: 'PC1',
        owner: 'Alice (Research Lab)',
        x: 150,
        y: 220,
        ipAddress: '192.168.1.10',
        macAddress: 'AA:AA:AA:00:00:10',
      );
      final sw1 = Device(
        id: 'sw1_level3',
        type: 'SWITCH',
        name: 'Switch1',
        owner: 'IT Department',
        x: 350,
        y: 220,
        ipAddress: '192.168.1.50',
        macAddress: 'BB:BB:BB:00:00:50',
      );
      final pc2 = Device(
        id: 'pc2_level3',
        type: 'PC',
        name: 'PC2',
        owner: 'Bob (Design Dept)',
        x: 550,
        y: 220,
        ipAddress: '192.168.2.20',
        macAddress: 'AA:AA:AA:00:00:20',
      );
      _devices.addAll([pc1, sw1, pc2]);

      _connections.add(Connection(
        id: 'conn1_level3',
        sourceDeviceId: pc1.id,
        destinationDeviceId: sw1.id,
        status: 'active',
      ));
      _connections.add(Connection(
        id: 'conn2_level3',
        sourceDeviceId: sw1.id,
        destinationDeviceId: pc2.id,
        status: 'active',
      ));

      _sourceDeviceId = pc1.id;
      _destinationDeviceId = pc2.id;
      _simulationStatus = 'READY';
      _simulationMessage = 'Level 3: PC2 is unreachable. Verify if IP addresses are on the same subnet.';
    } else if (index == 4) {
      // Level 4: Interface Port DOWN
      final pc1 = Device(
        id: 'pc1_level4',
        type: 'PC',
        name: 'PC1',
        owner: 'Alice (Research Lab)',
        x: 150,
        y: 220,
        ipAddress: '192.168.1.10',
        macAddress: 'AA:AA:AA:00:00:10',
        portStatus: 'up',
      );
      final sw1 = Device(
        id: 'sw1_level4',
        type: 'SWITCH',
        name: 'Switch1',
        owner: 'IT Department',
        x: 350,
        y: 220,
        ipAddress: '192.168.1.50',
        macAddress: 'BB:BB:BB:00:00:50',
        portStatus: 'up',
      );
      final pc2 = Device(
        id: 'pc2_level4',
        type: 'PC',
        name: 'PC2',
        owner: 'Bob (Design Dept)',
        x: 550,
        y: 220,
        ipAddress: '192.168.1.20',
        macAddress: 'AA:AA:AA:00:00:20',
        portStatus: 'down',
      );
      _devices.addAll([pc1, sw1, pc2]);

      _connections.add(Connection(
        id: 'conn1_level4',
        sourceDeviceId: pc1.id,
        destinationDeviceId: sw1.id,
        status: 'active',
      ));
      _connections.add(Connection(
        id: 'conn2_level4',
        sourceDeviceId: sw1.id,
        destinationDeviceId: pc2.id,
        status: 'active',
      ));

      _sourceDeviceId = pc1.id;
      _destinationDeviceId = pc2.id;
      _simulationStatus = 'READY';
      _simulationMessage = 'Level 4: PC2 interface is administratively DOWN. Toggle port state to UP in node inspector.';
    }

    _requestedTab = 1; // Direct redirection to Simulator
    notifyListeners();
  }

  void exitLevel() {
    _level1InitialTimer?.cancel();
    _activeLevelIndex = null;
    _levelCompleted = false;
    clearCanvas();
    _requestedTab = 2; // Redirect back to Troubleshooting
    notifyListeners();
  }

  void resetLevel() {
    if (_activeLevelIndex != null) {
      startLevel(_activeLevelIndex!);
      _requestedTab = null; // Suppress redirection on reset
      notifyListeners();
    }
  }

  void showNextHint() {
    if (_activeLevelIndex == null) return;
    if (_hintsUsed < 2) {
      _hintsUsed++;
      _levelXp = 100 - (_hintsUsed * 25);
      notifyListeners();
    }
  }

  // =========================================================================
  // Challenge System Methods
  // =========================================================================

  Future<void> fetchChallenges() async {
    try {
      final list = await _simulationService.fetchChallengesFromDb();
      if (list.isNotEmpty) {
        _challenges = list.map((item) => Challenge.fromJson(item as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void startChallenge(String id) {
    final ch = _challenges.firstWhere(
      (c) => c.id == id,
      orElse: () => getDefaultChallenges().firstWhere((c) => c.id == id),
    );
    _activeLevelIndex = null;
    _level1InitialTimer?.cancel();
    _activeChallenge = ch.copyWith(status: ChallengeStatus.inProgress);
    _challengeHintsUsed = 0;

    _devices.clear();
    _devices.addAll(ch.initialDevices);
    _connections.clear();
    _connections.addAll(ch.initialConnections);

    _selectedDevice = null;
    _selectedConnection = null;
    _firstSelectedDeviceForConnection = null;
    _connectionMode = false;
    _isAnimating = false;
    _isPaused = false;

    if (ch.initialDevices.isNotEmpty) {
      _sourceDeviceId = ch.initialDevices.first.id;
      _destinationDeviceId = ch.initialDevices.last.id;
    } else {
      _sourceDeviceId = '';
      _destinationDeviceId = '';
    }

    _simulationStatus = 'READY';
    _simulationMessage = 'Challenge: ${ch.title} loaded. Follow instructions in top HUD.';
    _simulationPath = [];
    _simulationPacket = null;

    _requestedTab = 1; // Direct redirection to Simulator view
    _simulationService.startChallengeOnBackend(id);
    notifyListeners();
  }

  Future<void> executeChallengeAction(String actionType, [Map<String, dynamic> payload = const {}]) async {
    if (_activeChallenge == null) return;
    final chId = _activeChallenge!.id;

    final res = await _simulationService.executeChallengeAction(
      challengeId: chId,
      actionType: actionType,
      payload: payload,
    );

    final isSuccess = res['success'] == true;
    final isCompleted = res['objectiveCompleted'] == true;
    final updatedProgress = (res['progress'] as Map<String, dynamic>?) ?? _activeChallenge!.progress;

    _activeChallenge = _activeChallenge!.copyWith(
      progress: updatedProgress,
      status: isCompleted ? ChallengeStatus.completed : _activeChallenge!.status,
    );

    // Update challenge in list
    final idx = _challenges.indexWhere((c) => c.id == chId);
    if (idx != -1) {
      _challenges[idx] = _activeChallenge!;
    }

    if (res['path'] != null) {
      _simulationPath = (res['path'] as List).map((e) => e.toString()).toList();
      _simulationStatus = 'SIMULATING';
    }

    if (res['packet'] != null) {
      final pMap = res['packet'] as Map<String, dynamic>;
      _simulationPacket = Packet(
        sourceDeviceId: pMap['sourceDeviceId']?.toString() ?? _sourceDeviceId,
        destinationDeviceId: pMap['destinationDeviceId']?.toString() ?? _destinationDeviceId,
        sourceIP: pMap['sourceIP']?.toString() ?? '192.168.1.10',
        destinationIP: pMap['destinationIP']?.toString() ?? '192.168.1.20',
        sourceMAC: pMap['sourceMAC']?.toString() ?? 'AA:AA:AA:00:00:10',
        destinationMAC: pMap['destinationMAC']?.toString() ?? 'BB:BB:BB:00:00:20',
        protocol: pMap['protocol']?.toString() ?? 'IPv4',
        currentLayer: (pMap['currentLayer'] as num?)?.toInt() ?? 3,
        status: pMap['status']?.toString() ?? 'active',
        path: _simulationPath,
      );
    }

    _simulationMessage = res['message']?.toString() ?? (isSuccess ? 'Action completed.' : 'Action failed.');

    if (isCompleted) {
      _simulationService.saveLevelProgressToDb(
        levelId: 100 + _activeChallenge!.number,
        levelName: 'Challenge: ${_activeChallenge!.title}',
        stars: 3,
        score: 150,
      );
      fetchDatabaseStats();
    }

    notifyListeners();
  }

  void exitChallenge() {
    _activeChallenge = null;
    clearCanvas();
    _requestedTab = 2; // Redirect to Challenges screen
    notifyListeners();
  }

  void resetActiveChallenge() {
    if (_activeChallenge != null) {
      startChallenge(_activeChallenge!.id);
    }
  }

  void showNextChallengeHint() {
    if (_activeChallenge == null) return;
    if (_challengeHintsUsed < _activeChallenge!.hints.length) {
      _challengeHintsUsed++;
      notifyListeners();
    }
  }

  void updateDeviceIp(String id, String newIp) {
    updateDeviceConfig(id, ipAddress: newIp);
  }

  void updateDeviceConfig(
    String id, {
    String? name,
    String? ipAddress,
    String? subnetMask,
    String? defaultGateway,
    String? portStatus,
  }) {
    if (_isAnimating) return;
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        name: name,
        ipAddress: ipAddress,
        subnetMask: subnetMask,
        defaultGateway: defaultGateway,
        portStatus: portStatus,
      );
      if (_selectedDevice?.id == id) {
        _selectedDevice = _devices[index];
      }
      _simulationMessage = 'Configuration updated for ${_devices[index].name}';
      notifyListeners();
    }
  }

  void togglePortStatus(String id) {
    if (_isAnimating) return;
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final currentStatus = _devices[index].portStatus;
      final newStatus = currentStatus.toLowerCase() == 'up' ? 'down' : 'up';
      _devices[index] = _devices[index].copyWith(portStatus: newStatus);
      if (_selectedDevice?.id == id) {
        _selectedDevice = _devices[index];
      }
      _simulationMessage = 'Port status for ${_devices[index].name} set to ${newStatus.toUpperCase()}';
      notifyListeners();
    }
  }

  // --- Topology JSON Save & Load Features ---

  /// Serialize current topology into pretty-printed JSON string
  String exportTopologyJson() {
    final Map<String, dynamic> data = {
      'version': '1.0',
      'generator': 'NetVisual Academy',
      'timestamp': DateTime.now().toIso8601String(),
      'devices': _devices.map((d) => d.toJson()).toList(),
      'connections': _connections.map((c) => c.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Parse and load a JSON topology string into active canvas
  bool loadTopologyJson(String jsonString) {
    if (_isAnimating) return false;
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final network = Network.fromJson(data);

      _devices.clear();
      _devices.addAll(network.devices);

      _connections.clear();
      _connections.addAll(network.connections);

      _selectedDevice = null;
      _selectedConnection = null;
      _sourceDeviceId = '';
      _destinationDeviceId = '';
      _connectionMode = false;
      _firstSelectedDeviceForConnection = null;
      _simulationStatus = 'READY';
      _simulationMessage = '✓ Topology loaded successfully (${_devices.length} devices, ${_connections.length} links)';

      notifyListeners();
      return true;
    } catch (e) {
      _simulationMessage = '✕ Failed to parse JSON topology: $e';
      notifyListeners();
      return false;
    }
  }

  /// Exports active topology as a downloadable or saveable JSON file
  Future<bool> exportTopologyFile() async {
    if (_devices.isEmpty) {
      _simulationMessage = 'Canvas is empty. Add devices before exporting.';
      notifyListeners();
      return false;
    }
    final jsonStr = exportTopologyJson();
    final filename = 'network_topology_${DateTime.now().millisecondsSinceEpoch}.json';
    final success = await TopologyFileHelper.saveJsonFile(jsonStr, filename);
    if (success) {
      _simulationMessage = '✓ Topology exported successfully as $filename';
    } else {
      _simulationMessage = 'Failed to export topology file.';
    }
    notifyListeners();
    return success;
  }

  /// Opens OS file picker to select and load a JSON topology file
  Future<bool> importTopologyFile() async {
    if (_isAnimating) return false;
    final jsonContent = await TopologyFileHelper.pickJsonFile();
    if (jsonContent != null && jsonContent.trim().isNotEmpty) {
      return loadTopologyJson(jsonContent);
    }
    return false;
  }

  // --- Offline Local Device Storage (SharedPreferences) ---

  /// Save current topology into offline local device storage
  Future<bool> saveTopologyToLocalStorage(String name) async {
    if (_devices.isEmpty) {
      _simulationMessage = 'Canvas is empty. Add devices before saving.';
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final keyListJson = prefs.getString('offline_saved_topology_keys') ?? '[]';
      final List<dynamic> keys = jsonDecode(keyListJson);

      final id = 'local_net_${DateTime.now().millisecondsSinceEpoch}';
      final entryName = name.trim().isEmpty ? 'Offline Topology ${keys.length + 1}' : name.trim();
      final jsonStr = exportTopologyJson();

      final record = {
        'id': id,
        'name': entryName,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceCount': _devices.length,
        'json': jsonStr,
      };

      keys.add(id);
      await prefs.setString('offline_saved_topology_keys', jsonEncode(keys));
      await prefs.setString('offline_topology_$id', jsonEncode(record));

      // Also persist to backend SQLite Database if available
      try {
        await _simulationService.saveTopologyToDb(entryName, 'Saved network layout', jsonStr);
        await fetchDatabaseStats();
      } catch (_) {}

      _simulationMessage = '✓ Work saved locally to device: "$entryName"';
      notifyListeners();
      return true;
    } catch (e) {
      _simulationMessage = '✕ Failed to save work locally: $e';
      notifyListeners();
      return false;
    }
  }


  /// Get list of saved local offline topologies
  Future<List<Map<String, dynamic>>> getLocalStorageTopologies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyListJson = prefs.getString('offline_saved_topology_keys') ?? '[]';
      final List<dynamic> keys = jsonDecode(keyListJson);

      final List<Map<String, dynamic>> results = [];
      for (final k in keys) {
        final itemJson = prefs.getString('offline_topology_$k');
        if (itemJson != null) {
          results.add(jsonDecode(itemJson) as Map<String, dynamic>);
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  /// Load a saved topology from local device storage
  Future<bool> loadTopologyFromLocalStorage(String jsonContent) async {
    return loadTopologyJson(jsonContent);
  }

  /// Delete a saved topology from local device storage
  Future<bool> deleteTopologyFromLocalStorage(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyListJson = prefs.getString('offline_saved_topology_keys') ?? '[]';
      final List<dynamic> keys = jsonDecode(keyListJson);

      keys.remove(id);
      await prefs.setString('offline_saved_topology_keys', jsonEncode(keys));
      await prefs.remove('offline_topology_$id');

      _simulationMessage = '✓ Deleted saved local topology';
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }


  /// Load sample preset topologies
  void loadPresetTopology(String presetKey) {
    if (_isAnimating) return;

    if (presetKey == 'basic_lan') {
      loadTopologyJson(jsonEncode({
        "devices": [
          {"id": "pc_1", "type": "PC", "name": "PC1", "x": 150.0, "y": 250.0, "ipAddress": "192.168.1.10", "macAddress": "AA:AA:AA:00:00:10", "subnetMask": "255.255.255.0", "defaultGateway": "192.168.1.1", "portStatus": "up"},
          {"id": "switch_1", "type": "SWITCH", "name": "Switch1", "x": 400.0, "y": 250.0, "ipAddress": "192.168.1.2", "macAddress": "BB:BB:BB:00:00:02", "subnetMask": "255.255.255.0", "defaultGateway": "192.168.1.1", "portStatus": "up"},
          {"id": "pc_2", "type": "PC", "name": "PC2", "x": 650.0, "y": 250.0, "ipAddress": "192.168.1.20", "macAddress": "AA:AA:AA:00:00:20", "subnetMask": "255.255.255.0", "defaultGateway": "192.168.1.1", "portStatus": "up"}
        ],
        "connections": [
          {"id": "conn_1", "sourceDeviceId": "pc_1", "destinationDeviceId": "switch_1", "status": "active", "cableType": "straight_through"},
          {"id": "conn_2", "sourceDeviceId": "switch_1", "destinationDeviceId": "pc_2", "status": "active", "cableType": "straight_through"}
        ]
      }));
    } else if (presetKey == 'dual_subnet') {
      loadTopologyJson(jsonEncode({
        "devices": [
          {"id": "pc_1", "type": "PC", "name": "PC1", "x": 120.0, "y": 180.0, "ipAddress": "192.168.1.10", "macAddress": "AA:AA:AA:00:00:10", "subnetMask": "255.255.255.0", "defaultGateway": "192.168.1.1", "portStatus": "up"},
          {"id": "switch_1", "type": "SWITCH", "name": "SwitchA", "x": 300.0, "y": 180.0, "ipAddress": "192.168.1.2", "macAddress": "BB:BB:BB:00:00:01", "subnetMask": "255.255.255.0", "defaultGateway": "192.168.1.1", "portStatus": "up"},
          {"id": "router_1", "type": "ROUTER", "name": "Router1", "x": 500.0, "y": 250.0, "ipAddress": "192.168.1.1", "macAddress": "CC:CC:CC:00:00:01", "subnetMask": "255.255.255.0", "defaultGateway": "0.0.0.0", "portStatus": "up"},
          {"id": "switch_2", "type": "SWITCH", "name": "SwitchB", "x": 700.0, "y": 320.0, "ipAddress": "192.168.2.2", "macAddress": "BB:BB:BB:00:00:02", "subnetMask": "255.255.255.0", "defaultGateway": "192.168.2.1", "portStatus": "up"},
          {"id": "pc_2", "type": "PC", "name": "PC2", "x": 880.0, "y": 320.0, "ipAddress": "192.168.2.10", "macAddress": "AA:AA:AA:00:00:20", "subnetMask": "255.255.255.0", "defaultGateway": "192.168.2.1", "portStatus": "up"}
        ],
        "connections": [
          {"id": "conn_1", "sourceDeviceId": "pc_1", "destinationDeviceId": "switch_1", "status": "active", "cableType": "straight_through"},
          {"id": "conn_2", "sourceDeviceId": "switch_1", "destinationDeviceId": "router_1", "status": "active", "cableType": "straight_through"},
          {"id": "conn_3", "sourceDeviceId": "router_1", "destinationDeviceId": "switch_2", "status": "active", "cableType": "straight_through"},
          {"id": "conn_4", "sourceDeviceId": "switch_2", "destinationDeviceId": "pc_2", "status": "active", "cableType": "straight_through"}
        ]
      }));
    }
  }

  // --- Undo / Redo System ---

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void saveUndoSnapshot() {
    final currentNet = Network(
      devices: _devices.map((d) => d.copyWith()).toList(),
      connections: _connections.map((c) => c.copyWith()).toList(),
    );
    _undoStack.add(currentNet);
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo || _isAnimating) return;

    final currentNet = Network(
      devices: _devices.map((d) => d.copyWith()).toList(),
      connections: _connections.map((c) => c.copyWith()).toList(),
    );
    _redoStack.add(currentNet);

    final previousNet = _undoStack.removeLast();
    _devices.clear();
    _devices.addAll(previousNet.devices);
    _connections.clear();
    _connections.addAll(previousNet.connections);

    _selectedDevice = null;
    _selectedConnection = null;
    _simulationMessage = '↩ Undo canvas action (History step ${_undoStack.length})';
    notifyListeners();
  }

  void redo() {
    if (!canRedo || _isAnimating) return;

    final currentNet = Network(
      devices: _devices.map((d) => d.copyWith()).toList(),
      connections: _connections.map((c) => c.copyWith()).toList(),
    );
    _undoStack.add(currentNet);

    final nextNet = _redoStack.removeLast();
    _devices.clear();
    _devices.addAll(nextNet.devices);
    _connections.clear();
    _connections.addAll(nextNet.connections);

    _selectedDevice = null;
    _selectedConnection = null;
    _simulationMessage = '↪ Redo canvas action';
    notifyListeners();
  }

  // --- Chaos Scenario Randomizer (Fault Injector) ---

  void injectRandomChaosFault() {
    if (_devices.isEmpty || _isAnimating) {
      _simulationMessage = 'Add devices to the canvas before injecting chaos!';
      notifyListeners();
      return;
    }

    saveUndoSnapshot();
    final rand = Random();
    final faultType = rand.nextInt(5);

    if (faultType == 0 && _devices.isNotEmpty) {
      // 1. Port Administrative Shutdown
      final target = _devices[rand.nextInt(_devices.length)];
      updateDeviceConfig(target.id, portStatus: 'down');
      _simulationMessage = '⚡ CHAOS FAULT: Port on ${target.name} administratively SHUT DOWN!';
    } else if (faultType == 1 && _devices.length >= 2) {
      // 2. Duplicate IP Assignment
      final src = _devices[0];
      final target = _devices[1];
      updateDeviceConfig(target.id, ipAddress: src.ipAddress);
      _simulationMessage = '⚡ CHAOS FAULT: Duplicate IP conflict created on ${target.name} (${src.ipAddress})!';
    } else if (faultType == 2 && _devices.isNotEmpty) {
      // 3. Mismatched Subnet / Gateway
      final target = _devices[rand.nextInt(_devices.length)];
      updateDeviceConfig(target.id, subnetMask: '255.255.255.240', defaultGateway: '10.0.0.1');
      _simulationMessage = '⚡ CHAOS FAULT: Invalid gateway & subnet injected into ${target.name}!';
    } else if (faultType == 3 && _connections.isNotEmpty) {
      // 4. Broken Cable Status
      final conn = _connections[rand.nextInt(_connections.length)];
      final idx = _connections.indexOf(conn);
      _connections[idx] = conn.copyWith(status: 'broken');
      _simulationMessage = '⚡ CHAOS FAULT: Cable link between nodes BROKEN!';
    } else if (_connections.isNotEmpty) {
      // 5. Cable Type Mismatch
      final conn = _connections[rand.nextInt(_connections.length)];
      updateConnectionCableType(conn.id, 'crossover');
      _simulationMessage = '⚡ CHAOS FAULT: Cable type changed to Crossover mismatch!';
    }
    notifyListeners();
  }

  // --- Time Attack Mode ---

  bool get timeAttackActive => _timeAttackActive;
  int get timeAttackSeconds => _timeAttackSeconds;

  void startTimeAttack() {
    _timeAttackActive = true;
    _timeAttackSeconds = 60;
    _timeAttackTimer?.cancel();
    _timeAttackTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeAttackSeconds > 0) {
        _timeAttackSeconds--;
        notifyListeners();
      } else {
        t.cancel();
        _timeAttackActive = false;
        _simulationMessage = '⏱️ TIME EXPIRED! Time attack lab session ended.';
        notifyListeners();
      }
    });
    _simulationMessage = '⏱️ TIME ATTACK STARTED! Fix the network in 60s for +100 Bonus XP!';
    notifyListeners();
  }

  void stopTimeAttack() {
    _timeAttackTimer?.cancel();
    _timeAttackActive = false;
    notifyListeners();
  }
}



