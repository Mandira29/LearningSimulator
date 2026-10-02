import 'package:flutter/material.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';
import '../widgets/post_lab_quiz_modal.dart';

class TroubleshootingScreen extends StatelessWidget {
  final SimulatorState state;

  const TroubleshootingScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header Block & Time Attack Controls
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHALLENGES & TROUBLESHOOTING LAB',
                      style: textTheme.displayLarge?.copyWith(
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Master the simulator interface. Complete challenges, diagnose faults, and earn XP.',
                      style: textTheme.headlineMedium?.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                // Time Attack & Post-Lab Quiz Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // Time Attack Button
                    ElevatedButton.icon(
                      onPressed: () {
                        if (state.timeAttackActive) {
                          state.stopTimeAttack();
                        } else {
                          state.startTimeAttack();
                        }
                      },
                      icon: Icon(
                        state.timeAttackActive ? Icons.timer_off : Icons.timer,
                        size: 18,
                      ),
                      label: Text(
                        state.timeAttackActive
                            ? '⏱️ Time Attack: ${state.timeAttackSeconds}s'
                            : '⚡ Start Time Attack Mode',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.timeAttackActive ? AppColors.warning : AppColors.secondaryAccent,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    // Post-Lab Quiz Modal Button
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => PostLabQuizModal(
                            onQuizCompleted: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Post-Lab Quiz passed! +100 XP awarded!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.quiz, size: 18),
                      label: const Text('Post-Lab Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Level List Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 750;
                final levelCards = [
                  _buildLevelCard(
                    context,
                    levelIndex: 1,
                    title: 'Getting started',
                    difficulty: 'Basic',
                    rewardXp: 100,
                    description: 'Welcome to the first level! Learn the simulator interface: restart, pause, inspect computer ownership and packet paths, and craft and dispatch new packets.',
                  ),
                  _buildLevelCard(
                    context,
                    levelIndex: 2,
                    title: 'Broken Cable',
                    difficulty: 'Beginner',
                    rewardXp: 100,
                    description: 'A cable in the local topology is severed. Diagnose which link is faulty, repair the connection, and test it with a Ping.',
                  ),
                  _buildLevelCard(
                    context,
                    levelIndex: 3,
                    title: 'Incorrect IP',
                    difficulty: 'Beginner',
                    rewardXp: 100,
                    description: 'A device is configured with an incorrect IP address on a different subnet prefix. Identify the conflict, update the IP, and verify the path.',
                  ),
                  _buildLevelCard(
                    context,
                    levelIndex: 4,
                    title: 'Port Down',
                    difficulty: 'Intermediate',
                    rewardXp: 150,
                    description: 'A network interface is administratively shut down (DOWN). Inspect port states in the node properties and re-enable it.',
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: levelCards.map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: card,
                    )).toList(),
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: levelCards[0]),
                          const SizedBox(width: 20),
                          Expanded(child: levelCards[1]),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: levelCards[2]),
                          const SizedBox(width: 20),
                          Expanded(child: levelCards[3]),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 40),

            // Gameplay Instructions
            Card(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'HOW TO PLAY',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepRow(context, '1', 'Select a Level above and click "Start Level".'),
                    const SizedBox(height: 12),
                    _buildStepRow(context, '2', 'Inspect the device properties and connections on the canvas.'),
                    const SizedBox(height: 12),
                    _buildStepRow(context, '3', 'Locate the issue (e.g., a broken cable or subnet mismatch).'),
                    const SizedBox(height: 12),
                    _buildStepRow(context, '4', 'Repair the cable or edit the device IP address, then hit "Ping".'),
                    const SizedBox(height: 12),
                    _buildStepRow(context, '5', 'Once the packet is successfully delivered, you solve the level!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
          child: Text(
            number,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required int levelIndex,
    required String title,
    required String difficulty,
    required int rewardXp,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isCompleted = state.completedDbLevels.containsKey(levelIndex);
    final int stars = isCompleted ? (state.completedDbLevels[levelIndex]?['stars'] as int? ?? 3) : 0;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCompleted ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Level $levelIndex',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.success, width: 1),
                        ),
                        child: Text(
                          'Completed ✓ (${"⭐" * stars})',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    difficulty,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Reward: $rewardXp XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    state.startLevel(levelIndex);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
