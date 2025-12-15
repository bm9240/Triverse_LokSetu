import '../models/autogov_complaint.dart';
import 'audit_log_service.dart';
import 'officer_assignment_service.dart';
import 'package:uuid/uuid.dart';

/// Autonomous Escalation Engine
/// Automatically escalates complaints through authority hierarchy
class EscalationEngine {
  static final EscalationEngine _instance = EscalationEngine._internal();
  factory EscalationEngine() => _instance;
  EscalationEngine._internal();

  final AuditLogService _auditLog = AuditLogService();
  final OfficerAssignmentService _officerService = OfficerAssignmentService();
  final Uuid _uuid = const Uuid();

  /// Trigger escalation for a complaint
  EscalationResult triggerEscalation(
    AutoGovComplaintExtension complaint,
    String reason,
  ) {
    // Determine current escalation level
    final currentLevel = _determineCurrentLevel(complaint);

    // Check if escalation is possible
    final nextLevel = currentLevel.nextLevel;
    if (nextLevel == null) {
      return EscalationResult(
        success: false,
        complaintId: complaint.complaintId,
        fromLevel: currentLevel,
        toLevel: currentLevel,
        errorMessage: 'Already at highest escalation level',
      );
    }

    // Perform escalation
    return _performEscalation(
      complaint,
      currentLevel,
      nextLevel,
      reason,
    );
  }

  /// Perform the actual escalation
  EscalationResult _performEscalation(
    AutoGovComplaintExtension complaint,
    EscalationLevel fromLevel,
    EscalationLevel toLevel,
    String reason,
  ) {
    // Store previous officer
    final previousOfficerId = complaint.assignedOfficerId;

    // Increase priority on escalation
    final newPriority = _increasePriority(complaint.priorityLevel!);
    complaint.priorityLevel = newPriority;

    // Adjust SLA for new priority
    final newSLA = newPriority.defaultSLA;
    complaint.slaDuration = newSLA;
    complaint.slaDeadline = DateTime.now().add(newSLA);

    // Assign to higher authority
    String? newOfficerId;
    if (toLevel == EscalationLevel.departmentHead) {
      newOfficerId = _officerService.getDepartmentHead(complaint.assignedDepartment!);
    } else if (toLevel == EscalationLevel.districtAuthority) {
      newOfficerId = _officerService.getDistrictAuthority(complaint.location.city);
    }

    complaint.assignedOfficerId = newOfficerId;

    // Create escalation record
    final escalationRecord = EscalationRecord(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      fromLevel: fromLevel,
      toLevel: toLevel,
      reason: reason,
      fromOfficerId: previousOfficerId,
      toOfficerId: newOfficerId,
      newPriority: newPriority,
    );

    complaint.escalationHistory.add(escalationRecord);

    // Log escalation
    _auditLog.logEscalation(
      complaintId: complaint.complaintId,
      fromLevel: fromLevel,
      toLevel: toLevel,
      reason: reason,
      newPriority: newPriority,
      metadata: {
        'previous_officer': previousOfficerId ?? 'none',
        'new_officer': newOfficerId ?? 'none',
        'new_sla': newSLA.toString(),
      },
    );

    return EscalationResult(
      success: true,
      complaintId: complaint.complaintId,
      fromLevel: fromLevel,
      toLevel: toLevel,
      newOfficerId: newOfficerId,
      newPriority: newPriority,
    );
  }

  /// Determine current escalation level based on complaint state
  EscalationLevel _determineCurrentLevel(AutoGovComplaintExtension complaint) {
    // Check escalation history
    if (complaint.escalationHistory.isNotEmpty) {
      return complaint.escalationHistory.last.toLevel;
    }

    // Default to officer level
    return EscalationLevel.officer;
  }

  /// Increase priority level during escalation
  PriorityLevel _increasePriority(PriorityLevel currentPriority) {
    final currentIndex = PriorityLevel.values.indexOf(currentPriority);
    if (currentIndex > 0) {
      return PriorityLevel.values[currentIndex - 1]; // Higher priority = lower number
    }
    return currentPriority; // Already at highest
  }

  /// Check if complaint should be escalated based on multiple factors
  bool shouldEscalate(AutoGovComplaintExtension complaint) {
    // Already at highest level
    final currentLevel = _determineCurrentLevel(complaint);
    if (currentLevel.nextLevel == null) {
      return false;
    }

    // Check various escalation triggers
    return _checkEscalationTriggers(complaint);
  }

  /// Check various triggers for escalation
  bool _checkEscalationTriggers(AutoGovComplaintExtension complaint) {
    // Trigger 1: SLA breach
    if (complaint.slaDeadline != null && 
        DateTime.now().isAfter(complaint.slaDeadline!)) {
      return true;
    }

    // Trigger 2: Multiple escalations already (stuck complaint)
    if (complaint.escalationHistory.length >= 2) {
      final lastEscalation = complaint.escalationHistory.last;
      final timeSinceLastEscalation = DateTime.now().difference(lastEscalation.timestamp);
      
      // If still not resolved after 48 hours at current level
      if (timeSinceLastEscalation.inHours >= 48) {
        return true;
      }
    }

    // Trigger 3: High priority complaints not in progress
    if (complaint.priorityLevel == PriorityLevel.p1 && 
        complaint.state == ComplaintState.assigned) {
      final timeSinceAssignment = DateTime.now().difference(complaint.timestamp);
      // P1 should start within 2 hours
      if (timeSinceAssignment.inHours >= 2) {
        return true;
      }
    }

    return false;
  }

  /// Auto-escalate stuck complaints (to be called periodically)
  List<EscalationResult> autoEscalateStuckComplaints(
    List<AutoGovComplaintExtension> complaints,
  ) {
    final results = <EscalationResult>[];

    for (final complaint in complaints) {
      if (complaint.state == ComplaintState.closed) {
        continue; // Skip closed complaints
      }

      if (shouldEscalate(complaint)) {
        final reason = _determineAutoEscalationReason(complaint);
        final result = triggerEscalation(complaint, reason);
        if (result.success) {
          results.add(result);
        }
      }
    }

    return results;
  }

  /// Determine reason for auto-escalation
  String _determineAutoEscalationReason(AutoGovComplaintExtension complaint) {
    if (complaint.slaDeadline != null && 
        DateTime.now().isAfter(complaint.slaDeadline!)) {
      return 'Automatic escalation: SLA deadline exceeded';
    }

    if (complaint.escalationHistory.length >= 2) {
      return 'Automatic escalation: Complaint stuck at current level';
    }

    if (complaint.priorityLevel == PriorityLevel.p1) {
      return 'Automatic escalation: Critical complaint not progressing';
    }

    return 'Automatic escalation: Review required';
  }

  /// Get escalation history for a complaint
  List<EscalationRecord> getEscalationHistory(String complaintId) {
    final entries = _auditLog.getComplaintHistory(complaintId)
        .where((e) => e.actionType == AuditActionType.escalation)
        .toList();

    return entries.map((e) {
      final metadata = e.metadata;
      return EscalationRecord(
        id: e.id,
        timestamp: e.timestamp,
        fromLevel: EscalationLevel.values.firstWhere(
          (level) => level.toString() == metadata['from_level'],
        ),
        toLevel: EscalationLevel.values.firstWhere(
          (level) => level.toString() == metadata['to_level'],
        ),
        reason: e.description,
        fromOfficerId: metadata['previous_officer'],
        toOfficerId: metadata['new_officer'],
        newPriority: PriorityLevel.values.firstWhere(
          (p) => p.toString() == metadata['new_priority'],
        ),
      );
    }).toList();
  }

  /// Get statistics on escalations
  EscalationStats getEscalationStats(List<AutoGovComplaintExtension> complaints) {
    int totalEscalations = 0;
    int atOfficerLevel = 0;
    int atDepartmentHead = 0;
    int atDistrictAuthority = 0;

    for (final complaint in complaints) {
      totalEscalations += complaint.escalationHistory.length;

      final currentLevel = _determineCurrentLevel(complaint);
      switch (currentLevel) {
        case EscalationLevel.officer:
          atOfficerLevel++;
          break;
        case EscalationLevel.departmentHead:
          atDepartmentHead++;
          break;
        case EscalationLevel.districtAuthority:
          atDistrictAuthority++;
          break;
      }
    }

    return EscalationStats(
      totalComplaints: complaints.length,
      totalEscalations: totalEscalations,
      atOfficerLevel: atOfficerLevel,
      atDepartmentHead: atDepartmentHead,
      atDistrictAuthority: atDistrictAuthority,
    );
  }
}

/// Result of escalation attempt
class EscalationResult {
  final bool success;
  final String complaintId;
  final EscalationLevel fromLevel;
  final EscalationLevel toLevel;
  final String? newOfficerId;
  final PriorityLevel? newPriority;
  final String? errorMessage;

  EscalationResult({
    required this.success,
    required this.complaintId,
    required this.fromLevel,
    required this.toLevel,
    this.newOfficerId,
    this.newPriority,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return 'Escalated: ${fromLevel.displayName} → ${toLevel.displayName} | New Priority: ${newPriority?.displayName}';
    } else {
      return 'Escalation failed: $errorMessage';
    }
  }
}

/// Escalation statistics
class EscalationStats {
  final int totalComplaints;
  final int totalEscalations;
  final int atOfficerLevel;
  final int atDepartmentHead;
  final int atDistrictAuthority;

  EscalationStats({
    required this.totalComplaints,
    required this.totalEscalations,
    required this.atOfficerLevel,
    required this.atDepartmentHead,
    required this.atDistrictAuthority,
  });

  double get averageEscalationsPerComplaint =>
      totalComplaints > 0 ? totalEscalations / totalComplaints : 0.0;

  @override
  String toString() {
    return '''
Escalation Stats:
- Total Complaints: $totalComplaints
- Total Escalations: $totalEscalations
- Average Escalations: ${averageEscalationsPerComplaint.toStringAsFixed(2)}
- At Officer Level: $atOfficerLevel
- At Department Head: $atDepartmentHead
- At District Authority: $atDistrictAuthority
''';
  }
}
