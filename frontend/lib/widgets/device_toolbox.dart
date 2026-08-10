import 'package:flutter/material.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';

class DeviceToolbox extends StatelessWidget {
  final SimulatorState state;

  const DeviceToolbox({
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

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBg : AppColors.lightBg,
        border: Border(right: borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Device Toolbox',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildToolboxItem(
                  context,
                  type: 'PC',
                  label: 'End device',
                  icon: Icons.computer,
                ),
                const SizedBox(height: 16),
                _buildToolboxItem(
                  context,
                  type: 'SWITCH',
                  label: 'Connects devices',
                  icon: Icons.swap_horiz_outlined,
                ),
                const SizedBox(height: 16),
                _buildToolboxItem(
                  context,
                  type: 'ROUTER',
                  label: 'Connects networks',
                  icon: Icons.router_outlined,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Tip: Drag devices onto the workspace, or click them to place at the center.',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolboxItem(
    BuildContext context, {
    required String type,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final boxDecoration = BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    );

    final itemWidget = Container(
      decoration: boxDecoration,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: AppColors.primaryAccent,
          ),
          const SizedBox(height: 8),
          Text(
            type,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: SizedBox(
            width: 140,
            child: itemWidget,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: itemWidget,
      ),
      child: InkWell(
        onTap: () {
          // Fallback click action: place at center of canvas
          state.addDevice(type, 350.0, 200.0);
        },
        borderRadius: BorderRadius.circular(6),
        child: itemWidget,
      ),
    );
  }
}
