import 'package:flutter/material.dart';
import 'device.dart';
import 'connection.dart';
import '../theme/app_theme.dart';

enum ChallengeCategory {
  fundamentals,
  security,
  denialOfService,
  privacy,
  diagnostics;

  static ChallengeCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'fundamentals':
        return ChallengeCategory.fundamentals;
      case 'security':
        return ChallengeCategory.security;
      case 'denialofservice':
      case 'denial_of_service':
      case 'dos':
        return ChallengeCategory.denialOfService;
      case 'privacy':
      case 'control':
      case 'networkcontrol':
        return ChallengeCategory.privacy;
      case 'diagnostics':
        return ChallengeCategory.diagnostics;
      default:
        return ChallengeCategory.fundamentals;
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeCategory.fundamentals:
        return 'Category A: Networking Fundamentals';
      case ChallengeCategory.security:
        return 'Category B: Network Security';
      case ChallengeCategory.denialOfService:
        return 'Category C: Denial of Service';
      case ChallengeCategory.privacy:
        return 'Category D: Network Control & Privacy';
      case ChallengeCategory.diagnostics:
        return 'Category E: Network Diagnostics';
    }
  }

  String get shortName {
    switch (this) {
      case ChallengeCategory.fundamentals:
        return 'Fundamentals';
      case ChallengeCategory.security:
        return 'Security';
      case ChallengeCategory.denialOfService:
        return 'Denial of Service';
      case ChallengeCategory.privacy:
        return 'Privacy & Control';
      case ChallengeCategory.diagnostics:
        return 'Diagnostics';
    }
  }

  IconData get icon {
    switch (this) {
      case ChallengeCategory.fundamentals:
        return Icons.hub_outlined;
      case ChallengeCategory.security:
        return Icons.security_outlined;
      case ChallengeCategory.denialOfService:
        return Icons.flash_on_outlined;
      case ChallengeCategory.privacy:
        return Icons.vpn_lock_outlined;
      case ChallengeCategory.diagnostics:
        return Icons.track_changes_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ChallengeCategory.fundamentals:
        return AppColors.primaryAccent; // Cyan
      case ChallengeCategory.security:
        return const Color(0xFFF59E0B); // Amber
      case ChallengeCategory.denialOfService:
        return const Color(0xFFEF4444); // Red
      case ChallengeCategory.privacy:
        return const Color(0xFF8B5CF6); // Purple
      case ChallengeCategory.diagnostics:
        return const Color(0xFF10B981); // Emerald
    }
  }
}

enum ChallengeStatus {
  locked,
  available,
  inProgress,
  completed;

  static ChallengeStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'locked':
        return ChallengeStatus.locked;
      case 'available':
        return ChallengeStatus.available;
      case 'inprogress':
      case 'in_progress':
        return ChallengeStatus.inProgress;
      case 'completed':
        return ChallengeStatus.completed;
      default:
        return ChallengeStatus.available;
    }
  }
}

enum ObjectiveType {
  sendPacket,
  sendPing,
  inspectPacket,
  configurePacket,
  configureRouting,
  modifySourceAddress,
  generateTraffic,
  observePacket,
  discoverRouter,
  useProxy,
  detectInterception,
  completeSequence;

  static ObjectiveType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'sendpacket':
        return ObjectiveType.sendPacket;
      case 'sendping':
        return ObjectiveType.sendPing;
      case 'inspectpacket':
        return ObjectiveType.inspectPacket;
      case 'configurepacket':
        return ObjectiveType.configurePacket;
      case 'configurerouting':
        return ObjectiveType.configureRouting;
      case 'modifysourceaddress':
        return ObjectiveType.modifySourceAddress;
      case 'generatetraffic':
        return ObjectiveType.generateTraffic;
      case 'observepacket':
        return ObjectiveType.observePacket;
      case 'discoverrouter':
        return ObjectiveType.discoverRouter;
      case 'useproxy':
        return ObjectiveType.useProxy;
      case 'detectinterception':
        return ObjectiveType.detectInterception;
      case 'completesequence':
      default:
        return ObjectiveType.completeSequence;
    }
  }
}

class Challenge {
  final String id;
  final int number;
  final String title;
  final ChallengeCategory category;
  final String description;
  final String learningObjective;
  final List<String> instructions;
  final String difficulty;
  final List<Device> initialDevices;
  final List<Connection> initialConnections;
  final ObjectiveType objectiveType;
  final List<String> requiredActions;
  final Map<String, dynamic> successConditions;
  final List<String> hints;
  final String explanation;
  final ChallengeStatus status;
  final Map<String, dynamic> progress;

  Challenge({
    required this.id,
    required this.number,
    required this.title,
    required this.category,
    required this.description,
    required this.learningObjective,
    required this.instructions,
    required this.difficulty,
    required this.initialDevices,
    required this.initialConnections,
    required this.objectiveType,
    required this.requiredActions,
    required this.successConditions,
    required this.hints,
    required this.explanation,
    this.status = ChallengeStatus.available,
    this.progress = const {},
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String,
      category: ChallengeCategory.fromString(json['category'] as String? ?? 'fundamentals'),
      description: json['description'] as String? ?? '',
      learningObjective: json['learningObjective'] as String? ?? '',
      instructions: (json['instructions'] as List? ?? []).map((e) => e.toString()).toList(),
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      initialDevices: (json['initialDevices'] as List? ?? [])
          .map((d) => Device.fromJson(d as Map<String, dynamic>))
          .toList(),
      initialConnections: (json['initialConnections'] as List? ?? [])
          .map((c) => Connection.fromJson(c as Map<String, dynamic>))
          .toList(),
      objectiveType: ObjectiveType.fromString(json['objectiveType'] as String? ?? 'sendPacket'),
      requiredActions: (json['requiredActions'] as List? ?? []).map((e) => e.toString()).toList(),
      successConditions: (json['successConditions'] as Map<String, dynamic>?) ?? {},
      hints: (json['hints'] as List? ?? []).map((e) => e.toString()).toList(),
      explanation: json['explanation'] as String? ?? '',
      status: ChallengeStatus.fromString(json['status'] as String? ?? 'available'),
      progress: (json['progress'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'category': category.name,
      'description': description,
      'learningObjective': learningObjective,
      'instructions': instructions,
      'difficulty': difficulty,
      'initialDevices': initialDevices.map((d) => d.toJson()).toList(),
      'initialConnections': initialConnections.map((c) => c.toJson()).toList(),
      'objectiveType': objectiveType.name,
      'requiredActions': requiredActions,
      'successConditions': successConditions,
      'hints': hints,
      'explanation': explanation,
      'status': status.name,
      'progress': progress,
    };
  }

  Challenge copyWith({
    String? id,
    int? number,
    String? title,
    ChallengeCategory? category,
    String? description,
    String? learningObjective,
    List<String>? instructions,
    String? difficulty,
    List<Device>? initialDevices,
    List<Connection>? initialConnections,
    ObjectiveType? objectiveType,
    List<String>? requiredActions,
    Map<String, dynamic>? successConditions,
    List<String>? hints,
    String? explanation,
    ChallengeStatus? status,
    Map<String, dynamic>? progress,
  }) {
    return Challenge(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      learningObjective: learningObjective ?? this.learningObjective,
      instructions: instructions ?? this.instructions,
      difficulty: difficulty ?? this.difficulty,
      initialDevices: initialDevices ?? this.initialDevices,
      initialConnections: initialConnections ?? this.initialConnections,
      objectiveType: objectiveType ?? this.objectiveType,
      requiredActions: requiredActions ?? this.requiredActions,
      successConditions: successConditions ?? this.successConditions,
      hints: hints ?? this.hints,
      explanation: explanation ?? this.explanation,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
