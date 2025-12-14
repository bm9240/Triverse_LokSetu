import '../models/autogov_complaint.dart';
import 'decision_engine.dart';
import 'jurisdiction_resolver.dart';
import 'complaint_state_machine.dart';
import 'sla_monitor.dart';
import 'escalation_engine.dart';
import 'officer_assignment_service.dart';
import 'audit_log_service.dart';

/// AutoGov Engine - Main Coordinator
/// Orchestrates all autonomous governance components
class AutoGovEngine {
  static final AutoGovEngine _instance = AutoGovEngine._internal();
  factory AutoGovEngine() => _instance;
  AutoGovEngine._internal();

  // Core components
  final DecisionEngine _decisionEngine = DecisionEngine();
  final JurisdictionResolver _jurisdictionResolver = JurisdictionResolver();
  final ComplaintStateMachine _stateMachine = ComplaintStateMachine();
  final SLAMonitor _slaMonitor = SLAMonitor();
  final EscalationEngine _escalationEngine = EscalationEngine();
  final OfficerAssignmentService _officerService = OfficerAssignmentService();
  final AuditLogService _auditLog = AuditLogService();

  // Active complaints registry
  final Map<String, AutoGovComplaintExtension> _activeComplaints = {};

  bool _initialized = false;

  /// Initialize the AutoGov Engine
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize components
    _jurisdictionResolver.initialize();
    _officerService.initialize();
    
    // Start SLA monitoring
    _slaMonitor.startGlobalMonitoring();

    _initialized = true;
  }

  /// Process a new complaint through the AutoGov pipeline
  Future<ProcessingResult> processComplaint(
    AutoGovComplaintExtension complaint,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Step 1: Make decision (department, priority, SLA)
      final decision = _decisionEngine.makeDecision(complaint);
      
      complaint.assignedDepartment = decision.department;
      complaint.priorityLevel = decision.priority;
      complaint.slaDuration = decision.slaDuration;
      complaint.slaDeadline = DateTime.now().add(decision.slaDuration);

      // Log decision
      _auditLog.logDecision(
        complaintId: complaint.complaintId,
        department: decision.department,
        priority: decision.priority,
        slaDuration: decision.slaDuration,
        reasoning: decision.reasoning,
      );

      // Step 2: Resolve jurisdiction
      final jurisdiction = _jurisdictionResolver.resolveJurisdiction(complaint.location);
      if (jurisdiction != null) {
        _auditLog.logJurisdictionResolution(
          complaintId: complaint.complaintId,
          city: complaint.location.city,
          ward: complaint.location.ward,
          officeId: jurisdiction.id,
          officeName: jurisdiction.name,
        );
      }

      // Step 3: Transition to submitted state (if new)
      if (complaint.state == ComplaintState.submitted) {
        _stateMachine.submit(complaint, 'SYSTEM');
      }

      // Step 4: Assign officer
      final assignment = _officerService.assignOfficer(
        complaint,
        decision.department,
      );

      if (!assignment.success) {
        return ProcessingResult(
          success: false,
          complaintId: complaint.complaintId,
          errorMessage: 'Officer assignment failed: ${assignment.errorMessage}',
        );
      }

      // Step 5: Transition to assigned state
      final stateTransition = _stateMachine.assign(
        complaint,
        assignment.officerId!,
        'SYSTEM',
      );

      if (!stateTransition.success) {
        return ProcessingResult(
          success: false,
          complaintId: complaint.complaintId,
          errorMessage: 'State transition failed: ${stateTransition.errorMessage}',
        );
      }

      // Step 6: Start SLA monitoring
      _slaMonitor.startSLA(complaint);

      // Register complaint
      _activeComplaints[complaint.complaintId] = complaint;

      return ProcessingResult(
        success: true,
        complaintId: complaint.complaintId,
        department: decision.department,
        assignedOfficer: assignment.officerName,
        priority: decision.priority,
        slaDeadline: complaint.slaDeadline,
        governingOffice: jurisdiction?.name,
      );

    } catch (e) {
      return ProcessingResult(
        success: false,
        complaintId: complaint.complaintId,
        errorMessage: 'Processing failed: $e',
      );
    }
  }

  /// Update complaint state
  Future<StateTransitionResult> updateComplaintState(
    String complaintId,
    ComplaintState newState,
    String actorId,
    String reason,
  ) async {
    final complaint = _activeComplaints[complaintId];
    if (complaint == null) {
      return StateTransitionResult(
        success: false,
        previousState: ComplaintState.submitted,
        newState: ComplaintState.submitted,
        errorMessage: 'Complaint not found',
      );
    }

    return _stateMachine.transitionState(complaint, newState, actorId, reason);
  }

  /// Mark complaint as resolved
  Future<void> resolveComplaint(
    String complaintId,
    String officerId,
    String resolutionNotes,
  ) async {
    final complaint = _activeComplaints[complaintId];
    if (complaint == null) return;

    // Transition to resolved
    _stateMachine.resolve(complaint, officerId, resolutionNotes);

    // Stop SLA monitoring
    _slaMonitor.stopSLA(complaintId);

    // Release officer
    if (complaint.assignedOfficerId != null) {
      _officerService.releaseOfficer(complaint.assignedOfficerId!, complaintId);
    }

    // Decrease department workload
    if (complaint.assignedDepartment != null) {
      _decisionEngine.decreaseWorkload(complaint.assignedDepartment!);
    }
  }

  /// Close complaint
  Future<void> closeComplaint(
    String complaintId,
    String actorId,
    String closureReason,
  ) async {
    final complaint = _activeComplaints[complaintId];
    if (complaint == null) return;

    _stateMachine.close(complaint, actorId, closureReason);

    // Remove from active registry
    _activeComplaints.remove(complaintId);
  }

  /// Run periodic escalation check
  Future<List<EscalationResult>> checkAndEscalate() async {
    final activeComplaintsList = _activeComplaints.values.toList();
    return _escalationEngine.autoEscalateStuckComplaints(activeComplaintsList);
  }

  /// Get complaint by ID
  AutoGovComplaintExtension? getComplaint(String complaintId) {
    return _activeComplaints[complaintId];
  }

  /// Get all active complaints
  List<AutoGovComplaintExtension> getActiveComplaints() {
    return _activeComplaints.values.toList();
  }

  /// Get complaints by department
  List<AutoGovComplaintExtension> getComplaintsByDepartment(String department) {
    return _activeComplaints.values
        .where((c) => c.assignedDepartment == department)
        .toList();
  }

  /// Get complaints by officer
  List<AutoGovComplaintExtension> getComplaintsByOfficer(String officerId) {
    return _activeComplaints.values
        .where((c) => c.assignedOfficerId == officerId)
        .toList();
  }

  /// Get complaints by state
  List<AutoGovComplaintExtension> getComplaintsByState(ComplaintState state) {
    return _activeComplaints.values
        .where((c) => c.state == state)
        .toList();
  }

  /// Get SLA status for complaint
  SLAStatus? getSLAStatus(String complaintId) {
    return _slaMonitor.getSLAStatus(complaintId);
  }

  /// Get breached SLAs
  List<SLATracking> getBreachedSLAs() {
    return _slaMonitor.getBreachedSLAs();
  }

  /// Get audit report for complaint
  AuditReport getAuditReport(String complaintId) {
    return _auditLog.generateComplaintReport(complaintId);
  }

  /// Get department workload statistics
  Map<String, int> getDepartmentWorkload() {
    return _decisionEngine.getDepartmentWorkload();
  }

  /// Get escalation statistics
  EscalationStats getEscalationStats() {
    return _escalationEngine.getEscalationStats(_activeComplaints.values.toList());
  }

  /// Get engine statistics
  EngineStatistics getStatistics() {
    final complaints = _activeComplaints.values.toList();
    
    final byState = <ComplaintState, int>{};
    final byPriority = <PriorityLevel, int>{};
    final byDepartment = <String, int>{};

    for (final complaint in complaints) {
      byState[complaint.state] = (byState[complaint.state] ?? 0) + 1;
      if (complaint.priorityLevel != null) {
        byPriority[complaint.priorityLevel!] = 
            (byPriority[complaint.priorityLevel!] ?? 0) + 1;
      }
      if (complaint.assignedDepartment != null) {
        byDepartment[complaint.assignedDepartment!] = 
            (byDepartment[complaint.assignedDepartment!] ?? 0) + 1;
      }
    }

    return EngineStatistics(
      totalActiveComplaints: complaints.length,
      complaintsByState: byState,
      complaintsByPriority: byPriority,
      complaintsByDepartment: byDepartment,
      breachedSLAs: _slaMonitor.getBreachedSLAs().length,
      totalAuditEvents: _auditLog.getLogSize(),
      escalationStats: getEscalationStats(),
    );
  }

  /// Dispose engine resources
  void dispose() {
    _slaMonitor.dispose();
    _activeComplaints.clear();
  }
}

/// Result of complaint processing
class ProcessingResult {
  final bool success;
  final String complaintId;
  final String? department;
  final String? assignedOfficer;
  final PriorityLevel? priority;
  final DateTime? slaDeadline;
  final String? governingOffice;
  final String? errorMessage;

  ProcessingResult({
    required this.success,
    required this.complaintId,
    this.department,
    this.assignedOfficer,
    this.priority,
    this.slaDeadline,
    this.governingOffice,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return '''
Complaint Processed Successfully:
- ID: $complaintId
- Department: $department
- Assigned Officer: $assignedOfficer
- Priority: ${priority?.displayName}
- SLA Deadline: $slaDeadline
- Governing Office: $governingOffice
''';
    } else {
      return 'Processing failed: $errorMessage';
    }
  }
}

/// Engine statistics
class EngineStatistics {
  final int totalActiveComplaints;
  final Map<ComplaintState, int> complaintsByState;
  final Map<PriorityLevel, int> complaintsByPriority;
  final Map<String, int> complaintsByDepartment;
  final int breachedSLAs;
  final int totalAuditEvents;
  final EscalationStats escalationStats;

  EngineStatistics({
    required this.totalActiveComplaints,
    required this.complaintsByState,
    required this.complaintsByPriority,
    required this.complaintsByDepartment,
    required this.breachedSLAs,
    required this.totalAuditEvents,
    required this.escalationStats,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('AutoGov Engine Statistics:');
    buffer.writeln('Total Active Complaints: $totalActiveComplaints');
    buffer.writeln('\nBy State:');
    complaintsByState.forEach((state, count) {
      buffer.writeln('  ${state.displayName}: $count');
    });
    buffer.writeln('\nBy Priority:');
    complaintsByPriority.forEach((priority, count) {
      buffer.writeln('  ${priority.displayName}: $count');
    });
    buffer.writeln('\nBy Department:');
    complaintsByDepartment.forEach((dept, count) {
      buffer.writeln('  $dept: $count');
    });
    buffer.writeln('\nBreached SLAs: $breachedSLAs');
    buffer.writeln('Total Audit Events: $totalAuditEvents');
    buffer.writeln('\n$escalationStats');
    return buffer.toString();
  }
}
