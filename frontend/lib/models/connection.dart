class Connection {
  final String id;
  final String sourceDeviceId;
  final String destinationDeviceId;
  final String status; // active, broken
  final String cableType; // straight_through, crossover, console, fiber

  Connection({
    required this.id,
    required this.sourceDeviceId,
    required this.destinationDeviceId,
    this.status = 'active',
    this.cableType = 'straight_through',
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      sourceDeviceId: json['sourceDeviceId'] as String,
      destinationDeviceId: json['destinationDeviceId'] as String,
      status: json['status'] as String? ?? 'active',
      cableType: json['cableType'] as String? ?? 'straight_through',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceDeviceId': sourceDeviceId,
      'destinationDeviceId': destinationDeviceId,
      'status': status,
      'cableType': cableType,
    };
  }

  Connection copyWith({
    String? id,
    String? sourceDeviceId,
    String? destinationDeviceId,
    String? status,
    String? cableType,
  }) {
    return Connection(
      id: id ?? this.id,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      destinationDeviceId: destinationDeviceId ?? this.destinationDeviceId,
      status: status ?? this.status,
      cableType: cableType ?? this.cableType,
    );
  }
}

