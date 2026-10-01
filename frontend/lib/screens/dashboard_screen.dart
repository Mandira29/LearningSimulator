import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenSimulatorPressed;
  final VoidCallback onTroubleshootingLabPressed;

  const DashboardScreen({
    super.key,
    required this.onOpenSimulatorPressed,
    required this.onTroubleshootingLabPressed,
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
            // Title & Subtitle Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NETVISUAL ACADEMY',
                  style: textTheme.displayLarge?.copyWith(
                    letterSpacing: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn networking by seeing it.',
                  style: textTheme.headlineMedium?.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Text(
                    'Visualize network topologies, follow packets, and understand the OSI model interactively.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Hero Animation Section
            const AnimatedHeroTopology(),
            const SizedBox(height: 40),

            // Main Columns
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;

                final actionsColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'QUICK ACTIONS',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            title: 'Open Simulator',
                            icon: Icons.settings_ethernet,
                            color: AppColors.primaryAccent,
                            onPressed: onOpenSimulatorPressed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            title: 'Troubleshooting Lab',
                            icon: Icons.build_outlined,
                            color: AppColors.secondaryAccent,
                            onPressed: onTroubleshootingLabPressed,
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                final statsColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ACADEMY PROGRESS & STATS',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildStatItem(context, 'Simulations', '12', Icons.hub_outlined),
                            const Divider(height: 24),
                            _buildStatItem(context, 'Troubleshooting Levels', '2', Icons.task_alt),
                            const Divider(height: 24),
                            _buildStatItem(context, 'Learning Progress', '75%', Icons.school_outlined),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      actionsColumn,
                      const SizedBox(height: 32),
                      statsColumn,
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: actionsColumn),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: statsColumn),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isDark
        ? color
        : (color == AppColors.primaryAccent
            ? const Color(0xFF0284C7)
            : const Color(0xFF4F46E5));

    return SizedBox(
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          foregroundColor: accentColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: accentColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class AnimatedHeroTopology extends StatefulWidget {
  const AnimatedHeroTopology({super.key});

  @override
  State<AnimatedHeroTopology> createState() => _AnimatedHeroTopologyState();
}

class _AnimatedHeroTopologyState extends State<AnimatedHeroTopology> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'LIVE PACKET VISUALIZER PREVIEW',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 70,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Connection line
                    Positioned(
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 2.5,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    // Nodes
                    Positioned(
                      left: 0,
                      child: _buildHeroNode(context, Icons.computer, 'PC', AppColors.primaryAccent),
                    ),
                    Positioned(
                      left: (width - 70) / 2,
                      child: _buildHeroNode(context, Icons.swap_horiz, 'Switch', AppColors.secondaryAccent),
                    ),
                    Positioned(
                      right: 0,
                      child: _buildHeroNode(context, Icons.router, 'Router', AppColors.primaryAccent),
                    ),
                    // Animating Packet dot
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final val = _controller.value;
                        final double startX = 40.0;
                        final double endX = width - 40.0;
                        final double x = startX + (endX - startX) * val;
                        return Positioned(
                          left: x - 6,
                          top: 8,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success,
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PACKET',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroNode(BuildContext context, IconData icon, String label, Color accentColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: accentColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
