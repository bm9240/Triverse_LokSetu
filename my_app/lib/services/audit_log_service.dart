import '../models/autogov_complaint.dart';
import 'package:uuid/uuid.dart';

/// Immutable Audit Log Service
/// Maintains comprehensive audit trail for all AutoGov Engine decisions and actions
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final Uuid _uuid = const Uuid();

  // Immutable audit log entries
  final List<AuditLogEntry> _auditLog = [];

  /// Log a decision made by the engine
  void logDecision({
    required String complaintId,
    required String department,
    required PriorityLevel priority,
    required Duration slaDuration,
    required String reasoning,
  }) {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      complaintId: complaintId,
      actionType: AuditActionType.decision,
      actorId: 'SYSTEM',
      actorType: ActorType.system,
      description: 'Decision made: Department=$department, Priority=$priority',
      metadata: {
        'department': department,
        'priority': priority.toString(),
        'sla_duration': slaDuration.toString(),
        'reasoning': reasoning,
      },
    );

    _auditLog.add(entry);
  }

  /// Log state transition
  void logStateTransition({
    required String complaintId,
    required ComplaintState fromState,
    required ComplaintState toState,
    required String actorId,
    required String reason,
  }) {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      complaintId: complaintId,
      actionType: AuditActionType.stateTransition,
      actorId: actorId,
      actorType: ActorType.officer,
      description: 'State transition: ${fromState.displayName} → ${toState.displayName}',
      metadata: {
        'from_state': fromState.toString(),
        'to_state': toState.toString(),
        'reason': reason,
      },
    );

    _auditLog.add(entry);
  }

  /// Log officer assignment
  void logAssignment({
    required String complaintId,
    required String officerId,
    required String department,
    required String reason,
  }) {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      complaintId: complaintId,
      actionType: AuditActionType.assignment,
      actorId: 'SYSTEM',
      actorType: ActorType.system,
      description: 'Assigned to officer: $officerId',
      metadata: {
        'officer_id': officerId,
        'department': department,
        'reason': reason,
      },
    );

    _auditLog.add(entry);
  }

  /// Log escalation
  void logEscalation({
    required String complaintId,
    required EscalationLevel fromLevel,
    required EscalationLevel toLevel,
    required String reason,
    required PriorityLevel newPriority,
    Map<String, dynamic>? metadata,
  }) {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      complaintId: complaintId,
      actionType: AuditActionType.escalation,
      actorId: 'SYSTEM',
      actorType: ActorType.system,
      description: 'Escalated: ${fromLevel.displayName} → ${toLevel.displayName}',
      metadata: {
        'from_level': fromLevel.toString(),
        'to_level': toLevel.toString(),
        'reason': reason,
        'new_priority': newPriority.toString(),
        ...?metadata,
      },
    );

    _auditLog.add(entry);
  }

  /// Log SLA event
  void logSLAEvent({
    required String complaintId,
    required String eventType,
    required DateTime deadline,
    Map<String, dynamic>? metadata,
  }) {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      complaintId: complaintId,
      actionType: AuditActionType.slaEvent,
      actorId: 'SYSTEM',
      actorType: ActorType.system,
      description: 'SLA Event: $eventType',
      metadata: {
        'event_type': eventType,
        'deadline': deadline.toIso8601String(),
        ...?metadata,
      },
    );

    _auditLog.add(entry);
  }

  /// Log jurisdiction resolution
  void logJurisdictionResolution({
    required String complaintId,
    required String city,
    required String ward,
    required String officeId,
    required String officeName,
  }) {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      complaintId: complaintId,
      actionType: AuditActionType.jurisdictionResolution,
      actorId: 'SYSTEM',
      actorType: ActorType.system,
      description: 'Jurisdiction resolved: $officeName',
      metadata: {
        'city': city,
        'ward': ward,
        'office_id': officeId,
        'office_name': officeName,
      },
    );

    _auditLog.add(entry);
  }

  /// Log custom action
  void logCustomAction({
    required String complaintId,
    required String description,
    required String actorId,
    ActorType actorType = ActorType.system,
    Map<String, dynamic>? metadata,
  }) {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      complaintId: complaintId,
      actionType: AuditActionType.custom,
      actorId: actorId,
      actorType: actorType,
      description: description,
      metadata: metadata ?? {},
    );

    _auditLog.add(entry);
  }

  /// Get all audit entries for a complaint
  List<AuditLogEntry> getComplaintHistory(String complaintId) {
    return _auditLog
        .where((entry) => entry.complaintId == complaintId)
        .toList();
  }

  /// Get audit entries by type
  List<AuditLogEntry> getEntriesByType(AuditActionType type) {
    return _auditLog.where((entry) => entry.actionType == type).toList();
  }

  /// Get audit entries by time range
  List<AuditLogEntry> getEntriesByTimeRange(DateTime start, DateTime end) {
    return _auditLog
        .where((entry) =>
            entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList();
  }

  /// Get audit entries by actor
  List<AuditLogEntry> getEntriesByActor(String actorId) {
    return _auditLog.where((entry) => entry.actorId == actorId).toList();
  }

  /// Get recent audit entries
  List<AuditLogEntry> getRecentEntries(int count) {
    final sorted = List<AuditLogEntry>.from(_auditLog)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(count).toList();
  }

  /// Get full audit log (immutable copy)
  List<AuditLogEntry> getFullAuditLog() {
    return List.unmodifiable(_auditLog);
  }

  /// Get audit log size
  int getLogSize() => _auditLog.length;

  /// Export audit log to JSON
  List<Map<String, dynamic>> exportToJson() {
    return _auditLog.map((entry) => entry.toJson()).toList();
  }

  /// Generate audit report for complaint
  AuditReport generateComplaintReport(String complaintId) {
    final entries = getComplaintHistory(complaintId);

    if (entries.isEmpty) {
      return AuditReport(
        complaintId: complaintId,
        totalEvents: 0,
        firstEvent: null,
        lastEvent: null,
        eventsByType: {},
        timeline: [],
      );
    }

    final eventsByType = <AuditActionType, int>{};
    for (final entry in entries) {
      eventsByType[entry.actionType] = (eventsByType[entry.actionType] ?? 0) + 1;
    }

    final sortedEntries = List<AuditLogEntry>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return AuditReport(
      complaintId: complaintId,
      totalEvents: entries.length,
      firstEvent: sortedEntries.first.timestamp,
      lastEvent: sortedEntries.last.timestamp,
      eventsByType: eventsByType,
      timeline: sortedEntries,
    );
  }

  /// Verify audit log integrity (check for tampering)
  bool verifyIntegrity() {
    // In a production system, this would verify cryptographic hashes
    // For now, check basic consistency
    for (int i = 1; i < _auditLog.length; i++) {
      // Ensure timestamps are monotonically increasing or equal
      if (_auditLog[i].timestamp.isBefore(_auditLog[i - 1].timestamp)) {
        return false; // Time anomaly detected
      }
    }
    return true;
  }

  /// Clear audit log (should only be used for testing)
  void clearAuditLog() {
    _auditLog.clear();
  }
}

/// Immutable audit log entry
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String complaintId;
  final AuditActionType actionType;
  final String actorId; // Who performed the action (officer ID or SYSTEM)
  final ActorType actorType;
  final String description;
  final Map<String, dynamic> metadata;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.complaintId,
    required this.actionType,
    required this.actorId,
    required this.actorType,
    required this.description,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'complaintId': complaintId,
        'actionType': actionType.toString(),
        'actorId': actorId,
        'actorType': actorType.toString(),
        'description': description,
        'metadata': metadata,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        complaintId: json['complaintId'],
        actionType: AuditActionType.values.firstWhere(
          (e) => e.toString() == json['actionType'],
        ),
        actorId: json['actorId'],
        actorType: ActorType.values.firstWhere(
          (e) => e.toString() == json['actorType'],
        ),
        description: json['description'],
        metadata: Map<String, dynamic>.from(json['metadata']),
      );

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] $actorId: $description';
}

/// Types of audit actions
enum AuditActionType {
  decision,
  stateTransition,
  assignment,
  escalation,
  slaEvent,
  jurisdictionResolution,
  custom,
}

/// Types of actors
enum ActorType {
  system,
  officer,
  citizen,
  admin,
}

/// Audit report for a complaint
class AuditReport {
  final String complaintId;
  final int totalEvents;
  final DateTime? firstEvent;
  final DateTime? lastEvent;
  final Map<AuditActionType, int> eventsByType;
  final List<AuditLogEntry> timeline;

  AuditReport({
    required this.complaintId,
    required this.totalEvents,
    required this.firstEvent,
    required this.lastEvent,
    required this.eventsByType,
    required this.timeline,
  });

  Duration? get totalDuration =>
      firstEvent != null && lastEvent != null
          ? lastEvent!.difference(firstEvent!)
          : null;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Audit Report for Complaint: $complaintId');
    buffer.writeln('Total Events: $totalEvents');
    buffer.writeln('First Event: $firstEvent');
    buffer.writeln('Last Event: $lastEvent');
    buffer.writeln('Duration: ${totalDuration ?? "N/A"}');
    buffer.writeln('\nEvents by Type:');
    eventsByType.forEach((type, count) {
      buffer.writeln('  $type: $count');
    });
    return buffer.toString();
  }
}
