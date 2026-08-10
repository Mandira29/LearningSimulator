import 'device.dart';
import 'connection.dart';

class Network {
  final List<Device> devices;
  final List<Connection> connections;

  Network({
    required this.devices,
    required this.connections,
  });

  factory Network.fromJson(Map<String, dynamic> json) {
    var devicesList = json['devices'] as List? ?? [];
    var connectionsList = json['connections'] as List? ?? [];

    return Network(
      devices: devicesList.map((d) => Device.fromJson(d as Map<String, dynamic>)).toList(),
      connections: connectionsList.map((c) => Connection.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devices': devices.map((d) => d.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
    };
  }
}
