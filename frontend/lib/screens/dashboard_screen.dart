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
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Header Section
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
                      'NETVISUAL ACADEMY',
                      style: textTheme.displayLarge?.copyWith(
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Learn networking by seeing it.',
                      style: textTheme.headlineMedium?.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                // Quick Nav Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onOpenSimulatorPressed,
                      icon: const Icon(Icons.settings_ethernet, size: 18),
                      label: const Text('Open Simulator'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onTroubleshootingLabPressed,
                      icon: const Icon(Icons.build_outlined, size: 18),
                      label: const Text('Troubleshooting Lab'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryAccent,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 1. CONTINUE LAST LAB PREVIEW CARD
            ContinueLastLabCard(onResumePressed: onTroubleshootingLabPressed),
            const SizedBox(height: 28),

            // 2. STATS ROW: Radial Progress Ring + GitHub Activity Heatmap + Network Counters
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1100;
                if (isNarrow) {
                  return Column(
                    children: [
                      _buildRadialProgressCard(context),
                      const SizedBox(height: 16),
                      _buildActivityHeatmapCard(context),
                      const SizedBox(height: 16),
                      _buildNetworkStatsCounters(context),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildRadialProgressCard(context)),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: _buildActivityHeatmapCard(context)),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: _buildNetworkStatsCounters(context)),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 28),

            // 3. MIDDLE ROW: Daily Challenge + Leaderboard / Peer Rank + Latest Earned Badge
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1100;
                if (isNarrow) {
                  return Column(
                    children: [
                      DailyChallengeWidget(onLaunchPressed: onTroubleshootingLabPressed),
                      const SizedBox(height: 16),
                      _buildLeaderboardCard(context),
                      const SizedBox(height: 16),
                      _buildLatestBadgeCard(context),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: DailyChallengeWidget(onLaunchPressed: onTroubleshootingLabPressed)),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: _buildLeaderboardCard(context)),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: _buildLatestBadgeCard(context)),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 28),

            // 4. BOTTOM SECTION: Course Modules List with Status Tags, Difficulty & Estimated Times
            _buildCourseModulesSection(context),
          ],
        ),
      ),
    );
  }

  // --- Radial / Circular Progress Ring Card ---
  Widget _buildRadialProgressCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 18, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              Text(
                'ACADEMY COMPLETION',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Radial Progress Ring
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 8,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    ),
                    Center(
                      child: Text(
                        '75%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 of 4 Modules Completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep practicing to master subnetting & dynamic routing.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
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

  // --- Weekly Activity Heatmap (GitHub Style Grid) ---
  Widget _buildActivityHeatmapCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<List<int>> activityGrid = [
      [1, 2, 3, 0, 2, 3, 1],
      [2, 3, 1, 2, 3, 0, 2],
      [0, 1, 2, 3, 3, 2, 1],
      [3, 2, 3, 3, 2, 3, 3],
    ];

    Color getCellColor(int level) {
      if (level == 0) return isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
      if (level == 1) return const Color(0xFF064E3B);
      if (level == 2) return const Color(0xFF047857);
      return AppColors.success;
    }

    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.grid_on_outlined, size: 18, color: AppColors.secondaryAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PRACTICE CONSISTENCY',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥 ', style: TextStyle(fontSize: 12)),
                    Text(
                      '5 Day Streak',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('M', style: TextStyle(fontSize: 9)),
                  SizedBox(height: 5),
                  Text('W', style: TextStyle(fontSize: 9)),
                  SizedBox(height: 5),
                  Text('F', style: TextStyle(fontSize: 9)),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (dayIdx) {
                    return Column(
                      children: List.generate(4, (weekIdx) {
                        final val = activityGrid[weekIdx][dayIdx];
                        return Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: getCellColor(val),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Network Stats Counters ---
  Widget _buildNetworkStatsCounters(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 18, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              Text(
                'NETWORK STATS',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStatRow(context, 'Packets Routed', '142', Icons.mark_email_read_outlined, AppColors.success),
          const Divider(height: 16),
          _buildStatRow(context, 'Labs Resolved', '8 / 10', Icons.task_alt, AppColors.primaryAccent),
          const Divider(height: 16),
          _buildStatRow(context, 'Devices Configured', '45', Icons.router_outlined, AppColors.secondaryAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor),
        ),
      ],
    );
  }

  // --- Compact Leaderboard / Peer Rank Widget ---
  Widget _buildLeaderboardCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final learners = [
      {'rank': '🥇 #1', 'name': 'Alex Chen', 'xp': '1,450 XP', 'badge': 'Network Master', 'color': Colors.amber},
      {'rank': '🥈 #2', 'name': 'Sarah Jenkins', 'xp': '1,280 XP', 'badge': 'Subnet Wizard', 'color': const Color(0xFF94A3B8)},
      {'rank': '🥉 #3', 'name': 'You (Current)', 'xp': '1,120 XP', 'badge': 'Packet Tracer', 'color': const Color(0xFFCD7F32)},
    ];

    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_outlined, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TOP LEARNERS THIS WEEK',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: learners.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, idx) {
              final item = learners[idx];
              final isUser = idx == 2;
              return Row(
                children: [
                  Text(
                    item['rank'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isUser ? AppColors.primaryAccent : null,
                          ),
                        ),
                        Text(
                          item['badge'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item['xp'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item['color'] as Color,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Latest Earned Badge Card ---
  Widget _buildLatestBadgeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, size: 18, color: AppColors.secondaryAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LATEST EARNED BADGE',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondaryAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryAccent, width: 2),
                ),
                child: const Icon(Icons.military_tech, color: AppColors.secondaryAccent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subnet Master',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mastered CIDR masks & IP gateway routing',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTroubleshootingLabPressed,
              icon: const Icon(Icons.emoji_events_outlined, size: 14),
              label: const Text('View All Badges & Progress', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryAccent,
                side: const BorderSide(color: AppColors.secondaryAccent),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Course Modules List with Status Tags, Difficulty & Estimated Completion Times ---
  Widget _buildCourseModulesSection(BuildContext context) {
    final theme = Theme.of(context);

    final modules = [
      {
        'title': 'Module 1: Physical Layer & Cabling',
        'subtitle': 'Straight-through, Crossover & Fiber connections',
        'status': 'Completed',
        'statusColor': AppColors.success,
        'difficulty': 'Beginner',
        'diffColor': AppColors.success,
        'time': '15 mins',
      },
      {
        'title': 'Module 2: IP Subnetting & Gateway Routing',
        'subtitle': 'CIDR masks, gateway IPs & host subnets',
        'status': 'In Progress',
        'statusColor': AppColors.warning,
        'difficulty': 'Intermediate',
        'diffColor': AppColors.warning,
        'time': '25 mins',
      },
      {
        'title': 'Module 3: OSI Model & Header Inspection',
        'subtitle': 'Layer 1-7 encapsulation & Ethernet frames',
        'status': 'In Progress',
        'statusColor': AppColors.secondaryAccent,
        'difficulty': 'Intermediate',
        'diffColor': AppColors.warning,
        'time': '35 mins',
      },
      {
        'title': 'Module 4: Advanced Network Troubleshooting',
        'subtitle': 'Diagnosing broken links, shutdown ports & ACLs',
        'status': 'Not Started',
        'statusColor': theme.hintColor,
        'difficulty': 'Advanced',
        'diffColor': const Color(0xFFA855F7), // Purple
        'time': '45 mins',
      },
    ];

    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              Text(
                'COURSE MODULES & LEARNING PATH',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final mod = modules[index];
              final statusColor = mod['statusColor'] as Color;
              final statusText = mod['status'] as String;
              final diffColor = mod['diffColor'] as Color;
              final diffText = mod['difficulty'] as String;
              final timeText = mod['time'] as String;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.canvasColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mod['title'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mod['subtitle'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),

                    // Badges Row: Difficulty + Time + Status Chip
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Difficulty Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: diffColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: diffColor, width: 1),
                          ),
                          child: Text(
                            diffText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: diffColor,
                            ),
                          ),
                        ),

                        // Estimated Completion Time
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                timeText,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                        // Status Tag Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE HOVER CARD WIDGET WITH SOFT ELEVATION & GLOWING BORDER
// ============================================================================
class HoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HoverCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final border = Border.all(
      color: _isHovered
          ? AppColors.primaryAccent.withOpacity(0.8)
          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      width: _isHovered ? 1.5 : 1.0,
    );

    final shadow = _isHovered
        ? [
            BoxShadow(
              color: AppColors.primaryAccent.withOpacity(isDark ? 0.25 : 0.12),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: border,
          boxShadow: shadow,
        ),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// 1. CONTINUE LAST LAB PREVIEW CARD
// ============================================================================
class ContinueLastLabCard extends StatefulWidget {
  final VoidCallback onResumePressed;

  const ContinueLastLabCard({super.key, required this.onResumePressed});

  @override
  State<ContinueLastLabCard> createState() => _ContinueLastLabCardState();
}

class _ContinueLastLabCardState extends State<ContinueLastLabCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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

    return HoverCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Time Spent Badge, Difficulty, and Resume Button
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.play_circle_outline, color: AppColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'CONTINUE LAST LAB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          // Difficulty Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.warning, width: 1),
                            ),
                            child: const Text(
                              'Intermediate',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                            ),
                          ),
                          // Estimated Time
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 12, color: AppColors.primaryAccent),
                                const SizedBox(width: 4),
                                Text(
                                  '⏱️ 25 mins total (14 mins spent)',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lab 2: Subnetting & IP Gateway Routing',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onResumePressed,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('RESUME LAB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mini Network Diagram Preview Box
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 2,
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: _buildMiniNode(context, Icons.computer, 'PC1\n192.168.1.10'),
                    ),
                    Positioned(
                      left: (width - 80) * 0.33,
                      child: _buildMiniNode(context, Icons.swap_horiz, 'SwitchA'),
                    ),
                    Positioned(
                      left: (width - 80) * 0.66,
                      child: _buildMiniNode(context, Icons.router, 'Router1\n192.168.1.1'),
                    ),
                    Positioned(
                      right: 0,
                      child: _buildMiniNode(context, Icons.computer, 'PC2\n192.168.2.20'),
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final val = _controller.value;
                        final double startX = 35.0;
                        final double endX = width - 35.0;
                        final double x = startX + (endX - startX) * val;
                        return Positioned(
                          left: x - 5,
                          child: Container(
                            width: 10,
                            height: 10,
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

  Widget _buildMiniNode(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryAccent),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ============================================================================
// 2. DAILY CHALLENGE / QUIZ OF THE DAY WIDGET
// ============================================================================
class DailyChallengeWidget extends StatefulWidget {
  final VoidCallback onLaunchPressed;

  const DailyChallengeWidget({super.key, required this.onLaunchPressed});

  @override
  State<DailyChallengeWidget> createState() => _DailyChallengeWidgetState();
}

class _DailyChallengeWidgetState extends State<DailyChallengeWidget> {
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

    return HoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'QUIZ OF THE DAY',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '+50 XP Reward',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Which subnet mask yields 30 usable host IPs for network 192.168.1.0?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(options.length, (idx) {
              final isSelected = _selectedOption == idx;
              return ChoiceChip(
                label: Text(options[idx], style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
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
              icon: const Icon(Icons.rocket_launch, size: 16),
              label: const Text('Launch Challenge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
