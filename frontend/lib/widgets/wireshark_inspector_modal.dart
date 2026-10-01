import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/packet.dart';

class WiresharkInspectorModal extends StatefulWidget {
  final Packet? activePacket;
  final String srcName;
  final String dstName;

  const WiresharkInspectorModal({
    super.key,
    this.activePacket,
    this.srcName = 'PC1',
    this.dstName = 'PC2',
  });

  @override
  State<WiresharkInspectorModal> createState() => _WiresharkInspectorModalState();
}

class _WiresharkInspectorModalState extends State<WiresharkInspectorModal> {
  int _selectedPacketIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final packet = widget.activePacket;
    final srcIp = packet?.sourceIP ?? '192.168.1.10';
    final dstIp = packet?.destinationIP ?? '192.168.1.20';

    final packets = [
      {'no': 1, 'time': '0.000000', 'src': srcIp, 'dst': dstIp, 'proto': 'ICMP', 'len': 74, 'info': 'Echo (ping) request  id=0x0001, seq=1/256, ttl=64'},
      {'no': 2, 'time': '0.002410', 'src': dstIp, 'dst': srcIp, 'proto': 'ICMP', 'len': 74, 'info': 'Echo (ping) reply    id=0x0001, seq=1/256, ttl=64'},
      {'no': 3, 'time': '0.015220', 'src': srcIp, 'dst': '255.255.255.255', 'proto': 'ARP', 'len': 42, 'info': 'Who has $dstIp? Tell $srcIp'},
      {'no': 4, 'time': '0.016010', 'src': dstIp, 'dst': srcIp, 'proto': 'ARP', 'len': 42, 'info': '$dstIp is at AA:AA:AA:00:00:20'},
    ];

    final currentPkt = packets[_selectedPacketIndex];

    // Hex bytes simulation
    final rawBytes = [
      0xaa, 0xaa, 0xaa, 0x00, 0x00, 0x10, 0xbb, 0xbb, 0xbb, 0x00, 0x00, 0x02, 0x08, 0x00, 0x45, 0x00,
      0x00, 0x3c, 0x1c, 0x46, 0x40, 0x00, 0x40, 0x01, 0x73, 0x14, 0xc0, 0xa8, 0x01, 0x0a, 0xc0, 0xa8,
      0x01, 0x14, 0x08, 0x00, 0x4d, 0x5b, 0x00, 0x01, 0x00, 0x01, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66,
      0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76,
    ];

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0284C7),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Wireshark Packet Inspector', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 850,
        height: 520,
        child: Column(
          children: [
            // 1. Packet List Table (Top Pane)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
              ),
              child: ListView.builder(
                itemCount: packets.length,
                itemBuilder: (ctx, idx) {
                  final item = packets[idx];
                  final isSel = idx == _selectedPacketIndex;
                  return InkWell(
                    onTap: () => setState(() => _selectedPacketIndex = idx),
                    child: Container(
                      color: isSel
                          ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD))
                          : (idx % 2 == 0 ? (isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC)) : null),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('${item['no']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                          SizedBox(width: 90, child: Text('${item['time']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                          SizedBox(width: 120, child: Text('${item['src']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 120, child: Text('${item['dst']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 70, child: Text('${item['proto']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.primaryAccent))),
                          SizedBox(width: 60, child: Text('${item['len']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                          Expanded(child: Text('${item['info']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // 2. Encapsulated Protocol Tree View (Middle Pane)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView(
                  children: [
                    _buildTreeTile('▶ Frame 1: 74 bytes on wire (592 bits), 74 bytes captured'),
                    _buildTreeTile('▼ Ethernet II, Src: ${widget.srcName} (AA:AA:AA:00:00:10), Dst: ${widget.dstName} (BB:BB:BB:00:00:02)', isExpanded: true, children: [
                      '  Destination: BB:BB:BB:00:00:02',
                      '  Source: AA:AA:AA:00:00:10',
                      '  Type: IPv4 (0x0800)',
                    ]),
                    _buildTreeTile('▼ Internet Protocol Version 4, Src: ${currentPkt['src']}, Dst: ${currentPkt['dst']}', isExpanded: true, children: [
                      '  0100 .... = Version: 4',
                      '  .... 0101 = Header Length: 20 bytes (5)',
                      '  Differentiates Services Field: 0x00',
                      '  Total Length: 60',
                      '  Time to Live (TTL): 64',
                      '  Protocol: ${currentPkt['proto']} (${currentPkt['proto'] == 'ICMP' ? 1 : 6})',
                      '  Header Checksum: 0x7314 [validation disabled]',
                    ]),
                    _buildTreeTile('▼ Internet Control Message Protocol (Echo request)', isExpanded: true, children: [
                      '  Type: 8 (Echo (ping) request)',
                      '  Code: 0',
                      '  Checksum: 0x4d5b [correct]',
                      '  Identifier (BE): 1 (0x0001)',
                      '  Sequence Number (BE): 1 (0x0001)',
                      '  Data (32 bytes): 6162636465666768696a6b6c6d6e6f70...',
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Hex Dump & Decoded Text Pane (Bottom Pane)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF090D16) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: (rawBytes.length / 16).ceil(),
                  itemBuilder: (ctx, lineIdx) {
                    final start = lineIdx * 16;
                    final end = (start + 16 > rawBytes.length) ? rawBytes.length : start + 16;
                    final chunk = rawBytes.sublist(start, end);

                    final offsetHex = (lineIdx * 16).toRadixString(16).padLeft(4, '0');
                    final hexStr = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
                    final asciiStr = chunk.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : '.').join('');

                    return Text(
                      '$offsetHex   ${hexStr.padRight(48)}   $asciiStr',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeTile(String title, {bool isExpanded = false, List<String>? children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
          if (isExpanded && children != null)
            ...children.map(
              (c) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 1),
                child: Text(c, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF94A3B8))),
              ),
            ),
        ],
      ),
    );
  }
}
