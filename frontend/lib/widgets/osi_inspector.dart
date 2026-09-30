import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';

class OsiInspector extends StatefulWidget {
  final SimulatorState state;

  const OsiInspector({
    super.key,
    required this.state,
  });

  @override
  State<OsiInspector> createState() => _OsiInspectorState();
}

class _OsiInspectorState extends State<OsiInspector> {
  int _selectedOsiLayer = 3; // Default selection: Layer 3
  bool _wasAnimating = false;

  @override
  void didUpdateWidget(covariant OsiInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection to Layer 3 when a new animation sequence begins
    if (widget.state.isAnimating && !_wasAnimating) {
      _selectedOsiLayer = 3;
    }
    _wasAnimating = widget.state.isAnimating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 1,
    );

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBg : AppColors.lightBg,
        border: Border(left: borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inspector Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _showPacketInfo() ? 'PACKET INSPECTOR' : 'DEVICE INSPECTOR',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          
          // Scrollable content area to prevent layout overflows
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  bool _showPacketInfo() {
    return widget.state.isAnimating || 
        (widget.state.simulationStatus == 'SUCCESS' && 
         widget.state.selectedDevice == null && 
         widget.state.selectedConnection == null && 
         widget.state.simulationPacket != null);
  }

  Widget _buildContent(BuildContext context) {
    if (_showPacketInfo()) {
      return _buildPacketOsiView(context);
    } else if (widget.state.selectedDevice != null) {
      return _buildDeviceView(context);
    } else if (widget.state.selectedConnection != null) {
      return _buildConnectionView(context);
    } else {
      return _buildPlaceholderView(context);
    }
  }

  // View 1: Detailed Packet OSI Inspector
  Widget _buildPacketOsiView(BuildContext context) {
    final state = widget.state;
    final pkt = state.simulationPacket!;
    final theme = Theme.of(context);

    // Format top status message
    Color statusColor = AppColors.primaryAccent;
    String statusLabel = 'TRAVELLING';

    if (state.isPaused) {
      statusColor = AppColors.warning;
      statusLabel = 'PAUSED';
    } else if (state.simulationStatus == 'SUCCESS') {
      statusColor = AppColors.success;
      statusLabel = 'DELIVERED';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Packet Status Alert
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PACKET $statusLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pause / Resume Control
        if (state.isPaused) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Packet analysis paused at segment ${state.currentSegmentIndex + 1}. Press resume to continue routing.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => state.resumeAnimation(),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Resume', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // OSI Model Layers Header
        _buildSectionHeader(context, label: 'OSI MODEL LAYERS', icon: Icons.layers_outlined),
        const SizedBox(height: 10),

        // OSI 7-Layer Stack
        _buildOsiStack(context),

        const SizedBox(height: 24),

        // Selected Layer Details
        _buildOsiDetailsPanel(context, pkt),
      ],
    );
  }

  Widget _buildOsiStack(BuildContext context) {
    return Column(
      children: [
        _buildOsiLayerRow(context, layer: 7, name: 'Application', isImplemented: false),
        _buildOsiLayerRow(context, layer: 6, name: 'Presentation', isImplemented: false),
        _buildOsiLayerRow(context, layer: 5, name: 'Session', isImplemented: false),
        _buildOsiLayerRow(context, layer: 4, name: 'Transport', isImplemented: false),
        _buildOsiLayerRow(context, layer: 3, name: 'Network', isImplemented: true, isActiveSimulation: true),
        _buildOsiLayerRow(context, layer: 2, name: 'Data Link', isImplemented: true),
        _buildOsiLayerRow(context, layer: 1, name: 'Physical', isImplemented: false),
      ],
    );
  }

  Widget _buildOsiLayerRow(
    BuildContext context, {
    required int layer,
    required String name,
    required bool isImplemented,
    bool isActiveSimulation = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final isSelected = _selectedOsiLayer == layer;

    // Cable highlight or text color styling
    Color outlineColor = Colors.transparent;
    if (isSelected) {
      outlineColor = AppColors.primaryAccent;
    } else if (isActiveSimulation) {
      outlineColor = AppColors.primaryAccent.withOpacity(0.5);
    }

    final boxBg = isSelected
        ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        : (isDark ? Colors.black12 : Colors.grey[100]!);

    final textCol = isImplemented
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : (isDark ? AppColors.darkTextSecondary.withOpacity(0.4) : AppColors.lightTextSecondary.withOpacity(0.4));

    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOsiLayer = layer;
          });
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: boxBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: outlineColor,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Row(
            children: [
              // Layer Badge
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActiveSimulation 
                      ? AppColors.primaryAccent 
                      : (isImplemented ? AppColors.secondaryAccent : Colors.grey[400]!.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'L$layer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Layer name text
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    decoration: isImplemented ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),

              // ACTIVE simulation marker
              if (isActiveSimulation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.primaryAccent, width: 0.5),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOsiDetailsPanel(BuildContext context, dynamic pkt) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (_selectedOsiLayer) {
      case 3:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LAYER 3 — NETWORK', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
              const SizedBox(height: 12),
              _buildValueDetails(context, 'Protocol', pkt.protocol),
              _buildValueDetails(context, 'Source IP', pkt.sourceIP),
              _buildValueDetails(context, 'Destination IP', pkt.destinationIP),
              _buildValueDetails(context, 'Layer Status', widget.state.isPaused ? 'PAUSED' : 'ACTIVE'),
              const Divider(height: 20),
              
              // Educational explanation
              Text(
                'Network Layer',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Uses IP addresses to identify the source and destination.',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LAYER 2 — DATA LINK', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondaryAccent)),
              const SizedBox(height: 12),
              _buildValueDetails(context, 'Source MAC', pkt.sourceMAC),
              _buildValueDetails(context, 'Destination MAC', pkt.destinationMAC),
              _buildValueDetails(context, 'Layer Status', 'AVAILABLE'),
              const Divider(height: 20),
              
              // Educational explanation
              Text(
                'Data Link Layer',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Uses MAC addresses to identify devices on the local network.',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        );
      default:
        // Inactive layers (7, 6, 5, 4, 1)
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAYER $_selectedOsiLayer — INACTIVE',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.canvasColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Not implemented in this simulation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildValueDetails(BuildContext context, String title, String val) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
          const SizedBox(height: 1),
          Text(
            val,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // View 2: Device Details View
  Widget _buildDeviceView(BuildContext context) {
    final dev = widget.state.selectedDevice!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, label: 'DEVICE PROPERTIES', icon: Icons.info_outline),
        const SizedBox(height: 16),
        _buildPropertyRow(context, 'Name', dev.name),
        _buildPropertyRow(context, 'Type', dev.type),
        
        // Editable IP Address Row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IP Address',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dev.ipAddress,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showEditIpDialog(context, dev);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: 'Edit IP Address',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),
            ],
          ),
        ),
        
        _buildPropertyRow(context, 'MAC Address', dev.macAddress),
        _buildPropertyRow(context, 'X Position', dev.x.toStringAsFixed(1)),
        _buildPropertyRow(context, 'Y Position', dev.y.toStringAsFixed(1)),
      ],
    );
  }

  void _showEditIpDialog(BuildContext context, Device dev) {
    final controller = TextEditingController(text: dev.ipAddress);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          title: Text(
            'Edit IP Address for ${dev.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: 'e.g. 192.168.1.10',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'IP address cannot be empty';
                }
                final parts = val.split('.');
                if (parts.length != 4) {
                  return 'Must be in IPv4 format (x.x.x.x)';
                }
                for (final part in parts) {
                  final n = int.tryParse(part);
                  if (n == null || n < 0 || n > 255) {
                    return 'Each octet must be between 0 and 255';
                  }
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  widget.state.updateDeviceIp(dev.id, controller.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // View 3: Connection Details View
  Widget _buildConnectionView(BuildContext context) {
    final conn = widget.state.selectedConnection!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final srcDev = widget.state.devices.firstWhere(
      (d) => d.id == conn.sourceDeviceId,
      orElse: () => Device(id: '', type: '', name: 'Unknown', x: 0, y: 0, ipAddress: '', macAddress: ''),
    );
    final destDev = widget.state.devices.firstWhere(
      (d) => d.id == conn.destinationDeviceId,
      orElse: () => Device(id: '', type: '', name: 'Unknown', x: 0, y: 0, ipAddress: '', macAddress: ''),
    );

    final isBroken = conn.status == 'broken';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, label: 'CONNECTION PROPERTIES', icon: Icons.cable_outlined),
        const SizedBox(height: 16),
        _buildPropertyRow(context, 'Cable ID', conn.id),
        _buildPropertyRow(context, 'Source Node', srcDev.name),
        _buildPropertyRow(context, 'Destination Node', destDev.name),
        _buildPropertyRow(
          context,
          'Status',
          conn.status.toUpperCase(),
          valueColor: isBroken ? AppColors.error : AppColors.success,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              widget.state.toggleConnectionStatus(conn.id);
            },
            icon: Icon(isBroken ? Icons.construction : Icons.content_cut),
            label: Text(isBroken ? 'Repair Connection' : 'Sever Cable (Break)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isBroken
                  ? (isDark ? AppColors.success : const Color(0xFF16A34A))
                  : (isDark ? AppColors.error : const Color(0xFFDC2626)),
              side: BorderSide(
                color: isBroken
                    ? (isDark ? AppColors.success : const Color(0xFF16A34A))
                    : (isDark ? AppColors.error : const Color(0xFFDC2626)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }

  // View 4: Default Placeholder View
  Widget _buildPlaceholderView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.mouse_outlined,
          size: 40,
          color: theme.dividerColor,
        ),
        const SizedBox(height: 16),
        Text(
          'No Selection',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.dividerColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a device or cable on the canvas to view parameters and physical layer details.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String label, required IconData icon}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.textTheme.bodyLarge?.color,
            ),
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }
}
