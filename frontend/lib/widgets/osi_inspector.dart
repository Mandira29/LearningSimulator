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
  int _deviceInspectorTab = 0; // 0 = IP Config, 1 = CLI Terminal
  bool _wasAnimating = false;

  String? _lastInspectedDeviceId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _subnetController = TextEditingController();
  final TextEditingController _gatewayController = TextEditingController();

  final TextEditingController _cliInputController = TextEditingController();
  final ScrollController _cliScrollController = ScrollController();
  final Map<String, List<String>> _cliLogs = {};

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _cliInputController.dispose();
    _cliScrollController.dispose();
    super.dispose();
  }

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
      width: 330,
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
              _showPacketInfo() ? 'PACKET INSPECTOR' : 'NODE INSPECTOR',
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
        _buildSectionHeader(context, label: 'INTERACTIVE OSI MODEL LAYERS', icon: Icons.layers_outlined),
        const SizedBox(height: 6),
        Text(
          'Click any layer (L1–L7) to inspect header details below.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),

        // OSI 7-Layer Stack
        _buildOsiStack(context),

        const SizedBox(height: 20),

        // Selected Layer Details
        _buildOsiDetailsPanel(context, pkt),
      ],
    );
  }

  Widget _buildOsiStack(BuildContext context) {
    return Column(
      children: [
        _buildOsiLayerRow(context, layer: 7, name: 'Application', isImplemented: true),
        _buildOsiLayerRow(context, layer: 6, name: 'Presentation', isImplemented: true),
        _buildOsiLayerRow(context, layer: 5, name: 'Session', isImplemented: true),
        _buildOsiLayerRow(context, layer: 4, name: 'Transport', isImplemented: true),
        _buildOsiLayerRow(context, layer: 3, name: 'Network', isImplemented: true, isActiveSimulation: true),
        _buildOsiLayerRow(context, layer: 2, name: 'Data Link', isImplemented: true),
        _buildOsiLayerRow(context, layer: 1, name: 'Physical', isImplemented: true),
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

    Color outlineColor = Colors.transparent;
    if (isSelected) {
      outlineColor = AppColors.primaryAccent;
    } else if (isActiveSimulation) {
      outlineColor = AppColors.primaryAccent.withOpacity(0.5);
    }

    final boxBg = isSelected
        ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        : (isDark ? Colors.black12 : Colors.grey[100]!);

    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
                width: 24,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAccent
                      : (isActiveSimulation
                          ? AppColors.primaryAccent.withOpacity(0.8)
                          : AppColors.secondaryAccent.withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'L$layer',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
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

    final srcIp = pkt?.sourceIP ?? '192.168.1.10';
    final destIp = pkt?.destinationIP ?? '192.168.1.20';
    final srcMac = pkt?.sourceMAC ?? 'AA:AA:AA:00:00:0A';
    final destMac = pkt?.destinationMAC ?? 'BB:BB:BB:00:00:0B';
    final proto = pkt?.protocol ?? 'ICMP Echo';

    Widget panelContent;

    switch (_selectedOsiLayer) {
      case 7:
        panelContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYER 7 — APPLICATION', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
            const SizedBox(height: 10),
            _buildValueDetails(context, 'Application Protocol', 'ICMP Echo / HTTP 1.1'),
            _buildValueDetails(context, 'Payload Message', 'Ping Data: 32 Bytes (abcdefghijklmnopqrstuvw)'),
            _buildValueDetails(context, 'Message Type', 'Echo Request (Type 8, Code 0)'),
            _buildValueDetails(context, 'Application Status', 'Active Request Payload'),
            const Divider(height: 16),
            Text('Layer Description', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text('Provides network services directly to end-user applications and manages packet payload data.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        );
        break;
      case 6:
        panelContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYER 6 — PRESENTATION', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondaryAccent)),
            const SizedBox(height: 10),
            _buildValueDetails(context, 'Data Encoding', 'ASCII / UTF-8 Plaintext'),
            _buildValueDetails(context, 'Encryption', 'None (Plaintext ICMP Packet)'),
            _buildValueDetails(context, 'Compression', 'Disabled (Raw Binary Payload)'),
            _buildValueDetails(context, 'Structure Format', 'Standard ICMP Echo Packet Format'),
            const Divider(height: 16),
            Text('Layer Description', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
            const SizedBox(height: 4),
            Text('Translates, encrypts, and formats application data for transmission.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        );
        break;
      case 5:
        panelContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYER 5 — SESSION', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
            const SizedBox(height: 10),
            _buildValueDetails(context, 'Session ID', '0x7F4A2B90'),
            _buildValueDetails(context, 'Connection Mode', 'Full-Duplex (Ping Sequence #1)'),
            _buildValueDetails(context, 'Dialog Control', 'Request / Reply Synchronization'),
            _buildValueDetails(context, 'Session State', 'ESTABLISHED'),
            const Divider(height: 16),
            Text('Layer Description', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text('Establishes, maintains, and terminates communication sessions between endpoints.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        );
        break;
      case 4:
        panelContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYER 4 — TRANSPORT', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondaryAccent)),
            const SizedBox(height: 10),
            _buildValueDetails(context, 'Transport Protocol', proto),
            _buildValueDetails(context, 'Identifier / Port', 'Identifier: 0x0001 / Seq: 1'),
            _buildValueDetails(context, 'Checksum', '0x5E3D (Checksum Validated)'),
            _buildValueDetails(context, 'Flow Control', 'Stop-and-Wait ICMP Delivery'),
            const Divider(height: 16),
            Text('Layer Description', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
            const SizedBox(height: 4),
            Text('Ensures reliable end-to-end data transfer, flow control, and error recovery.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        );
        break;
      case 3:
        panelContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYER 3 — NETWORK', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
            const SizedBox(height: 10),
            _buildValueDetails(context, 'Protocol', 'IPv4'),
            _buildValueDetails(context, 'Source IP', srcIp),
            _buildValueDetails(context, 'Destination IP', destIp),
            _buildValueDetails(context, 'Time To Live (TTL)', '64 Hops'),
            _buildValueDetails(context, 'Header Checksum', '0x9A1B'),
            const Divider(height: 16),
            Text('Layer Description', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text('Uses IP addresses to route packets across logical network boundaries.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        );
        break;
      case 2:
        panelContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYER 2 — DATA LINK', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondaryAccent)),
            const SizedBox(height: 10),
            _buildValueDetails(context, 'Frame Format', 'Ethernet II Frame'),
            _buildValueDetails(context, 'Source MAC', srcMac),
            _buildValueDetails(context, 'Destination MAC', destMac),
            _buildValueDetails(context, 'EtherType', '0x0800 (IPv4 Payload)'),
            _buildValueDetails(context, 'FCS / CRC', '0x3F12A89C (Frame OK)'),
            const Divider(height: 16),
            Text('Layer Description', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
            const SizedBox(height: 4),
            Text('Uses physical MAC addresses for node-to-node frame delivery on local links.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        );
        break;
      case 1:
      default:
        panelContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYER 1 — PHYSICAL', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
            const SizedBox(height: 10),
            _buildValueDetails(context, 'Medium', 'Copper RJ-45 Category 6 UTP'),
            _buildValueDetails(context, 'Signal Format', 'NRZ Voltage Pulses (Electrical)'),
            _buildValueDetails(context, 'Link Speed', '1000 Mbps (Gigabit Ethernet)'),
            _buildValueDetails(context, 'Duplex Mode', 'Full-Duplex'),
            _buildValueDetails(context, 'Preamble / SFD', '10101010...10101011 (Synced)'),
            const Divider(height: 16),
            Text('Layer Description', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text('Transmits unstructured raw bit streams over a physical communications medium.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor),
      ),
      child: panelContent,
    );
  }

  Widget _buildValueDetails(BuildContext context, String title, String val) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          Text(
            val,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 12.0,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // View 2: Detailed Interactive Node Inspector (PC, Switch, Router)
  Widget _buildDeviceView(BuildContext context) {
    final dev = widget.state.selectedDevice!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sync input fields when selected device changes
    if (_lastInspectedDeviceId != dev.id) {
      _lastInspectedDeviceId = dev.id;
      _nameController.text = dev.name;
      _ipController.text = dev.ipAddress;
      _subnetController.text = dev.subnetMask;
      _gatewayController.text = dev.defaultGateway;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Node Header Banner
        Row(
          children: [
            Icon(
              dev.type == 'PC'
                  ? Icons.computer
                  : (dev.type == 'ROUTER' ? Icons.router : Icons.swap_horiz),
              size: 24,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${dev.type} Node • Link Active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Navigation Tabs: IP Configuration vs CLI Terminal
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _deviceInspectorTab = 0;
                    });
                  },
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _deviceInspectorTab == 0
                          ? AppColors.primaryAccent
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                    ),
                    child: Text(
                      'IP CONFIG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _deviceInspectorTab == 0
                            ? const Color(0xFF0F172A)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _deviceInspectorTab = 1;
                    });
                  },
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _deviceInspectorTab == 1
                          ? AppColors.primaryAccent
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                    ),
                    child: Text(
                      'CLI TERMINAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _deviceInspectorTab == 1
                            ? const Color(0xFF0F172A)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Body Content depending on Tab
        if (_deviceInspectorTab == 0)
          _buildIpConfigPanel(context, dev)
        else
          _buildCliTerminalView(context, dev),
      ],
    );
  }

  // IP Configuration Form Panel
  Widget _buildIpConfigPanel(BuildContext context, Device dev) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPortUp = dev.portStatus.toLowerCase() == 'up';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Port Administrative State Toggle
        _buildSectionHeader(context, label: 'PORT ADMINISTRATIVE STATE', icon: Icons.power_settings_new),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isPortUp
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPortUp
                  ? AppColors.success.withOpacity(0.4)
                  : AppColors.error.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPortUp ? Icons.check_circle_outline : Icons.highlight_off,
                size: 20,
                color: isPortUp ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interface eth0: ${isPortUp ? "UP / ENABLED" : "DOWN / SHUTDOWN"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPortUp ? AppColors.success : AppColors.error,
                      ),
                    ),
                    Text(
                      isPortUp
                          ? 'Interface is actively forwarding packets.'
                          : 'Interface is administratively shut down (drops packets).',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isPortUp,
                activeThumbColor: AppColors.success,
                inactiveThumbColor: AppColors.error,
                onChanged: (val) {
                  widget.state.togglePortStatus(dev.id);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),

        _buildSectionHeader(context, label: 'NETWORK CONFIGURATION', icon: Icons.settings_ethernet),
        const SizedBox(height: 12),

        // Device Name
        _buildInputField(
          context,
          label: 'Device Name',
          controller: _nameController,
          hint: 'e.g. PC1',
        ),
        const SizedBox(height: 10),

        // IPv4 Address
        _buildInputField(
          context,
          label: 'IP Address (IPv4)',
          controller: _ipController,
          hint: 'e.g. 192.168.1.10',
          isMonospace: true,
        ),
        const SizedBox(height: 10),

        // Subnet Mask
        _buildInputField(
          context,
          label: 'Subnet Mask',
          controller: _subnetController,
          hint: 'e.g. 255.255.255.0',
          isMonospace: true,
        ),
        const SizedBox(height: 10),

        // Default Gateway
        _buildInputField(
          context,
          label: 'Default Gateway',
          controller: _gatewayController,
          hint: 'e.g. 192.168.1.1',
          isMonospace: true,
        ),
        const SizedBox(height: 12),

        // MAC Address Info Box
        Text('Hardware Address (MAC)', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            dev.macAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              widget.state.updateDeviceConfig(
                dev.id,
                name: _nameController.text.trim(),
                ipAddress: _ipController.text.trim(),
                subnetMask: _subnetController.text.trim(),
                defaultGateway: _gatewayController.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Configuration saved for ${dev.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save Configuration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // Quick Ping Actions
        _buildSectionHeader(context, label: 'SIMULATION SHORTCUTS', icon: Icons.send),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => widget.state.setSourceDevice(dev.id),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(
                    color: widget.state.sourceDeviceId == dev.id
                        ? AppColors.primaryAccent
                        : theme.dividerColor,
                  ),
                ),
                child: Text(
                  widget.state.sourceDeviceId == dev.id ? '✓ Source Set' : 'Set as Source',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => widget.state.setDestinationDevice(dev.id),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(
                    color: widget.state.destinationDeviceId == dev.id
                        ? AppColors.secondaryAccent
                        : theme.dividerColor,
                  ),
                ),
                child: Text(
                  widget.state.destinationDeviceId == dev.id ? '✓ Dest Set' : 'Set as Dest',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _deviceInspectorTab = 1;
              });
            },
            icon: const Icon(Icons.terminal, size: 16),
            label: const Text('Launch CLI Terminal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Interactive CLI Terminal View
  Widget _buildCliTerminalView(BuildContext context, Device dev) {
    final logs = _getDeviceCliLog(dev);
    final prompt = _getPromptPrefix(dev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, label: 'COMMAND LINE INTERFACE', icon: Icons.terminal),
        const SizedBox(height: 8),

        // Terminal Console Window
        Container(
          height: 280,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Dark terminal background
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: [
              // Terminal Log Viewport
              Expanded(
                child: ListView.builder(
                  controller: _cliScrollController,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final line = logs[index];
                    Color lineCol = const Color(0xFF38BDF8); // Sky blue text
                    if (line.startsWith('C:\\') || line.startsWith('Router') || line.startsWith('Switch')) {
                      lineCol = const Color(0xFF22C55E); // Green prompt lines
                    } else if (line.contains('timed out') || line.contains('unreachable') || line.contains('not recognized')) {
                      lineCol = const Color(0xFFEF4444); // Red errors
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: SelectableText(
                        line,
                        style: TextStyle(
                          color: lineCol,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Color(0xFF334155), height: 12),

              // Interactive Command Prompt Line
              Row(
                children: [
                  Text(
                    '$prompt ',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _cliInputController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      cursorColor: const Color(0xFF38BDF8),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'type ping, ipconfig, arp -a, help...',
                        hintStyle: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                      onSubmitted: (val) {
                        _executeCliCommand(dev, val);
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _executeCliCommand(dev, _cliInputController.text),
                    icon: const Icon(Icons.send, size: 14, color: Color(0xFF38BDF8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: Type "ping PC2" or "ipconfig" into the terminal.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  List<String> _getDeviceCliLog(Device dev) {
    if (!_cliLogs.containsKey(dev.id)) {
      _cliLogs[dev.id] = [
        'NetVisual Academy CLI Shell [Version 1.0.0]',
        'Connected to ${dev.name} (${dev.type}). Type "help" for commands.\n',
      ];
    }
    return _cliLogs[dev.id]!;
  }

  String _getPromptPrefix(Device dev) {
    if (dev.type == 'ROUTER') return '${dev.name}#';
    if (dev.type == 'SWITCH') return '${dev.name}>';
    return 'C:\\Users\\${dev.name}>';
  }

  void _executeCliCommand(Device dev, String commandStr) {
    final cmd = commandStr.trim();
    if (cmd.isEmpty) return;

    final logs = _getDeviceCliLog(dev);
    final prompt = _getPromptPrefix(dev);
    logs.add('$prompt $cmd');

    final parts = cmd.split(RegExp(r'\s+'));
    final mainCmd = parts[0].toLowerCase();
    final args = parts.sublist(1);

    if (mainCmd == 'clear' || mainCmd == 'cls') {
      logs.clear();
      logs.add('Terminal screen cleared.\n');
    } else if (mainCmd == 'help') {
      logs.add('Available Commands:');
      logs.add('  ping <target>       - Test ICMP ping connectivity to IP or device name');
      logs.add('  ipconfig / ifconfig - Display IP configuration details');
      logs.add('  arp -a / show arp   - View ARP address resolution table');
      logs.add('  tracert <target>    - Trace packet hops across network');
      logs.add('  clear / cls         - Clear terminal screen\n');
    } else if (mainCmd == 'ipconfig' || mainCmd == 'ifconfig' || (mainCmd == 'show' && args.isNotEmpty && args[0].toLowerCase() == 'ip')) {
      logs.add('${dev.name} Network Configuration:');
      logs.add('   Host Name . . . . . . . . . : ${dev.name}');
      logs.add('   Node Type . . . . . . . . . : ${dev.type}');
      logs.add('   IPv4 Address. . . . . . . . : ${dev.ipAddress}');
      logs.add('   Subnet Mask . . . . . . . . : ${dev.subnetMask}');
      logs.add('   Default Gateway . . . . . . : ${dev.defaultGateway}');
      logs.add('   Physical MAC. . . . . . . . : ${dev.macAddress}');
      logs.add('   Link Status . . . . . . . . : UP (1000 Mbps Full Duplex)\n');
    } else if (mainCmd == 'arp' || (mainCmd == 'show' && args.isNotEmpty && args[0].toLowerCase() == 'arp')) {
      logs.add('Interface: ${dev.ipAddress} --- 0x1');
      logs.add('  Internet Address      Physical Address      Type');
      for (final other in widget.state.devices) {
        if (other.id != dev.id) {
          logs.add('  ${other.ipAddress.padRight(21)} ${other.macAddress.padRight(21)} dynamic');
        }
      }
      logs.add('');
    } else if (mainCmd == 'ping') {
      if (args.isEmpty) {
        logs.add('Usage: ping <ip_address_or_device_name>\n');
      } else {
        final targetStr = args[0];
        final targetDev = widget.state.devices.firstWhere(
          (d) => d.ipAddress == targetStr || d.name.toLowerCase() == targetStr.toLowerCase(),
          orElse: () => Device(id: '', type: '', name: '', x: 0, y: 0, ipAddress: '', macAddress: ''),
        );

        if (targetDev.id.isEmpty) {
          logs.add('Ping request could not find host $targetStr. Please check the name or IP.\n');
        } else if (targetDev.id == dev.id) {
          logs.add('Pinging self (${dev.ipAddress}):');
          logs.add('Reply from ${dev.ipAddress}: bytes=32 time<1ms TTL=128');
          logs.add('Reply from ${dev.ipAddress}: bytes=32 time<1ms TTL=128');
          logs.add('Ping statistics for ${dev.ipAddress}: Sent = 2, Received = 2, Lost = 0 (0% loss).\n');
        } else {
          final hasPath = _checkPathExists(dev.id, targetDev.id);
          logs.add('Pinging ${targetDev.name} [${targetDev.ipAddress}] with 32 bytes of data:');
          if (hasPath) {
            logs.add('Reply from ${targetDev.ipAddress}: bytes=32 time=1ms TTL=64');
            logs.add('Reply from ${targetDev.ipAddress}: bytes=32 time=1ms TTL=64');
            logs.add('Reply from ${targetDev.ipAddress}: bytes=32 time=1ms TTL=64');
            logs.add('Reply from ${targetDev.ipAddress}: bytes=32 time=1ms TTL=64');
            logs.add('Ping statistics for ${targetDev.ipAddress}:');
            logs.add('    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss).\n');
          } else {
            logs.add('Request timed out.');
            logs.add('Request timed out.');
            logs.add('Destination host unreachable.');
            logs.add('Ping statistics for ${targetDev.ipAddress}:');
            logs.add('    Packets: Sent = 3, Received = 0, Lost = 3 (100% loss).\n');
          }
        }
      }
    } else if (mainCmd == 'tracert' || mainCmd == 'traceroute') {
      if (args.isEmpty) {
        logs.add('Usage: tracert <ip_address_or_device_name>\n');
      } else {
        final targetStr = args[0];
        final targetDev = widget.state.devices.firstWhere(
          (d) => d.ipAddress == targetStr || d.name.toLowerCase() == targetStr.toLowerCase(),
          orElse: () => Device(id: '', type: '', name: '', x: 0, y: 0, ipAddress: '', macAddress: ''),
        );

        if (targetDev.id.isEmpty) {
          logs.add('Unable to resolve target system name $targetStr.\n');
        } else {
          logs.add('Tracing route to ${targetDev.name} [${targetDev.ipAddress}] over a maximum of 30 hops:');
          logs.add('  1    1 ms    1 ms    1 ms  ${dev.ipAddress} [Source]');
          final hasPath = _checkPathExists(dev.id, targetDev.id);
          if (hasPath) {
            logs.add('  2    2 ms    1 ms    2 ms  ${targetDev.ipAddress} [${targetDev.name}]');
            logs.add('Trace complete.\n');
          } else {
            logs.add('  2    *       *       *     Request timed out.');
            logs.add('Trace complete (destination unreachable).\n');
          }
        }
      }
    } else {
      logs.add('"$cmd" is not recognized as an internal command. Type "help" for a list of commands.\n');
    }

    _cliInputController.clear();
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cliScrollController.hasClients) {
        _cliScrollController.animateTo(
          _cliScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _checkPathExists(String sourceId, String destId) {
    final connections = widget.state.connections;
    for (final c in connections) {
      if (c.status == 'broken') continue;
      if ((c.sourceDeviceId == sourceId && c.destinationDeviceId == destId) ||
          (c.sourceDeviceId == destId && c.destinationDeviceId == sourceId)) {
        return true;
      }
    }
    for (final c1 in connections) {
      if (c1.status == 'broken') continue;
      final mid = c1.sourceDeviceId == sourceId ? c1.destinationDeviceId : (c1.destinationDeviceId == sourceId ? c1.sourceDeviceId : null);
      if (mid != null) {
        for (final c2 in connections) {
          if (c2.status == 'broken') continue;
          if ((c2.sourceDeviceId == mid && c2.destinationDeviceId == destId) ||
              (c2.destinationDeviceId == mid && c2.sourceDeviceId == destId)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isMonospace = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12.5,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
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
    final currentType = conn.cableType;

    // Check cable validity
    final validity = _checkCableValidity(srcDev.type, destDev.type, currentType);
    final isValidCable = validity['isValid'] as bool;
    final validationMsg = validity['message'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, label: 'CONNECTION PROPERTIES', icon: Icons.cable_outlined),
        const SizedBox(height: 12),
        _buildPropertyRow(context, 'Link', '${srcDev.name} (${srcDev.type}) ↔ ${destDev.name} (${destDev.type})'),
        _buildPropertyRow(
          context,
          'Physical Status',
          isBroken ? 'BROKEN / SEVERED' : 'ACTIVE LINK',
          valueColor: isBroken ? AppColors.error : AppColors.success,
        ),
        const SizedBox(height: 12),

        // Cable Compatibility Diagnostic Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBroken
                ? AppColors.error.withOpacity(0.1)
                : (isValidCable ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isBroken
                  ? AppColors.error.withOpacity(0.4)
                  : (isValidCable ? AppColors.success.withOpacity(0.4) : AppColors.warning.withOpacity(0.5)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isBroken ? Icons.broken_image : (isValidCable ? Icons.check_circle : Icons.warning_amber_rounded),
                size: 20,
                color: isBroken ? AppColors.error : (isValidCable ? AppColors.success : AppColors.warning),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBroken
                          ? 'CABLE PHYSICAL SEVER'
                          : (isValidCable ? 'CORRECT CABLE TYPE' : 'INCORRECT CABLE TYPE'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isBroken ? AppColors.error : (isValidCable ? AppColors.success : AppColors.warning),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBroken ? 'Cable is severed. Toggle physical link below.' : validationMsg,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // Hands-On Cable Type Selector
        _buildSectionHeader(context, label: 'HANDS-ON CABLE REPLACEMENT', icon: Icons.build_outlined),
        const SizedBox(height: 6),
        Text(
          'Click a cable type below to manually replace the cable:',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),

        _buildCableOptionTile(
          context,
          typeKey: 'straight_through',
          label: 'Straight-Through Cable',
          subtitle: 'PC ↔ Switch / Router ↔ Switch',
          icon: Icons.linear_scale,
          isSelected: currentType == 'straight_through',
          onTap: () => widget.state.updateConnectionCableType(conn.id, 'straight_through'),
        ),
        _buildCableOptionTile(
          context,
          typeKey: 'crossover',
          label: 'Crossover Cable',
          subtitle: 'PC ↔ PC / Switch ↔ Switch',
          icon: Icons.alt_route,
          isSelected: currentType == 'crossover',
          onTap: () => widget.state.updateConnectionCableType(conn.id, 'crossover'),
        ),
        _buildCableOptionTile(
          context,
          typeKey: 'console',
          label: 'Console Cable (Serial)',
          subtitle: 'CLI Terminal Management Only',
          icon: Icons.settings_input_component,
          isSelected: currentType == 'console',
          onTap: () => widget.state.updateConnectionCableType(conn.id, 'console'),
        ),
        _buildCableOptionTile(
          context,
          typeKey: 'fiber',
          label: 'Fiber Optic Cable',
          subtitle: 'High-Speed Switch ↔ Router',
          icon: Icons.bolt,
          isSelected: currentType == 'fiber',
          onTap: () => widget.state.updateConnectionCableType(conn.id, 'fiber'),
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              widget.state.toggleConnectionStatus(conn.id);
            },
            icon: Icon(isBroken ? Icons.construction : Icons.content_cut),
            label: Text(isBroken ? 'Repair Physical Link' : 'Sever Cable (Break)'),
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

  Map<String, dynamic> _checkCableValidity(String srcType, String destType, String cableType) {
    final t1 = srcType.toUpperCase();
    final t2 = destType.toUpperCase();
    final c = cableType.toLowerCase();

    if (c == 'console') {
      return {
        'isValid': false,
        'message': 'Console cable provides CLI access only and cannot transmit IP packet data.',
      };
    }
    if (t1 == 'PC' && t2 == 'PC') {
      if (c == 'crossover') return {'isValid': true, 'message': '✓ Crossover Cable is correct for direct PC to PC link.'};
      return {'isValid': false, 'message': '✕ Incorrect Cable! Direct PC to PC link requires a Crossover Cable.'};
    }
    if ((t1 == 'PC' && t2 == 'SWITCH') || (t1 == 'SWITCH' && t2 == 'PC')) {
      if (c == 'straight_through') return {'isValid': true, 'message': '✓ Straight-Through Cable is correct for PC to Switch.'};
      return {'isValid': false, 'message': '✕ Incorrect Cable! PC to Switch connection requires a Straight-Through Cable.'};
    }
    if (t1 == 'SWITCH' && t2 == 'SWITCH') {
      if (c == 'crossover' || c == 'fiber') return {'isValid': true, 'message': '✓ $cableType is valid for Switch to Switch uplink.'};
      return {'isValid': false, 'message': '✕ Incorrect Cable! Switch to Switch requires a Crossover or Fiber Cable.'};
    }
    if (t1 == 'ROUTER' && t2 == 'ROUTER') {
      if (c == 'crossover' || c == 'fiber') return {'isValid': true, 'message': '✓ $cableType is valid for Router to Router link.'};
      return {'isValid': false, 'message': '✕ Incorrect Cable! Router to Router requires a Crossover or Fiber Cable.'};
    }
    if ((t1 == 'ROUTER' && t2 == 'SWITCH') || (t1 == 'SWITCH' && t2 == 'ROUTER')) {
      if (c == 'straight_through' || c == 'fiber') return {'isValid': true, 'message': '✓ $cableType is valid for Router to Switch link.'};
      return {'isValid': false, 'message': '✕ Incorrect Cable! Router to Switch requires a Straight-Through or Fiber Cable.'};
    }
    if ((t1 == 'PC' && t2 == 'ROUTER') || (t1 == 'ROUTER' && t2 == 'PC')) {
      if (c == 'crossover' || c == 'fiber') return {'isValid': true, 'message': '✓ $cableType is valid for direct PC to Router link.'};
      return {'isValid': false, 'message': '✕ Incorrect Cable! Direct PC to Router link requires a Crossover Cable.'};
    }
    return {'isValid': true, 'message': '✓ Cable type accepted.'};
  }

  Widget _buildCableOptionTile(
    BuildContext context, {
    required String typeKey,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryAccent.withOpacity(0.12)
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.primaryAccent : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primaryAccent : theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primaryAccent
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.radio_button_checked,
                  size: 16,
                  color: AppColors.primaryAccent,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  size: 16,
                  color: theme.dividerColor,
                ),
            ],
          ),
        ),
      ),
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
          'Select a device (PC, Switch, Router) or cable on the canvas to configure IP settings, run CLI commands, or inspect OSI protocol layers.',
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
