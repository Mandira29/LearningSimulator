class Connection {
  final String id;
  final String sourceDeviceId;
  final String destinationDeviceId;
  final String status; // active, broken

  Connection({
    required this.id,
    required this.sourceDeviceId,
    required this.destinationDeviceId,
    this.status = 'active',
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      sourceDeviceId: json['sourceDeviceId'] as String,
      destinationDeviceId: json['destinationDeviceId'] as String,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceDeviceId': sourceDeviceId,
      'destinationDeviceId': destinationDeviceId,
      'status': status,
    };
  }

  Connection copyWith({
    String? id,
    String? sourceDeviceId,
    String? destinationDeviceId,
    String? status,
  }) {
    return Connection(
      id: id ?? this.id,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      destinationDeviceId: destinationDeviceId ?? this.destinationDeviceId,
      status: status ?? this.status,
    );
  }
}
