class Packet {
  final String sourceDeviceId;
  final String destinationDeviceId;
  final String sourceIP;
  final String destinationIP;
  final String sourceMAC;
  final String destinationMAC;
  final String protocol; // e.g., ICMP
  final int currentLayer; // e.g., 3
  final String status; // e.g., ready
  final List<String> path; // list of device IDs

  Packet({
    required this.sourceDeviceId,
    required this.destinationDeviceId,
    required this.sourceIP,
    required this.destinationIP,
    required this.sourceMAC,
    required this.destinationMAC,
    required this.protocol,
    required this.currentLayer,
    required this.status,
    required this.path,
  });

  factory Packet.fromJson(Map<String, dynamic> json) {
    return Packet(
      sourceDeviceId: json['sourceDeviceId'] as String,
      destinationDeviceId: json['destinationDeviceId'] as String,
      sourceIP: json['sourceIP'] as String,
      destinationIP: json['destinationIP'] as String,
      sourceMAC: json['sourceMAC'] as String,
      destinationMAC: json['destinationMAC'] as String,
      protocol: json['protocol'] as String? ?? 'ICMP',
      currentLayer: json['currentLayer'] as int? ?? 3,
      status: json['status'] as String? ?? 'ready',
      path: (json['path'] as List? ?? []).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceDeviceId': sourceDeviceId,
      'destinationDeviceId': destinationDeviceId,
      'sourceIP': sourceIP,
      'destinationIP': destinationIP,
      'sourceMAC': sourceMAC,
      'destinationMAC': destinationMAC,
      'protocol': protocol,
      'currentLayer': currentLayer,
      'status': status,
      'path': path,
    };
  }
}
