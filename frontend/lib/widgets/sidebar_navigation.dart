import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
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
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBg : AppColors.lightBg,
        border: Border(right: borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Row(
              children: [
                Icon(
                  Icons.hub_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NetVisual',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.settings_ethernet_outlined,
                  activeIcon: Icons.settings_ethernet,
                  label: 'Simulator',
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Challenges & Lab',
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: 'Modules & Path',
                ),
                _buildNavItem(
                  context,
                  index: 5,
                  icon: Icons.alt_route_outlined,
                  activeIcon: Icons.alt_route,
                  label: 'Packet Journey',
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                ),

              ],
            ),
          ),
          // Footer / Version
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'HackElite 3.0 v1.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == index;
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : theme.textTheme.bodyLarge?.color,
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
