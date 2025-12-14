import '../models/autogov_complaint.dart';
import 'audit_log_service.dart';

/// Complaint Lifecycle State Machine
/// Manages valid state transitions and prevents invalid changes
class ComplaintStateMachine {
  static final ComplaintStateMachine _instance = ComplaintStateMachine._internal();
  factory ComplaintStateMachine() => _instance;
  ComplaintStateMachine._internal();

  final AuditLogService _auditLog = AuditLogService();

  /// Attempt to transition complaint to new state
  /// Returns true if transition is valid and performed, false otherwise
  StateTransitionResult transitionState(
    AutoGovComplaintExtension complaint,
    ComplaintState newState,
    String actorId,
    String reason,
  ) {
    // Check if transition is valid
    if (!complaint.state.canTransitionTo(newState)) {
      return StateTransitionResult(
        success: false,
        previousState: complaint.state,
        newState: complaint.state,
        errorMessage: 'Invalid transition: ${complaint.state.displayName} → ${newState.displayName}',
      );
    }

    // Perform transition
    final previousState = complaint.state;
    complaint.state = newState;

    // Log the transition
    _auditLog.logStateTransition(
      complaintId: complaint.complaintId,
      fromState: previousState,
      toState: newState,
      actorId: actorId,
      reason: reason,
    );

    return StateTransitionResult(
      success: true,
      previousState: previousState,
      newState: newState,
    );
  }

  /// Check if transition is valid without performing it
  bool isTransitionValid(ComplaintState currentState, ComplaintState newState) {
    return currentState.canTransitionTo(newState);
  }

  /// Get all valid next states for current state
  List<ComplaintState> getValidNextStates(ComplaintState currentState) {
    return currentState.validTransitions;
  }

  /// Transition to submitted state (initial state)
  StateTransitionResult submit(
    AutoGovComplaintExtension complaint,
    String actorId,
  ) {
    // This should only be called for new complaints
    if (complaint.state != ComplaintState.submitted) {
      return StateTransitionResult(
        success: false,
        previousState: complaint.state,
        newState: complaint.state,
        errorMessage: 'Complaint already submitted',
      );
    }

    _auditLog.logStateTransition(
      complaintId: complaint.complaintId,
      fromState: complaint.state,
      toState: ComplaintState.submitted,
      actorId: actorId,
      reason: 'Initial submission',
    );

    return StateTransitionResult(
      success: true,
      previousState: complaint.state,
      newState: ComplaintState.submitted,
    );
  }

  /// Transition to assigned state
  StateTransitionResult assign(
    AutoGovComplaintExtension complaint,
    String officerId,
    String assignerId,
  ) {
    return transitionState(
      complaint,
      ComplaintState.assigned,
      assignerId,
      'Assigned to officer: $officerId',
    );
  }

  /// Transition to in-progress state
  StateTransitionResult startWork(
    AutoGovComplaintExtension complaint,
    String officerId,
  ) {
    return transitionState(
      complaint,
      ComplaintState.inProgress,
      officerId,
      'Officer started working on complaint',
    );
  }

  /// Transition to resolved state
  StateTransitionResult resolve(
    AutoGovComplaintExtension complaint,
    String officerId,
    String resolutionNotes,
  ) {
    return transitionState(
      complaint,
      ComplaintState.resolved,
      officerId,
      'Resolved: $resolutionNotes',
    );
  }

  /// Transition to closed state
  StateTransitionResult close(
    AutoGovComplaintExtension complaint,
    String actorId,
    String closureReason,
  ) {
    return transitionState(
      complaint,
      ComplaintState.closed,
      actorId,
      'Closed: $closureReason',
    );
  }

  /// Reopen complaint (from resolved back to in-progress)
  StateTransitionResult reopen(
    AutoGovComplaintExtension complaint,
    String actorId,
    String reason,
  ) {
    if (complaint.state != ComplaintState.resolved) {
      return StateTransitionResult(
        success: false,
        previousState: complaint.state,
        newState: complaint.state,
        errorMessage: 'Can only reopen resolved complaints',
      );
    }

    return transitionState(
      complaint,
      ComplaintState.inProgress,
      actorId,
      'Reopened: $reason',
    );
  }

  /// Reassign complaint (from in-progress back to assigned)
  StateTransitionResult reassign(
    AutoGovComplaintExtension complaint,
    String newOfficerId,
    String assignerId,
    String reason,
  ) {
    if (complaint.state != ComplaintState.inProgress) {
      return StateTransitionResult(
        success: false,
        previousState: complaint.state,
        newState: complaint.state,
        errorMessage: 'Can only reassign complaints that are in progress',
      );
    }

    return transitionState(
      complaint,
      ComplaintState.assigned,
      assignerId,
      'Reassigned to officer $newOfficerId: $reason',
    );
  }

  /// Get state transition history from audit log
  List<AuditLogEntry> getStateHistory(String complaintId) {
    return _auditLog.getComplaintHistory(complaintId)
        .where((entry) => entry.actionType == AuditActionType.stateTransition)
        .toList();
  }

  /// Validate state machine integrity
  bool validateStateMachine() {
    // Ensure all states have proper transitions defined
    for (final state in ComplaintState.values) {
      // Terminal state (closed) should have no transitions
      if (state == ComplaintState.closed) {
        if (state.validTransitions.isNotEmpty) {
          return false;
        }
      }
      // All non-terminal states should have at least one transition
      else {
        if (state.validTransitions.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }
}

/// Result of a state transition attempt
class StateTransitionResult {
  final bool success;
  final ComplaintState previousState;
  final ComplaintState newState;
  final String? errorMessage;

  StateTransitionResult({
    required this.success,
    required this.previousState,
    required this.newState,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return 'Transition successful: ${previousState.displayName} → ${newState.displayName}';
    } else {
      return 'Transition failed: $errorMessage';
    }
  }
}
