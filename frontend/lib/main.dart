import 'package:flutter/material.dart';
import 'services/theme_service.dart';
import 'services/simulator_state.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar_navigation.dart';
import 'screens/dashboard_screen.dart';
import 'screens/simulator_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/learning_path_screen.dart';
import 'screens/packet_journey_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetVisualAcademyApp());
}

class NetVisualAcademyApp extends StatefulWidget {
  const NetVisualAcademyApp({super.key});

  @override
  State<NetVisualAcademyApp> createState() => _NetVisualAcademyAppState();
}

class _NetVisualAcademyAppState extends State<NetVisualAcademyApp> {
  late final ThemeService _themeService;
  late final SimulatorState _simulatorState;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _simulatorState = SimulatorState();
  }

  @override
  void dispose() {
    _simulatorState.dispose();
    _themeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'NetVisual Academy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: AppShell(
            themeService: _themeService,
            simulatorState: _simulatorState,
          ),
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  final ThemeService themeService;
  final SimulatorState simulatorState;

  const AppShell({
    super.key,
    required this.themeService,
    required this.simulatorState,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.simulatorState.addListener(_onSimulatorStateChanged);
  }

  @override
  void dispose() {
    widget.simulatorState.removeListener(_onSimulatorStateChanged);
    super.dispose();
  }

  void _onSimulatorStateChanged() {
    if (widget.simulatorState.requestedTab != null) {
      setState(() {
        _currentIndex = widget.simulatorState.requestedTab!;
      });
      widget.simulatorState.clearTabRequest();
    }
  }

  void _onNavigationChanged(int index) {
    debugPrint('AppShell: Navigation changed to $index');
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Body selection
    Widget activeScreen;
    switch (_currentIndex) {
      case 0:
        activeScreen = DashboardScreen(
          state: widget.simulatorState,
          onOpenSimulatorPressed: () => _onNavigationChanged(1),
          onTroubleshootingLabPressed: () => _onNavigationChanged(2),
          onOpenModulesPressed: () => _onNavigationChanged(3),
          onOpenPacketJourneyPressed: () => _onNavigationChanged(5),
        );
        break;
      case 1:
        activeScreen = SimulatorScreen(state: widget.simulatorState);
        break;
      case 2:
        activeScreen = ChallengesScreen(state: widget.simulatorState);
        break;
      case 3:
        activeScreen = LearningPathScreen(
          onOpenSimulatorPressed: () => _onNavigationChanged(1),
          onTroubleshootingLabPressed: () => _onNavigationChanged(2),
        );
        break;
      case 4:
        activeScreen = SettingsScreen(themeService: widget.themeService);
        break;
      case 5:
        activeScreen = PacketJourneyScreen(
          state: widget.simulatorState,
          onOpenSimulatorPressed: () => _onNavigationChanged(1),
        );
        break;
      default:
        activeScreen = DashboardScreen(
          state: widget.simulatorState,
          onOpenSimulatorPressed: () => _onNavigationChanged(1),
          onTroubleshootingLabPressed: () => _onNavigationChanged(2),
          onOpenModulesPressed: () => _onNavigationChanged(3),
          onOpenPacketJourneyPressed: () => _onNavigationChanged(5),
        );
        break;
    }



    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Persistent Sidebar Menu
          SidebarNavigation(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onNavigationChanged,
          ),

          // Main Viewport
          Expanded(
            child: activeScreen,
          ),
        ],
      ),
    );
  }
}
