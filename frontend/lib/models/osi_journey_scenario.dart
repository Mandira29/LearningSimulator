import 'package:flutter/material.dart';

class OSIHeaderField {
  final String name;
  final String value;
  final bool isChanged;
  final String? previousValue;
  final String? explanation;

  const OSIHeaderField({
    required this.name,
    required this.value,
    this.isChanged = false,
    this.previousValue,
    this.explanation,
  });

  factory OSIHeaderField.fromJson(Map<String, dynamic> json) {
    return OSIHeaderField(
      name: json['name'] as String,
      value: json['value'] as String,
      isChanged: json['isChanged'] as bool? ?? false,
      previousValue: json['previousValue'] as String?,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'isChanged': isChanged,
        'previousValue': previousValue,
        'explanation': explanation,
      };
}

class OSIStep {
  final int stepIndex;
  final String title;
  final String phase; // 'encapsulation', 'transit', 'decapsulation'
  final int activeSenderLayer; // 7 to 1, or 0 if inactive
  final int activeReceiverLayer; // 1 to 7, or 0 if inactive
  final String activeDevice; // 'PC-A', 'Switch', 'Router', 'Server'
  final double pathProgress; // 0.0 to 1.0 along PC-A -> Switch -> Router -> Server
  final String caption;
  final String? deviceHighlight;
  final List<OSIHeaderField> headerFields;
  final String? bitstream;

  const OSIStep({
    required this.stepIndex,
    required this.title,
    required this.phase,
    required this.activeSenderLayer,
    required this.activeReceiverLayer,
    required this.activeDevice,
    required this.pathProgress,
    required this.caption,
    this.deviceHighlight,
    required this.headerFields,
    this.bitstream,
  });

  factory OSIStep.fromJson(Map<String, dynamic> json) {
    return OSIStep(
      stepIndex: json['stepIndex'] as int,
      title: json['title'] as String,
      phase: json['phase'] as String,
      activeSenderLayer: json['activeSenderLayer'] as int,
      activeReceiverLayer: json['activeReceiverLayer'] as int,
      activeDevice: json['activeDevice'] as String,
      pathProgress: (json['pathProgress'] as num).toDouble(),
      caption: json['caption'] as String,
      deviceHighlight: json['deviceHighlight'] as String?,
      headerFields: (json['headerFields'] as List<dynamic>)
          .map((e) => OSIHeaderField.fromJson(e as Map<String, dynamic>))
          .toList(),
      bitstream: json['bitstream'] as String?,
    );
  }
}

class OSIScenario {
  final String id;
  final String name;
  final String description;
  final String sourceDevice;
  final String destinationDevice;
  final List<OSIStep> steps;
  final Map<String, dynamic> quiz;

  const OSIScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.sourceDevice,
    required this.destinationDevice,
    required this.steps,
    required this.quiz,
  });

  factory OSIScenario.fromJson(Map<String, dynamic> json) {
    return OSIScenario(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      sourceDevice: json['sourceDevice'] as String,
      destinationDevice: json['destinationDevice'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => OSIStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      quiz: json['quiz'] as Map<String, dynamic>,
    );
  }
}

class OSILayerInfo {
  final int number;
  final String name;
  final String pdu;
  final Color color;
  final String purpose;
  final String protocols;
  final String headerAdded;
  final String realWorldAnalogy;

  const OSILayerInfo({
    required this.number,
    required this.name,
    required this.pdu,
    required this.color,
    required this.purpose,
    required this.protocols,
    required this.headerAdded,
    required this.realWorldAnalogy,
  });
}

final List<OSILayerInfo> defaultOSILayers = [
  const OSILayerInfo(
    number: 7,
    name: 'Application',
    pdu: 'Data',
    color: Color(0xFFE11D48), // Rose Red
    purpose: 'Provides network services directly to end-user applications and manages packet payload data.',
    protocols: 'HTTP, HTTPS, FTP, DNS, SSH, SMTP',
    headerAdded: 'HTTP GET /index.html Host: 10.0.0.5 User-Agent: NetVisual/1.0',
    realWorldAnalogy: 'The written letter inside the envelope: the raw content you wish to communicate.',
  ),
  const OSILayerInfo(
    number: 6,
    name: 'Presentation',
    pdu: 'Data',
    color: Color(0xFFA855F7), // Purple
    purpose: 'Translates, encrypts, compresses, and formats data into standard structures.',
    protocols: 'TLS/SSL, ASCII, JPEG, MPEG, UTF-8',
    headerAdded: 'Encoding: UTF-8, Encryption: TLS 1.3 CipherSuite AES-GCM',
    realWorldAnalogy: 'Translating the letter into a common language (e.g., English) and placing it into a protective sleeve.',
  ),
  const OSILayerInfo(
    number: 5,
    name: 'Session',
    pdu: 'Data',
    color: Color(0xFF6366F1), // Indigo
    purpose: 'Establishes, manages, synchronizes, and terminates communication sessions between endpoints.',
    protocols: 'NetBIOS, PPTP, RPC, SOCKS',
    headerAdded: 'Session ID: 0x8F9A2B, Dialog Control: Full-Duplex Sync Point',
    realWorldAnalogy: 'Opening a phone call conversation and establishing "Hello, can you hear me?" before speaking.',
  ),
  const OSILayerInfo(
    number: 4,
    name: 'Transport',
    pdu: 'Segment',
    color: Color(0xFFF59E0B), // Amber
    purpose: 'Ensures reliable end-to-end data delivery, flow control, sequence numbering, and port multiplexing.',
    protocols: 'TCP, UDP, SCTP',
    headerAdded: 'Src Port: 54321, Dst Port: 80 (HTTP), Seq: 1001, Ack: 0, Flags: [SYN]',
    realWorldAnalogy: 'Certified registered mail tracking number: ensures every package arrives in sequence without loss.',
  ),
  const OSILayerInfo(
    number: 3,
    name: 'Network',
    pdu: 'Packet',
    color: Color(0xFF06B6D4), // Cyan #29B6F6 primary theme
    purpose: 'Routes logical packets across subnets using logical IP addressing and hop-by-hop forwarding.',
    protocols: 'IPv4, IPv6, ICMP, OSPF, BGP',
    headerAdded: 'Src IP: 192.168.1.10, Dst IP: 10.0.0.5, TTL: 64, Protocol: 6 (TCP)',
    realWorldAnalogy: 'The destination street address and zip code written on the outer envelope.',
  ),
  const OSILayerInfo(
    number: 2,
    name: 'Data Link',
    pdu: 'Frame',
    color: Color(0xFF10B981), // Emerald Green
    purpose: 'Handles physical node-to-node frame transmission, MAC addressing, and link error checking.',
    protocols: 'Ethernet II (802.3), Wi-Fi (802.11), ARP, PPP',
    headerAdded: 'Src MAC: AA:AA:AA:11:11:11, Dst MAC: BB:BB:BB:22:22:22, EtherType: 0x0800, FCS: 0x3F2A',
    realWorldAnalogy: 'The local courier truck license plate transporting the envelope from depot to depot.',
  ),
  const OSILayerInfo(
    number: 1,
    name: 'Physical',
    pdu: 'Bits',
    color: Color(0xFF3B82F6), // Blue
    purpose: 'Transmits raw unstructured binary bitstreams over physical copper, fiber, or wireless media.',
    protocols: '1000BASE-T Ethernet, RJ-45, Fiber Optic, NRZ Signal',
    headerAdded: 'Preamble: 10101010... SFD: 10101011 (Raw Voltage NRZ Bitstream)',
    realWorldAnalogy: 'The physical asphalt road or copper wire supporting movement between locations.',
  ),
];
