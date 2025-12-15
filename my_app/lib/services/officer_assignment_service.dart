import '../models/autogov_complaint.dart';
import 'audit_log_service.dart';
import 'officers_firestore_service.dart';

/// Load-Aware Officer Assignment Service
/// Assigns complaints to officers based on workload, performance, and reliability
class OfficerAssignmentService {
  static final OfficerAssignmentService _instance = OfficerAssignmentService._internal();
  factory OfficerAssignmentService() => _instance;
  OfficerAssignmentService._internal();

  final AuditLogService _auditLog = AuditLogService();
  final OfficersFirestoreService _firestoreOfficers = OfficersFirestoreService();

  // Officer workload tracking
  final Map<String, List<String>> _officerWorkload = {}; // officerId -> complaint IDs

  /// Assign complaint to best available officer using dynamic Firestore queries
  Future<AssignmentResult> assignOfficer(
    AutoGovComplaintExtension complaint,
    String department,
  ) async {
    // Get available officers from Firestore (filtered by availability, ordered by workload)
    final eligibleOfficers = await _firestoreOfficers.getAvailableOfficersByDepartment(department);

    if (eligibleOfficers.isEmpty) {
      return AssignmentResult(
        success: false,
        complaintId: complaint.complaintId,
        errorMessage: 'No available officers in department: $department',
      );
    }

    // Select best officer (Firestore already ordered by activeComplaints, take first)
    final bestOfficer = eligibleOfficers.first;

    // Assign complaint
    complaint.assignedOfficerId = bestOfficer.id;
    
    // Update local workload tracking
    _officerWorkload.putIfAbsent(bestOfficer.id, () => []);
    _officerWorkload[bestOfficer.id]!.add(complaint.complaintId);

    // Increment officer's activeComplaints in Firestore
    await _firestoreOfficers.incrementOfficerWorkload(bestOfficer.id);

    // Log assignment
    _auditLog.logAssignment(
      complaintId: complaint.complaintId,
      officerId: bestOfficer.id,
      department: department,
      reason: _generateAssignmentReason(bestOfficer),
    );

    print('✅ Officer assigned: ${bestOfficer.name} (${bestOfficer.id}) to complaint ${complaint.complaintId}');
    print('   Department: $department');
    print('   Current workload: ${bestOfficer.activeComplaints + 1} complaints');

    return AssignmentResult(
      success: true,
      complaintId: complaint.complaintId,
      officerId: bestOfficer.id,
      officerName: bestOfficer.name,
      department: department,
    );
  }

  /// Select best officer based on multiple criteria
  Officer _selectBestOfficer(List<Officer> officers) {
    // Calculate score for each officer
    final scoredOfficers = officers.map((officer) {
      final score = _calculateOfficerScore(officer);
      return ScoredOfficer(officer: officer, score: score);
    }).toList();

    // Sort by score (descending)
    scoredOfficers.sort((a, b) => b.score.compareTo(a.score));

    return scoredOfficers.first.officer;
  }

  /// Calculate officer suitability score (based on Firestore Officer properties)
  double _calculateOfficerScore(Officer officer) {
    double score = 0.0;

    // Factor 1: Workload (lower activeComplaints is better) - 40% weight
    final workloadScore = 10.0 - (officer.activeComplaints * 2.0).clamp(0, 10);
    score += workloadScore * 0.4;

    // Factor 2: Reliability score - 30% weight (0-1 scale converted to 0-10)
    score += (officer.reliability * 10.0) * 0.3;

    // Factor 3: Average resolution time (faster is better) - 30% weight
    final resolutionScore = _calculateResolutionScore(officer.avgResolutionTime);
    score += resolutionScore * 0.3;

    return score;
  }

  /// Calculate resolution time score (0-10, higher is better)
  double _calculateResolutionScore(double avgResolutionHours) {
    // Ideal resolution time: 24 hours
    if (avgResolutionHours <= 24) {
      return 10.0;
    } else if (avgResolutionHours <= 48) {
      return 7.0;
    } else if (avgResolutionHours <= 72) {
      return 5.0;
    } else {
      return 2.0;
    }
  }



  /// Remove complaint from officer's workload (when resolved)
  Future<void> releaseOfficer(String officerId, String complaintId) async {
    // Update local tracking
    _officerWorkload[officerId]?.remove(complaintId);
    
    // Decrement officer's activeComplaints in Firestore
    await _firestoreOfficers.decrementOfficerWorkload(officerId);
    
    print('✅ Officer released: $officerId from complaint $complaintId');
  }

  /// Generate assignment reason
  String _generateAssignmentReason(Officer officer) {
    return 'Assigned based on load (${officer.activeComplaints}), '
           'reliability (${(officer.reliability * 100).toStringAsFixed(0)}%), '
           'avg resolution ${officer.avgResolutionTime.toStringAsFixed(1)}h';
  }
}

/// Scored officer for selection
class ScoredOfficer {
  final Officer officer;
  final double score;

  ScoredOfficer({required this.officer, required this.score});
}

/// Assignment result
class AssignmentResult {
  final bool success;
  final String complaintId;
  final String? officerId;
  final String? officerName;
  final String? department;
  final String? errorMessage;

  AssignmentResult({
    required this.success,
    required this.complaintId,
    this.officerId,
    this.officerName,
    this.department,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return 'Assigned to: $officerName (ID: $officerId) in $department';
    } else {
      return 'Assignment failed: $errorMessage';
    }
  }
}
