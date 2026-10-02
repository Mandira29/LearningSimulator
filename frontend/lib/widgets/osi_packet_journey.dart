import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/osi_journey_scenario.dart';
import '../models/default_osi_scenarios.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';

class OSIPacketJourney extends StatefulWidget {
  final bool isPreview;
  final SimulatorState? state;
  final VoidCallback? onOpenFullJourneyPressed;
  final VoidCallback? onOpenSimulatorPressed;

  const OSIPacketJourney({
    super.key,
    this.isPreview = false,
    this.state,
    this.onOpenFullJourneyPressed,
    this.onOpenSimulatorPressed,
  });

  @override
  State<OSIPacketJourney> createState() => _OSIPacketJourneyState();
}

class _OSIPacketJourneyState extends State<OSIPacketJourney> {
  final OSIScenario _scenario = DefaultOSIScenarios.defaultHttpScenario;
  int _currentStepIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0; // 0.5x, 1.0x, 2.0x
  Timer? _playbackTimer;

  final FocusNode _focusNode = FocusNode();
  bool _quizCompleted = false;
  int? _selectedQuizOption;

  @override
  void initState() {
    super.initState();
    if (widget.isPreview) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = true;
      if (_currentStepIndex >= _scenario.steps.length - 1) {
        _currentStepIndex = 0;
      }
    });
    final int intervalMs = (1200 / _playbackSpeed).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentStepIndex < _scenario.steps.length - 1) {
          _currentStepIndex++;
        } else {
          _currentStepIndex = 0; // Loop back
        }
      });
    });
  }

  void _pauseAutoPlay() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  void _stepForward() {
    _pauseAutoPlay();
    if (_currentStepIndex < _scenario.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _stepBackward() {
    _pauseAutoPlay();
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _restartJourney() {
    _pauseAutoPlay();
    setState(() {
      _currentStepIndex = 0;
      _quizCompleted = false;
      _selectedQuizOption = null;
    });
  }

  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    if (_isPlaying) {
      _startAutoPlay();
    }
  }

  // Keyboard shortcut listener (Space = Play/Pause, Left/Right = Step)
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _togglePlayPause();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _stepForward();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _stepBackward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPreview) {
      return _buildPreviewCard(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentStep = _scenario.steps[_currentStepIndex];

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: Container(
          color: isDark ? const Color(0xFF0F172A) : AppColors.lightBg,
          child: Column(
            children: [
              // 1. Top Navigation Bar & Scenario Selector
              _buildJourneyHeader(context),

              // 2. Main 3-Column Interactive Visualizer Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 900;
                    if (isMobile) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Physical Path Visualizer
                            _buildCenterTransitPath(context, currentStep),
                            const SizedBox(height: 16),
                            // Sender Stack
                            _buildSenderStack(context, currentStep),
                            const SizedBox(height: 16),
                            // Receiver Stack
                            _buildReceiverStack(context, currentStep),
                            const SizedBox(height: 16),
                            // Header Inspector
                            _buildHeaderInspector(context, currentStep),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Column: Sender 7-Layer OSI Stack
                          SizedBox(
                            width: 240,
                            child: _buildSenderStack(context, currentStep),
                          ),
                          const SizedBox(width: 16),

                          // Center Column: Animated Physical Path & Bitstream
                          Expanded(
                            child: _buildCenterTransitPath(context, currentStep),
                          ),
                          const SizedBox(width: 16),

                          // Right Column: Receiver 7-Layer Stack + Header Inspector
                          SizedBox(
                            width: 320,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _buildReceiverStack(context, currentStep),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  flex: 5,
                                  child: _buildHeaderInspector(context, currentStep),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 3. Bottom Accessible Plain-English Caption Bar & Control Suite
              _buildBottomControlSuite(context, currentStep),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // PREVIEW CARD VIEW (DASHBOARD INTEGRATION)
  // ============================================================================
  Widget _buildPreviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentStep = _scenario.steps[_currentStepIndex];

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.alt_route, color: AppColors.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FEATURED: OSI PACKET JOURNEY',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Visual Encapsulation ➔ Transit ➔ Decapsulation',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success, width: 0.8),
                  ),
                  child: const Text(
                    'Interactive 7-Layer Model',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Path Mini Diagram
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniDeviceNode('PC-A', Icons.computer, currentStep.activeDevice == 'PC-A'),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(height: 2, color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              alignment: Alignment(-1.0 + (currentStep.pathProgress * 2.0), 0.0),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.send, size: 10, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildMiniDeviceNode('Switch', Icons.swap_horiz, currentStep.activeDevice == 'Switch'),
                      Expanded(
                        child: Container(height: 2, color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                      ),
                      _buildMiniDeviceNode('Router', Icons.router, currentStep.activeDevice == 'Router'),
                      Expanded(
                        child: Container(height: 2, color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                      ),
                      _buildMiniDeviceNode('Server', Icons.dns, currentStep.activeDevice == 'Server'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentStep.caption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onOpenFullJourneyPressed,
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('OPEN FULL OSI PACKET JOURNEY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniDeviceNode(String label, IconData icon, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isActive ? AppColors.primaryAccent : Colors.grey),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primaryAccent : Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // FULL INTERACTIVE SCREEN WORKSPACE COMPONENTS
  // ============================================================================

  Widget _buildJourneyHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBg : AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.alt_route, color: AppColors.primaryAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OSI PACKET JOURNEY VISUALIZER',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.0,
                  color: AppColors.primaryAccent,
                ),
              ),
              Text(
                _scenario.description,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
          const Spacer(),

          // Scenario Preset Dropdown Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_calls, size: 14, color: AppColors.secondaryAccent),
                const SizedBox(width: 6),
                Text(
                  'Scenario: ${_scenario.name}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Left Column: Sender 7-Layer OSI Stack ---
  Widget _buildSenderStack(BuildContext context, OSIStep currentStep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.computer, size: 16, color: AppColors.primaryAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'SENDER (PC-A)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('192.168.1.10', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Expanded(
              child: Column(
                children: defaultOSILayers.map((layer) {
                  final isActive = currentStep.activeSenderLayer == layer.number;
                  return Expanded(
                    child: _buildLayerBlock(
                      layer: layer,
                      isActive: isActive,
                      isSender: true,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Right Column: Receiver 7-Layer OSI Stack ---
  Widget _buildReceiverStack(BuildContext context, OSIStep currentStep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns, size: 16, color: AppColors.secondaryAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'RECEIVER (SERVER)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.secondaryAccent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('10.0.0.5', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.secondaryAccent)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Expanded(
              child: Column(
                children: defaultOSILayers.map((layer) {
                  final isActive = currentStep.activeReceiverLayer == layer.number;
                  return Expanded(
                    child: _buildLayerBlock(
                      layer: layer,
                      isActive: isActive,
                      isSender: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerBlock({
    required OSILayerInfo layer,
    required bool isActive,
    required bool isSender,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => _openLayerDetailModal(layer),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActive ? layer.color.withValues(alpha: 0.25) : layer.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? layer.color : layer.color.withValues(alpha: 0.3),
              width: isActive ? 2.0 : 0.8,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: layer.color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? layer.color : layer.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'L${layer.number}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        layer.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'PDU: ${layer.pdu}',
                        style: TextStyle(
                          fontSize: 9,
                          color: layer.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isActive)
                Icon(
                  isSender ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 14,
                  color: layer.color,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Center Column: Physical Topology Path & Animated Nested Packet Graphic ---
  Widget _buildCenterTransitPath(BuildContext context, OSIStep currentStep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.hub, size: 16, color: AppColors.primaryAccent),
                const SizedBox(width: 6),
                Text(
                  'PHYSICAL NETWORK TRANSIT PATH',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.warning, width: 0.8),
                  ),
                  child: Text(
                    'Step ${currentStep.stepIndex + 1} of ${_scenario.steps.length}: ${currentStep.phase.toUpperCase()}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Top Device Path Nodes with Connection Lines
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Connection Cables Line
                    Positioned(
                      left: 40,
                      right: 40,
                      top: 40,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Animated Traveling Packet Node
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      left: 20 + (currentStep.pathProgress * 280.0),
                      top: 24,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              'L${currentStep.activeSenderLayer > 0 ? currentStep.activeSenderLayer : (currentStep.activeReceiverLayer > 0 ? currentStep.activeReceiverLayer : 3)} Packet',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, size: 12, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),

                    // Device Nodes Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTopologyDeviceNode('PC-A', '192.168.1.10', Icons.computer, currentStep.activeDevice == 'PC-A'),
                        _buildTopologyDeviceNode('Switch', 'Layer 2 MAC', Icons.swap_horiz, currentStep.activeDevice == 'Switch'),
                        _buildTopologyDeviceNode('Router', '192.168.1.1', Icons.router, currentStep.activeDevice == 'Router'),
                        _buildTopologyDeviceNode('Server', '10.0.0.5', Icons.dns, currentStep.activeDevice == 'Server'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nested Header Encapsulation Visualizer Card
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NESTED LAYER ENCAPSULATION GRAPHIC',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Nested Header Boxes Graphic
                    Expanded(
                      child: Center(
                        child: _buildNestedHeaderGraphic(currentStep),
                      ),
                    ),

                    // Live L1 Bitstream output if available
                    if (currentStep.bitstream != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, size: 12, color: AppColors.success),
                            const SizedBox(width: 6),
                            const Text(
                              'L1 WIRE BITS: ',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                            Expanded(
                              child: Text(
                                currentStep.bitstream!,
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.success),
                                overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopologyDeviceNode(String name, String subText, IconData icon, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryAccent.withValues(alpha: 0.2) : Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.primaryAccent : Colors.grey.withValues(alpha: 0.4),
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 26,
            color: isActive ? AppColors.primaryAccent : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          subText,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildNestedHeaderGraphic(OSIStep currentStep) {
    // Renders nested colored blocks representing L2 Frame > L3 IP > L4 TCP > L7 Data
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // L2 Header Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: const Text('L2 Eth Header\n[AA:AA ➔ GW:GW]', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), textAlign: TextAlign.center),
          ),
          // L3 Header Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF06B6D4)),
            ),
            child: Text('L3 IP Header\n[192.168.1.10 ➔ 10.0.0.5]\nTTL: ${currentStep.headerFields.firstWhere((e) => e.name.contains('TTL'), orElse: () => const OSIHeaderField(name: 'TTL', value: '64')).value}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)), textAlign: TextAlign.center),
          ),
          // L4 Header Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Text('L4 TCP Header\n[Port 54321 ➔ 80]', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)), textAlign: TextAlign.center),
          ),
          // L7 Payload Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
              border: Border.all(color: const Color(0xFFE11D48)),
            ),
            child: const Text('L7 HTTP Data Payload\n"GET /index.html"', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // --- Right Column: Header Inspector Card ---
  Widget _buildHeaderInspector(BuildContext context, OSIStep currentStep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 16, color: AppColors.primaryAccent),
                const SizedBox(width: 6),
                Text(
                  'HEADER FIELD INSPECTOR',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: currentStep.headerFields.length,
                itemBuilder: (context, index) {
                  final field = currentStep.headerFields[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: field.isChanged
                          ? AppColors.warning.withValues(alpha: 0.18)
                          : (isDark ? const Color(0xFF0F172A) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: field.isChanged ? AppColors.warning : theme.dividerColor,
                        width: field.isChanged ? 1.5 : 0.6,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              field.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: field.isChanged ? AppColors.warning : Colors.grey,
                              ),
                            ),
                            if (field.isChanged)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'CHANGED IN TRANSIT',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          field.value,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                        if (field.explanation != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            field.explanation!,
                            style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Colors.amber),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Control Suite & Accessible Caption Bar ---
  Widget _buildBottomControlSuite(BuildContext context, OSIStep currentStep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      liveRegion: true, // Accessibility aria-live equivalent
      label: 'Current OSI Step: ${currentStep.caption}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondaryBg : AppColors.lightSurface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          children: [
            // Plain-English Caption Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.primaryAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentStep.caption,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Controls Row: Step / Speed / Quiz / Simulator Buttons
            Row(
              children: [
                // Step Back Button
                IconButton(
                  onPressed: _currentStepIndex > 0 ? _stepBackward : null,
                  icon: const Icon(Icons.skip_previous),
                  tooltip: 'Step Back (Left Arrow)',
                ),

                // Play / Pause Button
                ElevatedButton.icon(
                  onPressed: _togglePlayPause,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 18),
                  label: Text(_isPlaying ? 'PAUSE' : 'PLAY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? AppColors.warning : AppColors.primaryAccent,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(width: 8),

                // Step Forward Button
                IconButton(
                  onPressed: _currentStepIndex < _scenario.steps.length - 1 ? _stepForward : null,
                  icon: const Icon(Icons.skip_next),
                  tooltip: 'Step Forward (Right Arrow)',
                ),

                // Restart Button
                IconButton(
                  onPressed: _restartJourney,
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Restart Animation',
                ),

                const SizedBox(width: 16),

                // Speed Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [0.5, 1.0, 2.0].map((speed) {
                      final isSelected = _playbackSpeed == speed;
                      return InkWell(
                        onTap: () => _changeSpeed(speed),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF0F172A) : theme.hintColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Spacer(),

                // "Quiz Me" Button (+XP Reward)
                ElevatedButton.icon(
                  onPressed: () => _showQuizModal(context),
                  icon: const Icon(Icons.quiz_outlined, size: 16),
                  label: Text(_quizCompleted ? 'Quiz Completed (+50 XP)' : 'Quiz Me (+50 XP)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _quizCompleted ? AppColors.success : Colors.amber,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(width: 10),

                // "Try it in Simulator" Button
                if (widget.onOpenSimulatorPressed != null)
                  OutlinedButton.icon(
                    onPressed: widget.onOpenSimulatorPressed,
                    icon: const Icon(Icons.settings_ethernet, size: 16),
                    label: const Text('Try it in Simulator'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryAccent,
                      side: const BorderSide(color: AppColors.primaryAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Interactive Layer Detail Modal ---
  void _openLayerDetailModal(OSILayerInfo layer) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: layer.color, borderRadius: BorderRadius.circular(4)),
                child: Text('Layer ${layer.number}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Text('${layer.name} Layer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModalDetailSection('Purpose & What it Does', layer.purpose, Icons.info_outline),
                const SizedBox(height: 12),
                _buildModalDetailSection('Protocols at this Layer', layer.protocols, Icons.code),
                const SizedBox(height: 12),
                _buildModalDetailSection('Header Added', layer.headerAdded, Icons.layers),
                const SizedBox(height: 12),
                _buildModalDetailSection('Real-World Analogy', layer.realWorldAnalogy, Icons.mark_as_unread),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalDetailSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryAccent),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryAccent)),
          ],
        ),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(fontSize: 12, height: 1.4)),
      ],
    );
  }

  // --- Quiz Me Modal ---
  void _showQuizModal(BuildContext context) {
    final quiz = _scenario.quiz;
    final options = (quiz['options'] as List<dynamic>).cast<String>();
    final correctIdx = quiz['correctIndex'] as int;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Row(
                children: [
                  Icon(Icons.quiz, color: Colors.amber, size: 22),
                  SizedBox(width: 8),
                  Text('OSI Journey Quiz Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz['question'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  ...List.generate(options.length, (idx) {
                    final isSelected = _selectedQuizOption == idx;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () {
                          setModalState(() {
                            _selectedQuizOption = idx;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryAccent.withValues(alpha: 0.2) : theme.canvasColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryAccent : theme.dividerColor,
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                size: 16,
                                color: isSelected ? AppColors.primaryAccent : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(options[idx], style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedQuizOption == null
                      ? null
                      : () {
                          final isCorrect = _selectedQuizOption == correctIdx;
                          Navigator.of(context).pop();

                          if (isCorrect) {
                            setState(() {
                              _quizCompleted = true;
                            });
                            widget.state?.recordQuizProgressToDb(99, 50); // Record XP in SQLite DB
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Correct! You earned +50 XP for mastering OSI Packet Journey!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Incorrect answer. Try reviewing the Router Transit step and test again!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: const Color(0xFF0F172A)),
                  child: const Text('Submit Answer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
