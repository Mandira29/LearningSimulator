import 'dart:math';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/connection.dart';
import '../models/challenge.dart';
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

                // 8. Challenge System HUD overlay
                if (state.activeChallenge != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildChallengeHUD(context),
                  ),

                // 9. Victory Overlay Card
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
      final obj = state.level1Objectives;
      final completedCount = state.level1CompletedCount;

      return Card(
        color: isDark ? AppColors.darkSurface.withOpacity(0.96) : AppColors.lightSurface.withOpacity(0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        margin: EdgeInsets.zero,
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Title, Progress Badge, Reward XP, Exit Button
              Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Basic level: Getting started',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Progress counter badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (completedCount == 6 ? AppColors.success : AppColors.secondaryAccent).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (completedCount == 6 ? AppColors.success : AppColors.secondaryAccent).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      '$completedCount / 6 Objectives',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: completedCount == 6 ? AppColors.success : AppColors.secondaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => state.exitLevel(),
                    icon: const Icon(Icons.exit_to_app, size: 18),
                    tooltip: 'Exit Level',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Action buttons row: Prominent Restart button in top left (Objective 1) & Pause button (Objective 2)
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => state.restartSimulationOver(),
                    icon: const Icon(Icons.restart_alt, size: 15),
                    label: const Text('Restart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryAccent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (state.isPaused) {
                        state.resumeAnimation();
                      } else {
                        state.pauseAnimation();
                      }
                    },
                    icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause, size: 15),
                    label: Text(
                      state.isPaused ? 'Resume' : 'Pause',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: state.isPaused ? AppColors.success : AppColors.warning,
                      side: BorderSide(color: state.isPaused ? AppColors.success : AppColors.warning),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Level introduction narrative
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to the first level!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use this level to get used to the simulator interface.\n\nClick on a computer to view information about who owns it. You can also pause the simulation and click on a packet to see where it is going and who it is coming from.\n\nPausing and restarting often is the key to success in this game! It allows you to slow down and see how things work.\n\nFollow the steps below to complete this level.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Level Objectives',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Objectives Checklist rendered as clean column
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildObjectiveChip(
                    context,
                    number: '1',
                    text: 'Use the restart button in the top left to start the simulation over',
                    isDone: obj['restart'] ?? false,
                  ),
                  const SizedBox(height: 6),
                  _buildObjectiveChip(
                    context,
                    number: '2',
                    text: 'Pause the simulation',
                    isDone: obj['pause'] ?? false,
                  ),
                  const SizedBox(height: 6),
                  _buildObjectiveChip(
                    context,
                    number: '3',
                    text: 'Click on a computer to see its properties',
                    isDone: obj['inspect_pc'] ?? false,
                  ),
                  const SizedBox(height: 6),
                  _buildObjectiveChip(
                    context,
                    number: '4',
                    text: 'Click on a packet (the circles) to see its properties',
                    isDone: obj['inspect_packet'] ?? false,
                  ),
                  const SizedBox(height: 6),
                  _buildObjectiveChip(
                    context,
                    number: '5',
                    text: 'Click the + button and add a new packet (you can leave the properties blank for now!)',
                    isDone: obj['add_packet'] ?? false,
                  ),
                  const SizedBox(height: 6),
                  _buildObjectiveChip(
                    context,
                    number: '6',
                    text: 'Click the send arrow beside the packet you just added!',
                    isDone: obj['send_packet'] ?? false,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (levelIdx == 2) {
      title = 'Level 2: Broken Cable';
      goal = 'Goal: Restore communication between PC1 and PC2.';
      hints = [
        'Check the connections between the devices. Some might be broken.',
        'Select the broken red cable and click \'Repair Connection\' in the inspector.'
      ];
    } else if (levelIdx == 3) {
      title = 'Level 3: Incorrect IP';
      goal = 'Goal: Correct the IP subnet prefix mismatch for PC2.';
      hints = [
        'Look at the IP addresses of PC1 and PC2. Do they share the same subnet prefix?',
        'Select PC2, click its IP address in the properties panel to edit it, and change it to 192.168.1.20.'
      ];
    } else if (levelIdx == 4) {
      title = 'Level 4: Interface Port DOWN';
      goal = 'Goal: Re-enable the shut down network interface on PC2.';
      hints = [
        'Check the port status badge on PC2 or inspect its IP Configuration.',
        'Select PC2 and toggle interface eth0 from DOWN to UP.'
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

  Widget _buildObjectiveChip(
    BuildContext context, {
    required String number,
    required String text,
    required bool isDone,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success.withOpacity(0.12)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDone ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isDone ? AppColors.success : theme.hintColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$number. $text',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                color: isDone
                    ? AppColors.success
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Challenge System HUD Overlay
  // =========================================================================

  Widget _buildChallengeHUD(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ch = state.activeChallenge!;
    final isCompleted = ch.status == ChallengeStatus.completed;

    return Card(
      color: isDark ? AppColors.darkSurface.withOpacity(0.96) : AppColors.lightSurface.withOpacity(0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCompleted ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      margin: EdgeInsets.zero,
      elevation: 6,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Icon(ch.category.icon, size: 20, color: ch.category.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Challenge ${ch.number.toString().padLeft(2, '0')}: ${ch.title}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ch.category.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ch.category.shortName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: ch.category.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success, width: 1),
                        ),
                        child: const Text(
                          'Completed ✓',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),

                    // Reset Challenge button
                    IconButton(
                      onPressed: () => state.resetActiveChallenge(),
                      icon: const Icon(Icons.refresh, size: 16),
                      tooltip: 'Reset Challenge',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    // Exit Challenge button
                    IconButton(
                      onPressed: () => state.exitChallenge(),
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Exit to Challenges Menu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Objective Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Text(
                    '🎯 Objective: ${ch.learningObjective}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Interactive Challenge-Specific Controls Row
                _buildChallengeActionControls(context, ch),
                const SizedBox(height: 8),

                // Hints Row
                Row(
                  children: [
                    if (state.challengeHintsUsed < ch.hints.length)
                      TextButton.icon(
                        onPressed: () => state.showNextChallengeHint(),
                        icon: const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.warning),
                        label: Text(
                          state.challengeHintsUsed == 0 ? 'Show Hint' : 'Show Next Hint',
                          style: const TextStyle(fontSize: 11, color: AppColors.warning),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (state.challengeHintsUsed > 0) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '💡 Hint: ${ch.hints[state.challengeHintsUsed - 1]}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                // Victory Card on Completion
                if (isCompleted) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '✓ Challenge Completed! +150 XP Awarded',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ch.explanation,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (ch.number < 12) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final nextId = 'ch${(ch.number + 1).toString().padLeft(2, '0')}';
                              state.startChallenge(nextId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('Next →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeActionControls(BuildContext context, Challenge ch) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (ch.id) {
      case 'ch01':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('send_packet', {
                'sourceDeviceId': 'pc_alice',
                'destinationDeviceId': 'pc_bob',
                'sourceIP': '192.168.1.10',
                'destinationIP': '192.168.1.20',
              }),
              icon: const Icon(Icons.send, size: 14),
              label: const Text('Send Alice → Bob (Inspect IP Fields)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: const Color(0xFF0F172A)),
            ),
          ],
        );

      case 'ch02':
        final currentPings = ch.progress['pingsCompleted'] as int? ?? 0;
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('send_ping'),
              icon: const Icon(Icons.repeat, size: 14),
              label: Text('Send ICMP Echo Ping ($currentPings / 5)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: const Color(0xFF0F172A)),
            ),
            Text(
              'Echo Requests: $currentPings of 5 delivered',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        );

      case 'ch03':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('route_packet', {
                'sourceDeviceId': 'pc_bob',
                'destinationDeviceId': 'pc_carol',
              }),
              icon: const Icon(Icons.alt_route, size: 14),
              label: const Text('Route Bob → Carol (via Router A & C)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: const Color(0xFF0F172A)),
            ),
          ],
        );

      case 'ch04':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('send_through_modem', {'sourceDeviceId': 'pc_alice'}),
              icon: const Icon(Icons.settings_input_antenna, size: 14),
              label: const Text('Send Alice Ping via Modem NAT (192.168.1.10 → 203.0.113.5)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: const Color(0xFF0F172A)),
            ),
            OutlinedButton.icon(
              onPressed: () => state.executeChallengeAction('send_through_modem', {'sourceDeviceId': 'pc_bob'}),
              icon: const Icon(Icons.settings_input_antenna, size: 14),
              label: const Text('Send Bob Ping via Modem NAT (192.168.1.20 → 203.0.113.5)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        );

      case 'ch05':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('send_spoofed', {
                'sourceDeviceId': 'pc_alice',
                'destinationDeviceId': 'pc_bob',
                'spoofedSourceIP': '192.168.1.30',
              }),
              icon: const Icon(Icons.vpn_key, size: 14),
              label: const Text('Send Spoofed Packet (Actual: Alice, Header: Carol 192.168.1.30)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: const Color(0xFF0F172A)),
            ),
          ],
        );

      case 'ch06':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('divert_traffic'),
              icon: const Icon(Icons.swap_calls, size: 14),
              label: const Text('Simulate MAC CAM Poisoning & Divert Bob\'s Packets to Carol', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: const Color(0xFF0F172A)),
            ),
          ],
        );

      case 'ch07':
        final traffic = ch.progress['trafficGenerated'] ?? 0;
        final status = ch.progress['serverStatus'] ?? 'Normal';
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('generate_traffic', {'packetCount': 25}),
              icon: const Icon(Icons.bolt, size: 14),
              label: const Text('Generate Traffic Burst (25 packets)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            ),
            Text(
              'Server Load: $traffic / 20 pkts (Status: $status)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: status == 'OVERLOADED' ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        );

      case 'ch08':
        final total = ch.progress['totalTraffic'] ?? 0;
        final status = ch.progress['serverStatus'] ?? 'Normal';
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('send_ddos_burst', {
                'aliceTraffic': 8,
                'bobTraffic': 7,
                'carolTraffic': 9,
                'daveTraffic': 6,
              }),
              icon: const Icon(Icons.flash_on, size: 14),
              label: const Text('Trigger All Botnet Endpoints (Total: 30 pkts)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            ),
            Text(
              'Aggregated Load: $total / 20 pkts (Status: $status)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: status == 'OVERLOADED' ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        );

      case 'ch09':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('smurf_broadcast', {
                'destinationIP': '255.255.255.255',
                'sourceIP': '8.8.8.8',
              }),
              icon: const Icon(Icons.campaign, size: 14),
              label: const Text('Broadcast Echo Request (Spoofed Source: 8.8.8.8)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            ),
          ],
        );

      case 'ch10':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('send_mitm_packet', {'encrypted': false}),
              icon: const Icon(Icons.lock_open, size: 14),
              label: const Text('Send Plaintext HTTP (Eve Reads & Tampered)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: const Color(0xFF0F172A)),
            ),
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('send_mitm_packet', {'encrypted': true}),
              icon: const Icon(Icons.lock, size: 14),
              label: const Text('Send Encrypted TLS/HTTPS (Eve Cannot Read)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: const Color(0xFF0F172A)),
            ),
          ],
        );

      case 'ch11':
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('request_site', {'useProxy': false}),
              icon: const Icon(Icons.block, size: 14),
              label: const Text('Direct: Alice → Blocked Site (Expect Drop)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () => state.executeChallengeAction('request_site', {'useProxy': true}),
              icon: const Icon(Icons.vpn_lock, size: 14),
              label: const Text('Tunnel: Alice → Proxy Server → Blocked Site', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
            ),
          ],
        );

      case 'ch12':
        final currentTtl = ch.progress['currentTTL'] as int? ?? 1;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Set Probe TTL: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ...[1, 2, 3, 4, 5].map((ttlVal) {
              final isTarget = currentTtl == ttlVal;
              return ElevatedButton(
                onPressed: () => state.executeChallengeAction('traceroute_probe', {'ttl': ttlVal}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTarget ? const Color(0xFF10B981) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  foregroundColor: isTarget ? const Color(0xFF0F172A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: Text('TTL=$ttlVal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              );
            }),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
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
                    if ((state.activeLevelIndex ?? 0) < 4) ...[
                      ElevatedButton(
                        onPressed: () {
                          final currentLvl = state.activeLevelIndex ?? 1;
                          state.startLevel(currentLvl + 1);
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

    final isPaused = state.isPaused;
    final activeLayer = state.currentActiveOsiLayer;
    final phaseLabel = state.currentEncapsulationPhase;

    String layerBadge = 'L$activeLayer';
    Color badgeBg = AppColors.primaryAccent;
    if (activeLayer == 7) {
      layerBadge = 'L7 App';
      badgeBg = const Color(0xFFE11D48);
    } else if (activeLayer == 4) {
      layerBadge = 'L4 Trans';
      badgeBg = const Color(0xFFF59E0B);
    } else if (activeLayer == 3) {
      layerBadge = 'L3 Net (IP)';
      badgeBg = AppColors.primaryAccent;
    } else if (activeLayer == 2) {
      layerBadge = 'L2 Link (MAC)';
      badgeBg = AppColors.secondaryAccent;
    } else if (activeLayer == 1) {
      layerBadge = 'L1 Physical Bits';
      badgeBg = AppColors.success;
    }

    return Positioned(
      left: packetX - 80,
      top: packetY - 45,
      child: SizedBox(
        width: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Live Layer Tag Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPaused ? AppColors.warning : badgeBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isPaused ? AppColors.warning : badgeBg).withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaused ? Icons.pause_circle_filled : Icons.motion_photos_on,
                    size: 11,
                    color: const Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$layerBadge • $phaseLabel',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Circular animated packet node
            GestureDetector(
              onTap: () {
                state.inspectPacketCircle();
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: isPaused
                      ? 'Click to Resume Animation'
                      : 'Click Packet to Pause & Inspect Layer 2 (MAC) & Layer 3 (IP) Data',
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isPaused ? AppColors.warning : badgeBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: (isPaused ? AppColors.warning : badgeBg).withValues(alpha: 0.8),
                          blurRadius: 12,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isPaused ? Icons.pause : Icons.send,
                        size: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    if (t1 == 'MODEM' || t2 == 'MODEM') return true;
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
    switch (dev.type.toUpperCase()) {
      case 'PC':
        devIcon = Icons.computer;
        break;
      case 'SWITCH':
        devIcon = Icons.swap_horiz;
        break;
      case 'ROUTER':
        devIcon = Icons.router;
        break;
      case 'MODEM':
        devIcon = Icons.settings_input_antenna;
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

