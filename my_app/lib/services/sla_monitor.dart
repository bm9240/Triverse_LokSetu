import 'dart:async';
import '../models/autogov_complaint.dart';
import 'audit_log_service.dart';
import 'escalation_engine.dart';

/// Time-Driven SLA Monitor
/// Asynchronously monitors SLA deadlines and triggers escalations
class SLAMonitor {
  static final SLAMonitor _instance = SLAMonitor._internal();
  factory SLAMonitor() => _instance;
  SLAMonitor._internal();

  final AuditLogService _auditLog = AuditLogService();
  final EscalationEngine _escalationEngine = EscalationEngine();

  // Active timers for each complaint
  final Map<String, Timer> _activeTimers = {};
  
  // Tracked complaints with SLA
  final Map<String, SLATracking> _slaTracking = {};

  // Check interval for SLA breaches (in production, this could be minutes)
  Duration checkInterval = const Duration(seconds: 30);

  // Background monitoring timer
  Timer? _monitoringTimer;

  /// Start SLA timer when complaint is assigned
  void startSLA(AutoGovComplaintExtension complaint) {
    if (complaint.slaDeadline == null) {
      throw StateError('SLA deadline not set for complaint ${complaint.complaintId}');
    }

    // Create SLA tracking record
    final tracking = SLATracking(
      complaintId: complaint.complaintId,
      startTime: DateTime.now(),
      deadline: complaint.slaDeadline!,
      priorityLevel: complaint.priorityLevel!,
      department: complaint.assignedDepartment!,
      officerId: complaint.assignedOfficerId,
    );

    _slaTracking[complaint.complaintId] = tracking;

    // Log SLA start
    _auditLog.logSLAEvent(
      complaintId: complaint.complaintId,
      eventType: 'SLA_STARTED',
      deadline: complaint.slaDeadline!,
      metadata: {
        'priority': complaint.priorityLevel.toString(),
        'duration': complaint.slaDuration.toString(),
      },
    );

    // Start monitoring
    _startComplaintTimer(complaint);
  }

  /// Stop SLA timer (when complaint is resolved)
  void stopSLA(String complaintId) {
    // Cancel timer
    _activeTimers[complaintId]?.cancel();
    _activeTimers.remove(complaintId);

    // Mark as completed
    final tracking = _slaTracking[complaintId];
    if (tracking != null) {
      tracking.completed = true;
      tracking.completionTime = DateTime.now();

      // Log SLA completion
      _auditLog.logSLAEvent(
        complaintId: complaintId,
        eventType: 'SLA_COMPLETED',
        deadline: tracking.deadline,
        metadata: {
          'completion_time': tracking.completionTime.toString(),
          'time_taken': tracking.completionTime!.difference(tracking.startTime).toString(),
          'breached': tracking.breached.toString(),
        },
      );
    }
  }

  /// Start background timer for a specific complaint
  void _startComplaintTimer(AutoGovComplaintExtension complaint) {
    final complaintId = complaint.complaintId;
    
    // Cancel existing timer if any
    _activeTimers[complaintId]?.cancel();

    // Calculate time until deadline
    final timeUntilDeadline = complaint.slaDeadline!.difference(DateTime.now());

    if (timeUntilDeadline.isNegative) {
      // Already breached
      _handleSLABreach(complaint);
      return;
    }

    // Set timer to trigger at deadline
    _activeTimers[complaintId] = Timer(timeUntilDeadline, () {
      _handleSLABreach(complaint);
    });
  }

  /// Handle SLA breach event
  void _handleSLABreach(AutoGovComplaintExtension complaint) {
    final tracking = _slaTracking[complaint.complaintId];
    if (tracking == null || tracking.completed) {
      return; // Already completed
    }

    if (tracking.breached) {
      return; // Already handled
    }

    // Mark as breached
    tracking.breached = true;
    tracking.breachTime = DateTime.now();

    // Log breach
    _auditLog.logSLAEvent(
      complaintId: complaint.complaintId,
      eventType: 'SLA_BREACHED',
      deadline: complaint.slaDeadline!,
      metadata: {
        'breach_time': tracking.breachTime.toString(),
        'overdue_by': DateTime.now().difference(complaint.slaDeadline!).toString(),
        'priority': complaint.priorityLevel.toString(),
      },
    );

    // Trigger escalation
    _escalationEngine.triggerEscalation(
      complaint,
      'SLA breach: Deadline exceeded',
    );
  }

  /// Start global monitoring loop
  void startGlobalMonitoring() {
    if (_monitoringTimer != null && _monitoringTimer!.isActive) {
      return; // Already running
    }

    _monitoringTimer = Timer.periodic(checkInterval, (_) {
      _checkAllSLAs();
    });
  }

  /// Stop global monitoring loop
  void stopGlobalMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Periodic check of all SLAs
  void _checkAllSLAs() {
    final now = DateTime.now();

    for (final tracking in _slaTracking.values) {
      if (tracking.completed || tracking.breached) {
        continue; // Skip completed or already breached
      }

      // Check if deadline passed
      if (now.isAfter(tracking.deadline)) {
        // Find complaint and trigger breach
        final complaintId = tracking.complaintId;
        _auditLog.logSLAEvent(
          complaintId: complaintId,
          eventType: 'SLA_BREACHED',
          deadline: tracking.deadline,
          metadata: {
            'detected_at': now.toString(),
            'overdue_by': now.difference(tracking.deadline).toString(),
          },
        );

        tracking.breached = true;
        tracking.breachTime = now;
      }
      // Warn if approaching deadline (e.g., 80% time elapsed)
      else {
        final totalDuration = tracking.deadline.difference(tracking.startTime);
        final elapsed = now.difference(tracking.startTime);
        final percentElapsed = elapsed.inMilliseconds / totalDuration.inMilliseconds;

        if (percentElapsed >= 0.8 && !tracking.warningIssued) {
          _issueWarning(tracking);
        }
      }
    }
  }

  /// Issue warning when approaching deadline
  void _issueWarning(SLATracking tracking) {
    tracking.warningIssued = true;

    _auditLog.logSLAEvent(
      complaintId: tracking.complaintId,
      eventType: 'SLA_WARNING',
      deadline: tracking.deadline,
      metadata: {
        'time_remaining': tracking.deadline.difference(DateTime.now()).toString(),
        'priority': tracking.priorityLevel.toString(),
      },
    );
  }

  /// Get SLA status for a complaint
  SLAStatus? getSLAStatus(String complaintId) {
    final tracking = _slaTracking[complaintId];
    if (tracking == null) {
      return null;
    }

    final now = DateTime.now();
    final timeRemaining = tracking.deadline.difference(now);
    final totalDuration = tracking.deadline.difference(tracking.startTime);
    final elapsed = now.difference(tracking.startTime);

    return SLAStatus(
      complaintId: complaintId,
      startTime: tracking.startTime,
      deadline: tracking.deadline,
      timeRemaining: timeRemaining,
      percentComplete: elapsed.inMilliseconds / totalDuration.inMilliseconds,
      breached: tracking.breached,
      completed: tracking.completed,
    );
  }

  /// Get all active SLA trackings
  List<SLATracking> getActiveSLAs() {
    return _slaTracking.values
        .where((t) => !t.completed)
        .toList();
  }

  /// Get breached SLAs
  List<SLATracking> getBreachedSLAs() {
    return _slaTracking.values
        .where((t) => t.breached && !t.completed)
        .toList();
  }

  /// Clean up completed trackings (for memory management)
  void cleanupCompletedSLAs({Duration retentionPeriod = const Duration(days: 7)}) {
    final cutoffTime = DateTime.now().subtract(retentionPeriod);
    
    _slaTracking.removeWhere((id, tracking) {
      if (tracking.completed && tracking.completionTime != null) {
        return tracking.completionTime!.isBefore(cutoffTime);
      }
      return false;
    });
  }

  /// Dispose all resources
  void dispose() {
    stopGlobalMonitoring();
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _slaTracking.clear();
  }
}

/// SLA tracking record
class SLATracking {
  final String complaintId;
  final DateTime startTime;
  final DateTime deadline;
  final PriorityLevel priorityLevel;
  final String department;
  final String? officerId;

  bool breached;
  bool completed;
  bool warningIssued;
  DateTime? breachTime;
  DateTime? completionTime;

  SLATracking({
    required this.complaintId,
    required this.startTime,
    required this.deadline,
    required this.priorityLevel,
    required this.department,
    this.officerId,
    this.breached = false,
    this.completed = false,
    this.warningIssued = false,
    this.breachTime,
    this.completionTime,
  });

  Map<String, dynamic> toJson() => {
        'complaintId': complaintId,
        'startTime': startTime.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'priorityLevel': priorityLevel.toString(),
        'department': department,
        'officerId': officerId,
        'breached': breached,
        'completed': completed,
        'warningIssued': warningIssued,
        'breachTime': breachTime?.toIso8601String(),
        'completionTime': completionTime?.toIso8601String(),
      };
}

/// Current SLA status snapshot
class SLAStatus {
  final String complaintId;
  final DateTime startTime;
  final DateTime deadline;
  final Duration timeRemaining;
  final double percentComplete;
  final bool breached;
  final bool completed;

  SLAStatus({
    required this.complaintId,
    required this.startTime,
    required this.deadline,
    required this.timeRemaining,
    required this.percentComplete,
    required this.breached,
    required this.completed,
  });

  String get statusText {
    if (completed) return 'Completed';
    if (breached) return 'Breached';
    if (percentComplete >= 0.8) return 'At Risk';
    return 'On Track';
  }

  @override
  String toString() {
    return 'SLA Status: $statusText | Time Remaining: ${timeRemaining.inHours}h';
  }
}
