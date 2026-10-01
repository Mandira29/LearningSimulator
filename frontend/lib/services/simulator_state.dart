import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/connection.dart';
import '../models/network.dart';
import '../models/packet.dart';
import 'simulation_service.dart';

class SimulatorState extends ChangeNotifier {
  final SimulationService _simulationService = SimulationService();
  StreamSubscription<dynamic>? _healthCheckSub;

  final List<Device> _devices = [];
  final List<Connection> _connections = [];

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
    if (_isAnimating) return;
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(ipAddress: newIp);
      if (_selectedDevice?.id == id) {
        _selectedDevice = _devices[index];
      }
      _simulationMessage = 'IP Address updated for ${_devices[index].name} to $newIp';
      notifyListeners();
    }
  }
}
