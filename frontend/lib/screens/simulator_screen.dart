import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/simulator_state.dart';
import '../widgets/device_toolbox.dart';
import '../widgets/network_canvas.dart';
import '../widgets/osi_inspector.dart';
import '../widgets/simulation_controls.dart';

class SimulatorScreen extends StatefulWidget {
  final SimulatorState state;

  const SimulatorScreen({
    super.key,
    required this.state,
  });

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Completer<void>? _segmentCompleter;
  bool _runningAnimation = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Initialize AnimationController (target ~1 second per segment)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Update progress in state on every tick
    _animationController!.addListener(() {
      widget.state.updateAnimationProgress(_animationController!.value);
    });

    // Check status to complete segments
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_segmentCompleter != null && !_segmentCompleter!.isCompleted) {
          _segmentCompleter!.complete();
        }
      }
    });

    // 2. Add listener to centralized state changes
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _animationController?.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;

    final state = widget.state;

    // Trigger visual animation if path resolved but animation not yet started
    if (state.simulationStatus == 'SIMULATING' && 
        state.simulationPath.isNotEmpty && 
        !state.isAnimating && 
        !_runningAnimation) {
      _startAnimation(state.simulationPath);
    }

    // Adapt controller to pause/resume triggers
    if (state.isAnimating) {
      if (state.isPaused && _animationController!.isAnimating) {
        _animationController!.stop();
      } else if (!state.isPaused && !_animationController!.isAnimating) {
        _animationController!.forward();
      }
    }
  }

  Future<void> _startAnimation(List<String> pathNames) async {
    _runningAnimation = true;

    // 1. Map names back to device objects to fetch canvas offsets
    final List<Device> pathDevices = [];
    for (final name in pathNames) {
      final dev = widget.state.devices.firstWhere(
        (d) => d.name == name,
        orElse: () => Device(id: '', type: '', name: '', x: 0, y: 0, ipAddress: '', macAddress: ''),
      );
      if (dev.id.isNotEmpty) {
        pathDevices.add(dev);
      }
    }

    if (pathDevices.length < 2) {
      widget.state.cancelAnimation();
      _runningAnimation = false;
      return;
    }

    // 2. Initialize state flags
    widget.state.startAnimation();

    // 3. Traverse segment by segment
    for (int i = 0; i < pathDevices.length - 1; i++) {
      // Check if animation was terminated midway (e.g. via reset/clear)
      if (!widget.state.isAnimating) break;

      widget.state.setAnimationSegment(
        from: pathDevices[i],
        to: pathDevices[i + 1],
        index: i,
      );

      try {
        await _runSegment();
      } catch (e) {
        // Animation was aborted or error occurred
        break;
      }
    }

    // 4. Mark success on completion if not cancelled midway
    if (widget.state.isAnimating) {
      widget.state.completeAnimation();
    }
    _runningAnimation = false;
  }

  Future<void> _runSegment() {
    _segmentCompleter = Completer<void>();
    _animationController!.reset();
    
    // Only start if not paused
    if (!widget.state.isPaused) {
      _animationController!.forward();
    }
    
    return _segmentCompleter!.future;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return Scaffold(
          body: Column(
            children: [
              // Top Section: Toolbox | Canvas | Inspector
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT: Toolbox
                    DeviceToolbox(state: widget.state),

                    // CENTER: Interactive Canvas
                    Expanded(
                      child: NetworkCanvas(state: widget.state),
                    ),

                    // RIGHT: OSI / Device Inspector
                    OsiInspector(state: widget.state),
                  ],
                ),
              ),

              // BOTTOM: Controls & Message Bar
              SimulationControls(state: widget.state),
            ],
          ),
        );
      },
    );
  }
}
