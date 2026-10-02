import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netvisual_academy/main.dart';
import 'package:netvisual_academy/services/simulator_state.dart';
import 'package:netvisual_academy/models/challenge.dart';

void main() {
  testWidgets('NetVisual Academy Startup Smoke Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Set desktop resolution for test window
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const NetVisualAcademyApp());
    await tester.pump();

    // Verify that the dashboard loads by checking for the branding title.
    expect(find.textContaining('NetVisual'), findsAtLeast(1));

    // Clear repeating animation timers
    await tester.pumpWidget(const SizedBox());
  });

  test('Basic Level 1: Getting started objectives and packet queue test', () {
    final state = SimulatorState();
    
    // Start Level 1
    state.startLevel(1);
    expect(state.activeLevelIndex, 1);
    expect(state.devices.length, 3);
    expect(state.devices.first.owner, contains('Alice'));
    expect(state.devices.last.owner, contains('Bob'));
    
    // Verify initial objectives are all false
    expect(state.level1Objectives['restart'], false);
    expect(state.level1Objectives['pause'], false);
    expect(state.level1Objectives['inspect_pc'], false);
    expect(state.level1Objectives['inspect_packet'], false);
    expect(state.level1Objectives['add_packet'], false);
    expect(state.level1Objectives['send_packet'], false);

    // Objective 1: Restart simulation over
    state.restartSimulationOver();
    expect(state.level1Objectives['restart'], true);

    // Objective 2: Pause the simulation
    state.pauseAnimation();
    expect(state.level1Objectives['pause'], true);

    // Objective 3: Click on a computer to see its properties
    state.selectDevice(state.devices.first.id);
    expect(state.level1Objectives['inspect_pc'], true);

    // Objective 4: Click on a packet (the circles) to see its properties
    state.inspectPacketCircle();
    expect(state.level1Objectives['inspect_packet'], true);

    // Objective 5: Click the + button and add a new packet
    state.addPacketToQueue();
    expect(state.level1Objectives['add_packet'], true);
    expect(state.packetQueue.length, 1);

    // Objective 6: Click the send arrow beside the packet you just added
    final queuedPkt = state.packetQueue.first;
    state.dispatchPacketFromQueue(queuedPkt);
    expect(state.level1Objectives['send_packet'], true);

    // Verify all 6 objectives completed
    expect(state.level1CompletedCount, 6);
    expect(state.levelCompleted, true);

    state.dispose();
  });

  test('Challenges System: All 12 challenges and actions execution test', () async {
    final state = SimulatorState();
    expect(state.challenges.length, 12);

    // Test Challenge 01: Packet Fields
    state.startChallenge('ch01');
    expect(state.activeChallenge?.id, 'ch01');
    expect(state.devices.length, 2);
    expect(state.devices.first.name, 'Alice PC');
    expect(state.devices.last.name, 'Bob PC');

    await state.executeChallengeAction('send_packet', {
      'sourceDeviceId': 'pc_alice',
      'destinationDeviceId': 'pc_bob',
      'sourceIP': '192.168.1.10',
      'destinationIP': '192.168.1.20',
    });
    expect(state.activeChallenge?.status, ChallengeStatus.completed);

    // Test Challenge 02: Ping
    state.startChallenge('ch02');
    expect(state.activeChallenge?.id, 'ch02');
    for (int i = 0; i < 5; i++) {
      await state.executeChallengeAction('send_ping');
    }
    expect(state.activeChallenge?.status, ChallengeStatus.completed);

    // Test Challenge 04: Modems (NAT)
    state.startChallenge('ch04');
    expect(state.activeChallenge?.id, 'ch04');
    expect(state.devices.any((d) => d.type == 'MODEM'), true);
    await state.executeChallengeAction('send_through_modem', {'sourceDeviceId': 'pc_alice'});
    expect(state.activeChallenge?.status, ChallengeStatus.completed);

    // Test Challenge 07: Basic DoS
    state.startChallenge('ch07');
    await state.executeChallengeAction('generate_traffic', {'packetCount': 25});
    expect(state.activeChallenge?.status, ChallengeStatus.completed);

    // Test Challenge 12: Traceroute
    state.startChallenge('ch12');
    expect(state.activeChallenge?.id, 'ch12');
    await state.executeChallengeAction('traceroute_probe', {'ttl': 1});
    await state.executeChallengeAction('traceroute_probe', {'ttl': 2});
    await state.executeChallengeAction('traceroute_probe', {'ttl': 3});
    await state.executeChallengeAction('traceroute_probe', {'ttl': 4});
    expect(state.activeChallenge?.status, ChallengeStatus.completed);

    state.dispose();
  });

  testWidgets('ChallengesScreen UI and Classic Lab toggle test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NetVisualAcademyApp());
    await tester.pump();

    // Navigate to Challenges & Lab
    final challengesNavFinder = find.text('Challenges & Lab');
    expect(challengesNavFinder, findsOneWidget);
    await tester.tap(challengesNavFinder);
    await tester.pumpAndSettle();

    // Verify Challenges screen header
    expect(find.text('NETWORKING CHALLENGES'), findsOneWidget);
    expect(find.text('Packet Fields'), findsOneWidget);
    expect(find.text('Ping (ICMP Echo)'), findsOneWidget);
    expect(find.text('Routing'), findsOneWidget);

    // Test switching to Classic Lab filter
    final classicLabChip = find.text('Classic Lab');
    expect(classicLabChip, findsOneWidget);
    await tester.tap(classicLabChip);
    await tester.pumpAndSettle();

    // Verify Classic Troubleshooting Lab levels are available
    expect(find.text('Getting started'), findsOneWidget);
    expect(find.text('Broken Cable'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpWidget(const SizedBox());
  });
}
