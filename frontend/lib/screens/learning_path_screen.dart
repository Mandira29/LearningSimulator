import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LearningPathScreen extends StatelessWidget {
  final VoidCallback onOpenSimulatorPressed;
  final VoidCallback onTroubleshootingLabPressed;

  const LearningPathScreen({
    super.key,
    required this.onOpenSimulatorPressed,
    required this.onTroubleshootingLabPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final modules = [
      {
        'id': 1,
        'title': 'Module 1: Physical Layer & Cabling',
        'subtitle': 'Straight-through, Crossover & Fiber connections',
        'status': 'Completed',
        'statusColor': AppColors.success,
        'difficulty': 'Beginner',
        'diffColor': AppColors.success,
        'time': '15 mins',
        'icon': Icons.cable_outlined,
        'topics': ['Cable Types (Straight-Through, Crossover, Fiber, Console)', 'Physical Topology Wiring', 'Link Connection Status Checks'],
      },
      {
        'id': 2,
        'title': 'Module 2: IP Subnetting & Gateway Routing',
        'subtitle': 'CIDR masks, gateway IPs & host subnets',
        'status': 'In Progress',
        'statusColor': AppColors.warning,
        'difficulty': 'Intermediate',
        'diffColor': AppColors.warning,
        'time': '25 mins',
        'icon': Icons.alt_route_outlined,
        'topics': ['IPv4 Subnet Mask Calculations (/24, /27, /28)', 'Default Gateway & Router Hops', 'ARP Request & Response Cycles'],
      },
      {
        'id': 3,
        'title': 'Module 3: OSI Model & Header Inspection',
        'subtitle': 'Layer 1-7 encapsulation & Ethernet frames',
        'status': 'In Progress',
        'statusColor': AppColors.secondaryAccent,
        'difficulty': 'Intermediate',
        'diffColor': AppColors.warning,
        'time': '35 mins',
        'icon': Icons.layers_outlined,
        'topics': ['Ethernet II Data Frames & MAC Addresses', 'IPv4 Packet Headers & TTL Values', 'ICMP Echo Request / Reply Breakdown'],
      },
      {
        'id': 4,
        'title': 'Module 4: Advanced Network Troubleshooting',
        'subtitle': 'Diagnosing broken links, shutdown ports & ACLs',
        'status': 'Not Started',
        'statusColor': theme.hintColor,
        'difficulty': 'Advanced',
        'diffColor': const Color(0xFFA855F7), // Purple
        'time': '45 mins',
        'icon': Icons.bug_report_outlined,
        'topics': ['Interface Administrative Port Down States', 'Duplicate IP Conflict Resolution', 'Time Attack Fault Diagnosis'],
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COURSE MODULES & LEARNING PATH',
                      style: textTheme.displayLarge?.copyWith(
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Master networking fundamentals step-by-step through interactive visual labs.',
                      style: textTheme.headlineMedium?.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onTroubleshootingLabPressed,
                  icon: const Icon(Icons.rocket_launch, size: 18),
                  label: const Text('Start Troubleshooting Lab'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Modules List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final mod = modules[index];
                final statusColor = mod['statusColor'] as Color;
                final statusText = mod['status'] as String;
                final diffColor = mod['diffColor'] as Color;
                final diffText = mod['difficulty'] as String;
                final timeText = mod['time'] as String;
                final icon = mod['icon'] as IconData;
                final topics = mod['topics'] as List<String>;

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: AppColors.primaryAccent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mod['title'] as String,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mod['subtitle'] as String,
                                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Difficulty Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: diffColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: diffColor),
                                ),
                                child: Text(
                                  diffText,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: diffColor),
                                ),
                              ),

                              // Estimated Time
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeText,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      statusText,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Topics List
                      Text('Core Topics Covered:', style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: topics.map((t) => Chip(
                          avatar: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          backgroundColor: theme.canvasColor,
                          side: BorderSide(color: theme.dividerColor),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Action Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: onTroubleshootingLabPressed,
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: Text('Open ${mod['title'].toString().split(':').first} Lab'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondaryAccent,
                            side: const BorderSide(color: AppColors.secondaryAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
