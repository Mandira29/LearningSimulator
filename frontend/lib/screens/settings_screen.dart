import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;

  const SettingsScreen({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = themeService.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your simulator interface preferences.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 40),

          // Appearance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Appearance',
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance Mode',
                            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDark ? 'Dark Mode Active' : 'Light Mode Active',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Switch(
                        value: isDark,
                        activeColor: AppColors.primaryAccent,
                        onChanged: (val) {
                          themeService.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Workspace Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.computer_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Simulator Options',
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingOption(
                    context,
                    title: 'Canvas Grid Snap',
                    description: 'Align devices automatically to grid intersections.',
                    trailing: const Switch(value: true, onChanged: null),
                  ),
                  const Divider(),
                  _buildSettingOption(
                    context,
                    title: 'Auto-Generate IP Addresses',
                    description: 'Generate mock IP and MAC addresses when dragging a device.',
                    trailing: const Switch(value: true, onChanged: null),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
            // About Card
            Card(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About NetVisual Academy',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'An interactive networking learning platform for beginners.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HackElite 3.0',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        Text(
                          'Binary Beasts',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildSettingOption(
    BuildContext context, {
    required String title,
    required String description,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
