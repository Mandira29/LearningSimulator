import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubnetCalculatorModal extends StatefulWidget {
  const SubnetCalculatorModal({super.key});

  @override
  State<SubnetCalculatorModal> createState() => _SubnetCalculatorModalState();
}

class _SubnetCalculatorModalState extends State<SubnetCalculatorModal> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.50');
  int _cidrPrefix = 24;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  // --- Subnet Calculations ---
  String _ipToBinary(String ip) {
    try {
      final parts = ip.split('.').map((e) => int.parse(e.trim())).toList();
      if (parts.length != 4) return 'Invalid IP';
      return parts.map((e) => e.toRadixString(2).padLeft(8, '0')).join('.');
    } catch (_) {
      return 'Invalid IP';
    }
  }

  Map<String, String> _calculateSubnet(String ipStr, int prefix) {
    try {
      final parts = ipStr.split('.').map((e) => int.parse(e.trim())).toList();
      if (parts.length != 4 || parts.any((e) => e < 0 || e > 255)) {
        return {'error': 'Invalid IPv4 Address format'};
      }

      final uint32Ip = (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3];
      final maskBits = (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
      final wildcardBits = ~maskBits & 0xFFFFFFFF;

      final netBits = uint32Ip & maskBits;
      final broadBits = uint32Ip | wildcardBits;

      String intToIp(int val) {
        return '${(val >> 24) & 0xFF}.${(val >> 16) & 0xFF}.${(val >> 8) & 0xFF}.${val & 0xFF}';
      }

      final totalHosts = pow(2, (32 - prefix)).toInt();
      final usableHosts = totalHosts > 2 ? totalHosts - 2 : (totalHosts == 2 ? 2 : 1);

      final firstUsableBits = (prefix >= 31) ? netBits : netBits + 1;
      final lastUsableBits = (prefix >= 31) ? broadBits : broadBits - 1;

      return {
        'networkId': intToIp(netBits),
        'broadcastId': intToIp(broadBits),
        'subnetMask': intToIp(maskBits),
        'wildcardMask': intToIp(wildcardBits),
        'firstUsable': intToIp(firstUsableBits),
        'lastUsable': intToIp(lastUsableBits),
        'totalHosts': '$totalHosts',
        'usableHosts': '$usableHosts',
        'ipBinary': _ipToBinary(ipStr),
        'maskBinary': _ipToBinary(intToIp(maskBits)),
      };
    } catch (e) {
      return {'error': 'Calculation Error: $e'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final calc = _calculateSubnet(_ipController.text, _cidrPrefix);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.primaryAccent),
          const SizedBox(width: 10),
          const Text('IP Subnet Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IP & CIDR Inputs
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _ipController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'IP Address',
                        hintText: '192.168.1.1',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _cidrPrefix,
                      decoration: const InputDecoration(
                        labelText: 'CIDR Prefix',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(31, (i) => i + 1).map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text('/$p'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _cidrPrefix = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (calc.containsKey('error'))
                Text(
                  calc['error']!,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                )
              else ...[
                // Calculated Metrics Table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      _buildCalcRow(context, 'Network Address:', calc['networkId']!, isBold: true),
                      const Divider(height: 12),
                      _buildCalcRow(context, 'Broadcast Address:', calc['broadcastId']!, isBold: true),
                      const Divider(height: 12),
                      _buildCalcRow(context, 'Subnet Mask:', calc['subnetMask']!),
                      const Divider(height: 12),
                      _buildCalcRow(context, 'Wildcard Mask:', calc['wildcardMask']!),
                      const Divider(height: 12),
                      _buildCalcRow(
                        context,
                        'Usable Host Range:',
                        '${calc['firstUsable']} - ${calc['lastUsable']}',
                        valueColor: AppColors.success,
                      ),
                      const Divider(height: 12),
                      _buildCalcRow(
                        context,
                        'Usable Host Count:',
                        '${calc['usableHosts']} Hosts',
                        valueColor: AppColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Binary Representations
                Text('Binary Breakdown', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF020617) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IP:   ${calc['ipBinary']}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MASK: ${calc['maskBinary']}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.secondaryAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: const Color(0xFF0F172A),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildCalcRow(BuildContext context, String label, String value, {bool isBold = false, Color? valueColor}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? (isBold ? theme.colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}
