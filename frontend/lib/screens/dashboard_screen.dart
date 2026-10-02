import 'package:flutter/material.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final SimulatorState state;
  final VoidCallback onOpenSimulatorPressed;
  final VoidCallback onTroubleshootingLabPressed;
  final VoidCallback? onOpenModulesPressed;
  final VoidCallback? onOpenPacketJourneyPressed;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onOpenSimulatorPressed,
    required this.onTroubleshootingLabPressed,
    this.onOpenModulesPressed,
    this.onOpenPacketJourneyPressed,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _loadAnimationController;

  @override
  void initState() {
    super.initState();
    _loadAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _loadAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final int completedCount = (widget.state.dbStats?['completed_levels_count'] as int?) ?? widget.state.completedDbLevels.length;
    final int totalXp = (widget.state.dbStats?['total_xp'] as int?) ?? 0;
    final int packetsTraced = (widget.state.dbStats?['total_packets_traced'] as int?) ?? 0;
    final int streakDays = packetsTraced > 0 ? (packetsTraced % 7 + 1) : 3;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP WELCOME HEADER
            StaggeredFadeSlide(
              controller: _loadAnimationController,
              index: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Welcome back, User',
                            style: textTheme.displayLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: AppColors.success),
                                SizedBox(width: 5),
                                Text(
                                  'SQLite DB Connected',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NetVisual Academy • Interactive Learning Dashboard',
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Student XP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          '$totalXp XP',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. CONTINUE LEARNING HERO CARD
            StaggeredFadeSlide(
              controller: _loadAnimationController,
              index: 1,
              child: ModernHoverCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CONTINUE LEARNING',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warning, width: 0.8),
                          ),
                          child: const Text('Intermediate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lab 2: Subnetting & IP Gateway Routing',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar: 55% · ~12 min left
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: 0.55,
                              minHeight: 10,
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '55%  ·  ~12 min left',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ScaleButton(
                        onPressed: widget.onTroubleshootingLabPressed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, color: Color(0xFF0F172A), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Resume Lab',
                                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. ROW OF 3 QUICK METRIC CARDS
            StaggeredFadeSlide(
              controller: _loadAnimationController,
              index: 2,
              child: Row(
                children: [
                  Expanded(child: _buildMetricTile(context, 'Labs Completed', '$completedCount/4', Icons.task_alt, AppColors.success)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMetricTile(context, 'Streak', '$streakDays days 🔥', Icons.local_fire_department, Colors.orange)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMetricTile(context, 'Total XP', '$totalXp XP', Icons.bolt, Colors.amber)),
                ],
              ),
            ),
            const SizedBox(height: 24),



            // 5. NEW · PACKET JOURNEY BANNER
            StaggeredFadeSlide(
              controller: _loadAnimationController,
              index: 4,
              child: ModernHoverCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PACKET JOURNEY',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 15,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Watch a packet travel through the 7 OSI layers in real time.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Layer Sequence Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLayerChip('L7', const Color(0xFFE11D48)),
                          _buildArrow(),
                          _buildLayerChip('L6', const Color(0xFFA855F7)),
                          _buildArrow(),
                          _buildLayerChip('L5', const Color(0xFF6366F1)),
                          _buildArrow(),
                          _buildLayerChip('L4', const Color(0xFFF59E0B)),
                          _buildArrow(),
                          _buildLayerChip('L3', AppColors.primaryAccent),
                          _buildArrow(),
                          _buildLayerChip('L2', AppColors.secondaryAccent),
                          _buildArrow(),
                          _buildLayerChip('L1', AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ScaleButton(
                        onPressed: () {
                          if (widget.onOpenPacketJourneyPressed != null) {
                            widget.onOpenPacketJourneyPressed!();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF0F172A)),
                              SizedBox(width: 6),
                              Text(
                                'See it in action',
                                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 6. BOTTOM 3-WIDGET GRID (Quiz + Leaderboard + Latest Badge)
            StaggeredFadeSlide(
              controller: _loadAnimationController,
              index: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  if (isNarrow) {
                    return Column(
                      children: [
                        DailyQuizCard(onLaunchPressed: widget.onTroubleshootingLabPressed),
                        const SizedBox(height: 16),
                        _buildLeaderboardWidget(context, totalXp),
                        const SizedBox(height: 16),
                        _buildBadgeWidget(context, totalXp),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: DailyQuizCard(onLaunchPressed: widget.onTroubleshootingLabPressed)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLeaderboardWidget(context, totalXp)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBadgeWidget(context, totalXp)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Metric Tile Widget ---
  Widget _buildMetricTile(BuildContext context, String label, String value, IconData icon, Color color) {
    return ModernHoverCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }



  Widget _buildLayerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.0),
      child: Text('▸', style: TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }

  // --- Bottom Leaderboard Widget ---
  Widget _buildLeaderboardWidget(BuildContext context, int userXp) {
    final theme = Theme.of(context);

    return ModernHoverCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_outlined, size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                'TOP 3 LEADERBOARD',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildRankRow('🥇 #1', 'Alex Chen', '1,450 XP', Colors.amber),
              const SizedBox(height: 4),
              _buildRankRow('🥈 #2', 'Sarah Jenkins', '1,280 XP', const Color(0xFF94A3B8)),
              const SizedBox(height: 4),
              _buildRankRow('🥉 #3', 'You (Current User)', '$userXp XP', const Color(0xFFCD7F32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(String rank, String name, String xp, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          Text(xp, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // --- Bottom Badge Widget ---
  Widget _buildBadgeWidget(BuildContext context, int userXp) {
    final theme = Theme.of(context);

    return ModernHoverCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_outlined, size: 16, color: AppColors.secondaryAccent),
              const SizedBox(width: 6),
              Text(
                'LATEST BADGE',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.secondaryAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryAccent, width: 1.5),
                ),
                child: const Icon(Icons.military_tech, color: AppColors.secondaryAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userXp >= 200 ? 'Subnet Master' : 'Cable Technician',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userXp >= 200 ? 'Mastered CIDR masks' : 'Completed initial labs in DB',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER ANIMATION & WIDGET COMPONENTS
// ============================================================================
class ModernHoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ModernHoverCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  State<ModernHoverCard> createState() => _ModernHoverCardState();
}

class _ModernHoverCardState extends State<ModernHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -3.0 : 0.0, 0.0),
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHovered
                ? AppColors.primaryAccent.withValues(alpha: 0.8)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: isDark ? 0.25 : 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class StaggeredFadeSlide extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const StaggeredFadeSlide({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double start = (index * 0.12).clamp(0.0, 0.7);
    final double end = (start + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: widget.child,
        ),
      ),
    );
  }
}

class DailyQuizCard extends StatefulWidget {
  final VoidCallback onLaunchPressed;

  const DailyQuizCard({super.key, required this.onLaunchPressed});

  @override
  State<DailyQuizCard> createState() => _DailyQuizCardState();
}

class _DailyQuizCardState extends State<DailyQuizCard> {
  int? _selectedOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      '255.255.255.224 (/27)',
      '255.255.255.192 (/26)',
      '255.255.255.240 (/28)',
      '255.255.255.0 (/24)',
    ];

    return ModernHoverCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'QUIZ OF THE DAY',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '+50 XP',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Which subnet mask yields 30 usable host IPs for network 192.168.1.0?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(options.length, (idx) {
              final isSelected = _selectedOption == idx;
              return ChoiceChip(
                label: Text(options[idx], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : null)),
                selected: isSelected,
                selectedColor: AppColors.primaryAccent,
                onSelected: (sel) {
                  setState(() {
                    _selectedOption = sel ? idx : null;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ScaleButton(
              onPressed: () {
                if (_selectedOption == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Correct! 255.255.255.224 yields 30 host IPs (+50 XP)!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  widget.onLaunchPressed();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Submit Answer',
                  style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
