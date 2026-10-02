import 'package:flutter/material.dart';
import '../services/simulator_state.dart';
import '../widgets/osi_packet_journey.dart';

class PacketJourneyScreen extends StatelessWidget {
  final SimulatorState state;
  final VoidCallback onOpenSimulatorPressed;

  const PacketJourneyScreen({
    super.key,
    required this.state,
    required this.onOpenSimulatorPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OSIPacketJourney(
      isPreview: false,
      state: state,
      onOpenSimulatorPressed: onOpenSimulatorPressed,
    );
  }
}
