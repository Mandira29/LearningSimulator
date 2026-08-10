import 'dart:math';

class Device {
  final String id;
  final String type; // PC, SWITCH, ROUTER
  final String name;
  double x;
  double y;
  final String ipAddress;
  final String macAddress;

  Device({
    required this.id,
    required this.type,
    required this.name,
    required this.x,
    required this.y,
    required this.ipAddress,
    required this.macAddress,
  });

  // Factory helper to create a device with automatically generated details
  factory Device.create({
    required String id,
    required String type,
    required String name,
    required double x,
    required double y,
  }) {
    final rand = Random();
    String ip = '';
    String mac = '';

    if (type.toUpperCase() == 'PC') {
      final lastOctet = 10 + rand.nextInt(40); // 192.168.1.10 - 192.168.1.49
      ip = '192.168.1.$lastOctet';
      final macHex = lastOctet.toRadixString(16).padLeft(2, '0').toUpperCase();
      mac = 'AA:AA:AA:00:00:$macHex';
    } else if (type.toUpperCase() == 'ROUTER') {
      final lastOctet = 1 + rand.nextInt(5); // 192.168.1.1 - 192.168.1.5
      ip = '192.168.1.$lastOctet';
      final macHex = lastOctet.toRadixString(16).padLeft(2, '0').toUpperCase();
      mac = 'CC:CC:CC:00:00:$macHex';
    } else {
      // SWITCH
      // Switches operate at Layer 2 and usually don't have an IP in simple simulations,
      // but let's provide a mock IP/MAC as requested.
      final lastOctet = 50 + rand.nextInt(40);
      ip = '192.168.1.$lastOctet';
      final macHex = lastOctet.toRadixString(16).padLeft(2, '0').toUpperCase();
      mac = 'BB:BB:BB:00:00:$macHex';
    }

    return Device(
      id: id,
      type: type.toUpperCase(),
      name: name,
      x: x,
      y: y,
      ipAddress: ip,
      macAddress: mac,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      ipAddress: json['ipAddress'] as String,
      macAddress: json['macAddress'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'x': x,
      'y': y,
      'ipAddress': ipAddress,
      'macAddress': macAddress,
    };
  }

  Device copyWith({
    String? id,
    String? type,
    String? name,
    double? x,
    double? y,
    String? ipAddress,
    String? macAddress,
  }) {
    return Device(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
    );
  }
}
