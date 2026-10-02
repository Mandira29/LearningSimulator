class QueuedPacket {
  final String id;
  final String name;
  final String sourceDeviceId;
  final String destinationDeviceId;
  final String sourceName;
  final String destName;
  final String protocol;
  final String payload;

  QueuedPacket({
    required this.id,
    required this.name,
    required this.sourceDeviceId,
    required this.destinationDeviceId,
    required this.sourceName,
    required this.destName,
    this.protocol = 'ICMP',
    this.payload = 'Ping Test',
  });
}
