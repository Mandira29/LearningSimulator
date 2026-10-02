import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';
import 'troubleshooting_screen.dart';

class ChallengesScreen extends StatefulWidget {
  final SimulatorState state;

  const ChallengesScreen({
    super.key,
    required this.state,
  });

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  String _selectedCategoryFilter = 'all'; // all, fundamentals, security, denialOfService, privacy, diagnostics, troubleshooting

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedCategoryFilter == 'troubleshooting') {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryFilterChip('All Challenges', 'all'),
                  _buildCategoryFilterChip('Fundamentals', 'fundamentals'),
                  _buildCategoryFilterChip('Network Security', 'security'),
                  _buildCategoryFilterChip('Denial of Service', 'denialOfService'),
                  _buildCategoryFilterChip('Privacy & Control', 'privacy'),
                  _buildCategoryFilterChip('Diagnostics', 'diagnostics'),
                  _buildCategoryFilterChip('Classic Lab', 'troubleshooting'),
                ],
              ),
            ),
            Expanded(
              child: TroubleshootingScreen(state: widget.state),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.military_tech_outlined,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'NETWORKING CHALLENGES',
                            style: textTheme.displayLarge?.copyWith(
                              letterSpacing: 1.5,
                              color: theme.colorScheme.primary,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Master network protocols, security vulnerabilities, traffic behavior, and diagnostics through interactive hands-on challenges.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Overall Stats Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 20, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Completed: ${_getCompletedCount()} / 12',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category Filter Bar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryFilterChip('All Challenges', 'all'),
                _buildCategoryFilterChip('Fundamentals', 'fundamentals'),
                _buildCategoryFilterChip('Network Security', 'security'),
                _buildCategoryFilterChip('Denial of Service', 'denialOfService'),
                _buildCategoryFilterChip('Privacy & Control', 'privacy'),
                _buildCategoryFilterChip('Diagnostics', 'diagnostics'),
                _buildCategoryFilterChip('Classic Lab', 'troubleshooting'),
              ],
            ),
            const SizedBox(height: 32),

            // Render Categorized Challenge Sections
            if (_shouldShowCategory(ChallengeCategory.fundamentals))
              _buildCategorySection(
                  context,
                  category: ChallengeCategory.fundamentals,
                  challenges: widget.state.challenges
                      .where((c) => c.category == ChallengeCategory.fundamentals)
                      .toList(),
                ),

              if (_shouldShowCategory(ChallengeCategory.security))
                _buildCategorySection(
                  context,
                  category: ChallengeCategory.security,
                  challenges: widget.state.challenges
                      .where((c) => c.category == ChallengeCategory.security)
                      .toList(),
                ),

              if (_shouldShowCategory(ChallengeCategory.denialOfService))
                _buildCategorySection(
                  context,
                  category: ChallengeCategory.denialOfService,
                  challenges: widget.state.challenges
                      .where((c) => c.category == ChallengeCategory.denialOfService)
                      .toList(),
                ),

              if (_shouldShowCategory(ChallengeCategory.privacy))
                _buildCategorySection(
                  context,
                  category: ChallengeCategory.privacy,
                  challenges: widget.state.challenges
                      .where((c) => c.category == ChallengeCategory.privacy)
                      .toList(),
                ),

              if (_shouldShowCategory(ChallengeCategory.diagnostics))
                _buildCategorySection(
                  context,
                  category: ChallengeCategory.diagnostics,
                  challenges: widget.state.challenges
                      .where((c) => c.category == ChallengeCategory.diagnostics)
                      .toList(),
                ),
            ],
          ),
        ),
      );
    }

  int _getCompletedCount() {
    return widget.state.challenges.where((c) => c.status == ChallengeStatus.completed).length;
  }

  bool _shouldShowCategory(ChallengeCategory cat) {
    if (_selectedCategoryFilter == 'all') return true;
    return _selectedCategoryFilter == cat.name;
  }

  Widget _buildCategoryFilterChip(String label, String value) {
    final isSelected = _selectedCategoryFilter == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? const Color(0xFF0F172A)
              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategoryFilter = value;
          });
        },
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required ChallengeCategory category,
    required List<Challenge> challenges,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(category.icon, size: 20, color: category.color),
            ),
            const SizedBox(width: 12),
            Text(
              category.displayName.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: category.color,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid of Challenge Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            final isVeryWide = constraints.maxWidth > 1200;
            final int crossAxisCount = isNarrow ? 1 : (isVeryWide ? 3 : 2);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: challenges.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 220,
              ),
              itemBuilder: (context, index) {
                return _buildChallengeCard(context, challenges[index]);
              },
            );
          },
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildChallengeCard(BuildContext context, Challenge challenge) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = challenge.status == ChallengeStatus.completed;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCompleted
              ? AppColors.success
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showChallengeDetailModal(context, challenge),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row: Level # & Difficulty + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: challenge.category.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Challenge ${challenge.number.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: challenge.category.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          challenge.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                challenge.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Description
              Expanded(
                child: Text(
                  challenge.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.35,
                    fontSize: 11.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),

              // Footer: Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${challenge.initialDevices.length} devices',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showChallengeDetailModal(context, challenge),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? AppColors.success : theme.colorScheme.primary,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      isCompleted ? 'Review' : 'Start',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChallengeDetailModal(BuildContext context, Challenge challenge) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = challenge.status == ChallengeStatus.completed;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppColors.darkSecondaryBg : AppColors.lightBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(challenge.category.icon, size: 24, color: challenge.category.color),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHALLENGE ${challenge.number.toString().padLeft(2, '0')}: ${challenge.title.toUpperCase()}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                '${challenge.category.shortName} • ${challenge.difficulty}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Learning Objective Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primaryAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'LEARNING OBJECTIVE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  challenge.learningObjective,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Instructions
                          Text(
                            'Instructions',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...challenge.instructions.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),

                          // Initial Topology Preview Summary
                          Text(
                            'Simulated Topology Preview',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: challenge.initialDevices.map((d) {
                              return Chip(
                                avatar: Icon(
                                  d.type.toUpperCase() == 'PC'
                                      ? Icons.computer
                                      : (d.type.toUpperCase() == 'SWITCH'
                                          ? Icons.swap_horiz
                                          : (d.type.toUpperCase() == 'MODEM'
                                              ? Icons.settings_input_antenna
                                              : Icons.router)),
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                label: Text('${d.name} (${d.ipAddress})'),
                                labelStyle: const TextStyle(fontSize: 11),
                                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                padding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Hints Section
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Need a Hint?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            leading: const Icon(Icons.help_outline, size: 18),
                            children: challenge.hints.map((hint) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        hint,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          // If completed: Educational Explanation
                          if (isCompleted) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.success, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      SizedBox(width: 8),
                                      Text(
                                        '✓ CHALLENGE COMPLETED — WHAT YOU LEARNED',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    challenge.explanation,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.4,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),

                  // Modal Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          widget.state.resetActiveChallenge();
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      Row(
                        children: [
                          if (isCompleted && challenge.number < 12) ...[
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                final nextId = 'ch${(challenge.number + 1).toString().padLeft(2, '0')}';
                                widget.state.startChallenge(nextId);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              child: const Text('Next Challenge →', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                          ],
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              widget.state.startChallenge(challenge.id);
                            },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text(
                              isCompleted ? 'Restart in Simulator' : 'Start Challenge',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
