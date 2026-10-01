import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/connection.dart';
import '../models/network.dart';
import '../models/packet.dart';
import 'simulation_service.dart';
import 'topology_file_helper.dart';

class SimulatorState extends ChangeNotifier {
  final SimulationService _simulationService = SimulationService();
  StreamSubscription<dynamic>? _healthCheckSub;

  final List<Device> _devices = [];
  final List<Connection> _connections = [];

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

  SimulatorState() {
    _startBackendHealthCheck();
  }

  void _startBackendHealthCheck() {
    checkBackendHealth();
    _healthCheckSub = Stream.periodic(const Duration(seconds: 5)).listen((_) {
      checkBackendHealth();
    });
  }

  @override
  void dispose() {
    _healthCheckSub?.cancel();
    super.dispose();
  }

  Future<void> checkBackendHealth() async {
    try {
      _isBackendConnected = await _simulationService.checkBackendConnection();
    } catch (_) {
      _isBackendConnected = false;
    }
    notifyListeners();
  }

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

  // Troubleshooting getters
  int? get activeLevelIndex => _activeLevelIndex;
  int get levelXp => _levelXp;
  int get hintsUsed => _hintsUsed;
  bool get levelCompleted => _levelCompleted;
  int? get requestedTab => _requestedTab;
  bool get isBackendConnected => _isBackendConnected;

  void clearTabRequest() {
    _requestedTab = null;
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
    if (!_isAnimating) return;
    _isPaused = true;
    notifyListeners();
  }

  void resumeAnimation() {
    if (!_isAnimating) return;
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
      _levelCompleted = true;
    }
    
    notifyListeners();
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
      // Level 1: Broken Cable
      final pc1 = Device(
        id: 'pc1_level1',
        type: 'PC',
        name: 'PC1',
        x: 150,
        y: 220,
        ipAddress: '192.168.1.10',
        macAddress: 'AA:AA:AA:00:00:10',
      );
      final sw1 = Device(
        id: 'sw1_level1',
        type: 'SWITCH',
        name: 'Switch1',
        x: 350,
        y: 220,
        ipAddress: '192.168.1.50',
        macAddress: 'BB:BB:BB:00:00:50',
      );
      final pc2 = Device(
        id: 'pc2_level1',
        type: 'PC',
        name: 'PC2',
        x: 550,
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
        status: 'broken',
      ));

      _sourceDeviceId = pc1.id;
      _destinationDeviceId = pc2.id;
      _simulationStatus = 'READY';
      _simulationMessage = 'Level 1: PC2 is offline. Inspect the cables to diagnose the issue.';
    } else if (index == 2) {
      // Level 2: Incorrect IP
      final pc1 = Device(
        id: 'pc1_level2',
        type: 'PC',
        name: 'PC1',
        x: 150,
        y: 220,
        ipAddress: '192.168.1.10',
        macAddress: 'AA:AA:AA:00:00:10',
      );
      final sw1 = Device(
        id: 'sw1_level2',
        type: 'SWITCH',
        name: 'Switch1',
        x: 350,
        y: 220,
        ipAddress: '192.168.1.50',
        macAddress: 'BB:BB:BB:00:00:50',
      );
      final pc2 = Device(
        id: 'pc2_level2',
        type: 'PC',
        name: 'PC2',
        x: 550,
        y: 220,
        ipAddress: '192.168.2.20',
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
        status: 'active',
      ));

      _sourceDeviceId = pc1.id;
      _destinationDeviceId = pc2.id;
      _simulationStatus = 'READY';
      _simulationMessage = 'Level 2: PC2 is unreachable. Verify if IP addresses are on the same subnet.';
    }

    _requestedTab = 1; // Direct redirection to Simulator
    notifyListeners();
  }

  void exitLevel() {
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



