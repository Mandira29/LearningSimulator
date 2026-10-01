import 'package:flutter/material.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';

class SimulationControls extends StatelessWidget {
  final SimulatorState state;

  const SimulationControls({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 1,
    );

    // Filter list for dropdowns
    final deviceList = state.devices;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBg : AppColors.lightBg,
        border: Border(top: borderSide),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Source and Destination Selectors + Status Indicator
          Row(
            children: [
              // Source Dropdown
              const Text('Source: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildDropdown(
                context,
                value: state.sourceDeviceId.isEmpty ? null : state.sourceDeviceId,
                items: deviceList.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                hint: 'Choose Source',
                onChanged: state.isAnimating
                    ? null
                    : (val) {
                        if (val != null) state.setSourceDevice(val);
                      },
              ),
              const SizedBox(width: 24),

              // Destination Dropdown
              const Text('Destination: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildDropdown(
                context,
                value: state.destinationDeviceId.isEmpty ? null : state.destinationDeviceId,
                items: deviceList.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                hint: 'Choose Destination',
                onChanged: state.isAnimating
                    ? null
                    : (val) {
                        if (val != null) state.setDestinationDevice(val);
                      },
              ),

              const Spacer(),

              // Simulation Engine status
              _buildBackendStatus(context),
              const SizedBox(width: 24),

              // Simulation Status Label
              _buildStatusIndicator(context),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Row: Action Buttons
          Row(
            children: [
              // Connect (Cable Mode) Button
              ElevatedButton.icon(
                onPressed: state.isAnimating
                    ? null
                    : () {
                        state.toggleConnectionMode();
                      },
                icon: Icon(
                  state.connectionMode ? Icons.close : Icons.cable,
                  size: 18,
                ),
                label: Text(state.connectionMode ? 'Cancel Connect' : 'Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.connectionMode
                      ? AppColors.warning
                      : AppColors.secondaryAccent,
                  foregroundColor: const Color(0xFF0F172A),
                  disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),

              // Ping Button
              ElevatedButton.icon(
                onPressed: (state.sourceDeviceId.isEmpty || state.destinationDeviceId.isEmpty || state.connectionMode || state.isAnimating)
                    ? null
                    : () {
                        state.runPingSimulation();
                      },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Ping'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: const Color(0xFF0F172A),
                  disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),

              // Delete Selection Button
              OutlinedButton.icon(
                onPressed: (state.isAnimating || (state.selectedDevice == null && state.selectedConnection == null))
                    ? null
                    : () {
                        state.deleteSelected();
                      },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.error : const Color(0xFFDC2626),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  side: BorderSide(
                    color: (state.selectedDevice != null || state.selectedConnection != null) && !state.isAnimating
                        ? (isDark ? AppColors.error : const Color(0xFFDC2626))
                        : theme.dividerColor,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),

              // Reset Button
              OutlinedButton.icon(
                onPressed: state.isAnimating
                    ? null
                    : () {
                        if (state.activeLevelIndex != null) {
                          state.resetLevel();
                        } else {
                          state.clearCanvas();
                        }
                      },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.secondaryAccent : const Color(0xFF4F46E5),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),

              // Clear Button
              OutlinedButton.icon(
                onPressed: (state.devices.isEmpty || state.isAnimating)
                    ? null
                    : () {
                        state.clearCanvas();
                      },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),

              const Spacer(),

              // Feedback Text / Output Message
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.canvasColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    state.simulationMessage.isNotEmpty
                        ? state.simulationMessage
                        : (state.connectionMode
                            ? 'Connection Mode: Select first node'
                            : 'Status: Ready to simulate. Drag items to begin.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: onChanged == null ? theme.hintColor : null,
          ),
          onChanged: onChanged,
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: onChanged == null ? theme.hintColor : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBackendStatus(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = state.isBackendConnected;
    final color = isConnected ? AppColors.success : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Simulation Engine',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'Connected' : 'Offline',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    String statusText = 'READY';

    switch (state.simulationStatus) {
      case 'SUCCESS':
        statusColor = AppColors.success;
        statusText = '✓ PACKET DELIVERED';
        break;
      case 'FAILED':
        statusColor = AppColors.error;
        statusText = '✕ DELIVERY FAILED';
        break;
      case 'SIMULATING':
        statusColor = AppColors.primaryAccent;
        statusText = 'PACKET TRAVELLING';
        break;
      case 'READY':
      default:
        statusColor = theme.hintColor;
        statusText = 'READY';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
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
          statusText,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: statusColor,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
