import 'dart:math';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/connection.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';

class NetworkCanvas extends StatelessWidget {
  final SimulatorState state;

  const NetworkCanvas({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data.isNotEmpty && !state.isAnimating, // Disable drops during animation
      onAcceptWithDetails: (details) {
        if (state.isAnimating) return;

        final renderBox = context.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(details.offset);
        final x = max(20.0, min(localPos.dx - 40, renderBox.size.width - 100));
        final y = max(20.0, min(localPos.dy - 40, renderBox.size.height - 100));
        
        state.addDevice(details.data, x, y);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            if (state.isAnimating) return;
            state.deselectAll();
          },
          child: Container(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // 1. Grid Background
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(isDark: isDark),
                  ),
                ),

                // 2. Cables Layer (drawn only if devices are present)
                if (state.devices.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CablePainter(
                        devices: state.devices,
                        connections: state.connections,
                        selectedConnection: state.selectedConnection,
                        activeConnectionId: state.activeConnectionId,
                        isDark: isDark,
                      ),
                    ),
                  ),

                // 3. Clickable Cable Midpoints
                if (state.devices.isNotEmpty)
                  ...state.connections.map((conn) => _buildCableMidpoint(context, conn)),

                // 4. Travelling Packet Node (drawn over connections but under devices)
                if (state.isAnimating && state.currentFromDevice != null && state.currentToDevice != null)
                  _buildPacketNode(context),

                // 5. Devices Layer
                if (state.devices.isNotEmpty)
                  ...state.devices.map((dev) => _buildDeviceNode(context, dev)),

                // 6. Empty State Overlay
                if (state.devices.isEmpty)
                  Positioned.fill(child: _buildEmptyState(context)),

                // 7. Troubleshooting Level HUD overlay
                if (state.activeLevelIndex != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildLevelHUD(context),
                  ),

                // 8. Victory Overlay Card
                if (state.levelCompleted)
                  Positioned.fill(child: _buildVictoryOverlay(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hub_outlined,
            size: 60,
            color: isDark ? AppColors.darkTextSecondary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No devices yet',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag or select a device from the toolbox to begin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddShortcutButton(context, 'PC', Icons.computer),
              const SizedBox(width: 12),
              _buildAddShortcutButton(context, 'Switch', Icons.swap_horiz_outlined),
              const SizedBox(width: 12),
              _buildAddShortcutButton(context, 'Router', Icons.router_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddShortcutButton(BuildContext context, String type, IconData icon) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: () {
        // Place in center area of canvas (approximately x=300, y=180)
        state.addDevice(type.toUpperCase(), 300, 180);
      },
      icon: Icon(icon, size: 16),
      label: Text('Add $type', style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildLevelHUD(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final levelIdx = state.activeLevelIndex!;
    String title = '';
    String goal = '';
    List<String> hints = [];

    if (levelIdx == 1) {
      title = 'Level 1: Broken Cable';
      goal = 'Goal: Restore communication between PC1 and PC2.';
      hints = [
        'Check the connections between the devices. Some might be broken.',
        'Select the broken red cable and click \'Repair Connection\' in the inspector.'
      ];
    } else if (levelIdx == 2) {
      title = 'Level 2: Incorrect IP';
      goal = 'Goal: Correct the IP subnet prefix mismatch for PC2.';
      hints = [
        'Look at the IP addresses of PC1 and PC2. Do they share the same subnet prefix?',
        'Select PC2, click its IP address in the properties panel to edit it, and change it to 192.168.1.20.'
      ];
    }

    return Card(
      color: isDark ? AppColors.darkSurface.withOpacity(0.95) : AppColors.lightSurface.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      margin: EdgeInsets.zero,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level title + XP + Exit
            Row(
              children: [
                Icon(Icons.assignment_outlined, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Reward: ${state.levelXp} XP',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => state.exitLevel(),
                  icon: const Icon(Icons.exit_to_app, size: 18),
                  tooltip: 'Exit Level',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              goal,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const Divider(height: 16),

            // Hint panel
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need help?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.hintsUsed == 0)
                        ElevatedButton.icon(
                          onPressed: () => state.showNextHint(),
                          icon: const Icon(Icons.lightbulb_outline, size: 14),
                          label: const Text('Show Hint (-25 XP)', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      if (state.hintsUsed > 0) ...[
                        Text(
                          'Hint 1: ${hints[0]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 11.5,
                          ),
                        ),
                        if (state.hintsUsed == 1) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => state.showNextHint(),
                            icon: const Icon(Icons.lightbulb_outline, size: 14),
                            label: const Text('Show Next Hint (-25 XP)', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ],
                      ],
                      if (state.hintsUsed == 2) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Hint 2: ${hints[1]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: Colors.black54, // Dim background
      alignment: Alignment.center,
      child: Card(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 2),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  '✓ NETWORK FIXED',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You successfully restored communication between the devices.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${state.levelXp} XP Earned',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.activeLevelIndex == 1) ...[
                      ElevatedButton(
                        onPressed: () {
                          state.startLevel(2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Next Level', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                    ],
                    OutlinedButton(
                      onPressed: () => state.exitLevel(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        side: BorderSide(color: theme.dividerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Back to Lab', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Renders the traveling data packet node on the canvas
  Widget _buildPacketNode(BuildContext context) {
    final from = state.currentFromDevice!;
    final to = state.currentToDevice!;
    final t = state.animationProgress;

    // Device center offsets (nodes are 80x80 widgets, so offset by 40)
    final double srcCenterX = from.x + 40;
    final double srcCenterY = from.y + 40;
    final double destCenterX = to.x + 40;
    final double destCenterY = to.y + 40;

    final double packetX = srcCenterX + (destCenterX - srcCenterX) * t;
    final double packetY = srcCenterY + (destCenterY - srcCenterY) * t;

    return Positioned(
      left: packetX - 12,
      top: packetY - 12,
      child: GestureDetector(
        onTap: () {
          if (state.isPaused) {
            state.resumeAnimation();
          } else {
            state.pauseAnimation();
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withOpacity(state.isPaused ? 0.4 : 0.8),
                  blurRadius: 10,
                  spreadRadius: 3,
                )
              ],
            ),
            child: Center(
              child: Icon(
                state.isPaused ? Icons.play_arrow : Icons.pause,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCableMidpoint(BuildContext context, Connection conn) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final src = state.devices.firstWhere((d) => d.id == conn.sourceDeviceId, orElse: () => Device(id: '', type: '', name: '', x: 0, y: 0, ipAddress: '', macAddress: ''));
    final dest = state.devices.firstWhere((d) => d.id == conn.destinationDeviceId, orElse: () => Device(id: '', type: '', name: '', x: 0, y: 0, ipAddress: '', macAddress: ''));

    if (src.id.isEmpty || dest.id.isEmpty) return const SizedBox.shrink();

    final double srcCenterX = src.x + 40;
    final double srcCenterY = src.y + 40;
    final double destCenterX = dest.x + 40;
    final double destCenterY = dest.y + 40;

    final double midX = (srcCenterX + destCenterX) / 2;
    final double midY = (srcCenterY + destCenterY) / 2;

    final isSelected = state.selectedConnection?.id == conn.id;
    final isBroken = conn.status == 'broken';
    final isValidCable = _isCableValidForPair(src.type, dest.type, conn.cableType);

    Color handleColor;
    IconData handleIcon;

    if (isBroken) {
      handleColor = AppColors.error;
      handleIcon = Icons.warning_amber_rounded;
    } else if (!isValidCable) {
      handleColor = AppColors.warning;
      handleIcon = Icons.error_outline;
    } else if (isSelected) {
      handleColor = AppColors.primaryAccent;
      handleIcon = Icons.lan;
    } else {
      switch (conn.cableType) {
        case 'crossover':
          handleColor = const Color(0xFF3B82F6); // Blue
          handleIcon = Icons.alt_route;
          break;
        case 'console':
          handleColor = const Color(0xFF38BDF8); // Cyan
          handleIcon = Icons.settings_input_component;
          break;
        case 'fiber':
          handleColor = const Color(0xFFF59E0B); // Amber
          handleIcon = Icons.bolt;
          break;
        case 'straight_through':
        default:
          handleColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          handleIcon = Icons.linear_scale;
          break;
      }
    }

    return Positioned(
      left: midX - 16,
      top: midY - 16,
      child: GestureDetector(
        onTap: state.isAnimating ? null : () {
          state.selectConnection(conn.id);
        },
        child: MouseRegion(
          cursor: state.isAnimating ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: handleColor,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: (isSelected || !isValidCable)
                  ? [
                      BoxShadow(
                        color: handleColor.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              handleIcon,
              size: 16,
              color: handleColor,
            ),
          ),
        ),
      ),
    );
  }

  bool _isCableValidForPair(String srcType, String destType, String cableType) {
    final t1 = srcType.toUpperCase();
    final t2 = destType.toUpperCase();
    final c = cableType.toLowerCase();

    if (c == 'console') return false;
    if (t1 == 'PC' && t2 == 'PC') return c == 'crossover';
    if ((t1 == 'PC' && t2 == 'SWITCH') || (t1 == 'SWITCH' && t2 == 'PC')) return c == 'straight_through';
    if (t1 == 'SWITCH' && t2 == 'SWITCH') return c == 'crossover' || c == 'fiber';
    if (t1 == 'ROUTER' && t2 == 'ROUTER') return c == 'crossover' || c == 'fiber';
    if ((t1 == 'ROUTER' && t2 == 'SWITCH') || (t1 == 'SWITCH' && t2 == 'ROUTER')) return c == 'straight_through' || c == 'fiber';
    if ((t1 == 'PC' && t2 == 'ROUTER') || (t1 == 'ROUTER' && t2 == 'PC')) return c == 'crossover' || c == 'fiber';
    return true;
  }

  Widget _buildDeviceNode(BuildContext context, Device dev) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final isSelected = state.selectedDevice?.id == dev.id;
    final isPendingConnection = state.firstSelectedDeviceForConnection?.id == dev.id;
    final isPortDown = dev.portStatus.toLowerCase() == 'down';

    IconData devIcon;
    switch (dev.type) {
      case 'PC':
        devIcon = Icons.computer;
        break;
      case 'SWITCH':
        devIcon = Icons.swap_horiz;
        break;
      case 'ROUTER':
        devIcon = Icons.router;
        break;
      default:
        devIcon = Icons.device_unknown;
        break;
    }

    Color outlineColor = Colors.transparent;
    if (isPortDown) {
      outlineColor = AppColors.error;
    } else if (isSelected) {
      outlineColor = AppColors.primaryAccent;
    } else if (isPendingConnection) {
      outlineColor = AppColors.warning;
    } else if (state.sourceDeviceId == dev.id) {
      outlineColor = AppColors.success;
    } else if (state.destinationDeviceId == dev.id) {
      outlineColor = AppColors.error;
    }

    return Positioned(
      left: dev.x,
      top: dev.y,
      child: GestureDetector(
        onTap: () {
          // Device selection is locked if simulating unless connection mode is active
          if (state.isAnimating) return;
          state.selectDevice(dev.id);
        },
        onPanUpdate: state.isAnimating ? null : (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          final double newX = max(10.0, min(dev.x + details.delta.dx, renderBox.size.width - 90));
          final double newY = max(10.0, min(dev.y + details.delta.dy, renderBox.size.height - 90));
          state.moveDevice(dev.id, newX, newY);
        },
        child: MouseRegion(
          cursor: state.isAnimating ? SystemMouseCursors.basic : SystemMouseCursors.move,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: outlineColor != Colors.transparent
                            ? outlineColor
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: outlineColor != Colors.transparent ? 2.5 : 1,
                      ),
                      boxShadow: (isSelected || isPendingConnection || isPortDown)
                          ? [
                              BoxShadow(
                                color: outlineColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          devIcon,
                          size: 34,
                          color: isPortDown
                              ? AppColors.error.withOpacity(0.7)
                              : (outlineColor != Colors.transparent ? outlineColor : AppColors.primaryAccent),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dev.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Port Administrative Status DOWN Badge
                  if (isPortDown)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'DOWN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSecondaryBg : AppColors.lightBg).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  dev.ipAddress,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Painters
class GridPainter extends CustomPainter {
  final bool isDark;

  GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? AppColors.darkBorder.withOpacity(0.15)
          : AppColors.lightBorder.withOpacity(0.3)
      ..strokeWidth = 1.0;

    const double gridSize = 40.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}

class CablePainter extends CustomPainter {
  final List<Device> devices;
  final List<Connection> connections;
  final Connection? selectedConnection;
  final String? activeConnectionId;
  final bool isDark;

  CablePainter({
    required this.devices,
    required this.connections,
    required this.selectedConnection,
    required this.activeConnectionId,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      final src = devices.firstWhere((d) => d.id == conn.sourceDeviceId, orElse: () => Device(id: '', type: '', name: '', x: 0, y: 0, ipAddress: '', macAddress: ''));
      final dest = devices.firstWhere((d) => d.id == conn.destinationDeviceId, orElse: () => Device(id: '', type: '', name: '', x: 0, y: 0, ipAddress: '', macAddress: ''));

      if (src.id.isEmpty || dest.id.isEmpty) continue;

      final srcCenter = Offset(src.x + 40, src.y + 40);
      final destCenter = Offset(dest.x + 40, dest.y + 40);

      final isSelected = selectedConnection?.id == conn.id;
      final isHighlighted = activeConnectionId == conn.id;
      final isBroken = conn.status == 'broken';

      Color cableColor;
      double strokeWidth = 2.5;

      if (isBroken) {
        cableColor = AppColors.error;
      } else if (isHighlighted) {
        cableColor = AppColors.primaryAccent;
        strokeWidth = 5.0;
      } else if (isSelected) {
        cableColor = AppColors.primaryAccent;
        strokeWidth = 3.5;
      } else {
        switch (conn.cableType) {
          case 'crossover':
            cableColor = const Color(0xFF3B82F6); // Blue for Crossover
            break;
          case 'console':
            cableColor = const Color(0xFF38BDF8); // Sky blue for Serial Console
            break;
          case 'fiber':
            cableColor = const Color(0xFFF59E0B); // Amber Yellow for Fiber
            strokeWidth = 3.0;
            break;
          case 'straight_through':
          default:
            cableColor = isDark ? AppColors.secondaryAccent : AppColors.lightTextSecondary;
            break;
        }
      }

      final paint = Paint()
        ..color = cableColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      if (isBroken) {
        _drawDashedLine(canvas, srcCenter, destCenter, paint, dashWidth: 8.0, dashSpace: 6.0);
      } else if (conn.cableType == 'crossover') {
        _drawDashedLine(canvas, srcCenter, destCenter, paint, dashWidth: 10.0, dashSpace: 5.0);
      } else if (conn.cableType == 'console') {
        _drawDashedLine(canvas, srcCenter, destCenter, paint, dashWidth: 4.0, dashSpace: 4.0);
      } else {
        canvas.drawLine(srcCenter, destCenter, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {double dashWidth = 8.0, double dashSpace = 6.0}) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final double step = dashWidth + dashSpace;
    final int numDashes = (distance / step).floor();

    for (int i = 0; i < numDashes; i++) {
      final double startFraction = (i * step) / distance;
      final double endFraction = (i * step + dashWidth) / distance;

      canvas.drawLine(
        Offset(p1.dx + dx * startFraction, p1.dy + dy * startFraction),
        Offset(p1.dx + dx * min(1.0, endFraction), p1.dy + dy * min(1.0, endFraction)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CablePainter oldDelegate) => true;
}

