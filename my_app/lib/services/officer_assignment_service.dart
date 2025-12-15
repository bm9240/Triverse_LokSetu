import '../models/autogov_complaint.dart';
import 'audit_log_service.dart';

/// Load-Aware Officer Assignment Service
/// Assigns complaints to officers based on workload, performance, and reliability
class OfficerAssignmentService {
  static final OfficerAssignmentService _instance = OfficerAssignmentService._internal();
  factory OfficerAssignmentService() => _instance;
  OfficerAssignmentService._internal();

  final AuditLogService _auditLog = AuditLogService();

  // Officer registry
  final Map<String, Officer> _officers = {};
  
  // Officer workload tracking
  final Map<String, List<String>> _officerWorkload = {}; // officerId -> complaint IDs

  /// Initialize with officer data
  OfficerAssignmentService initialize() {
    _initializeOfficers();
    return this;
  }

  /// Assign complaint to best available officer
  AssignmentResult assignOfficer(
    AutoGovComplaintExtension complaint,
    String department,
  ) {
    // Get officers in department
    final eligibleOfficers = _getOfficersInDepartment(department);

    if (eligibleOfficers.isEmpty) {
      return AssignmentResult(
        success: false,
        complaintId: complaint.complaintId,
        errorMessage: 'No officers available in department: $department',
      );
    }

    // Select best officer based on criteria
    final bestOfficer = _selectBestOfficer(
      eligibleOfficers,
      complaint.priorityLevel!,
    );

    // Assign complaint
    complaint.assignedOfficerId = bestOfficer.id;
    
    // Update workload
    _officerWorkload.putIfAbsent(bestOfficer.id, () => []);
    _officerWorkload[bestOfficer.id]!.add(complaint.complaintId);

    // Log assignment
    _auditLog.logAssignment(
      complaintId: complaint.complaintId,
      officerId: bestOfficer.id,
      department: department,
      reason: _generateAssignmentReason(bestOfficer),
    );

    return AssignmentResult(
      success: true,
      complaintId: complaint.complaintId,
      officerId: bestOfficer.id,
      officerName: bestOfficer.name,
      department: department,
    );
  }

  /// Select best officer based on multiple criteria
  Officer _selectBestOfficer(
    List<Officer> officers,
    PriorityLevel priority,
  ) {
    // Calculate score for each officer
    final scoredOfficers = officers.map((officer) {
      final score = _calculateOfficerScore(officer, priority);
      return ScoredOfficer(officer: officer, score: score);
    }).toList();

    // Sort by score (descending)
    scoredOfficers.sort((a, b) => b.score.compareTo(a.score));

    return scoredOfficers.first.officer;
  }

  /// Calculate officer suitability score
  double _calculateOfficerScore(Officer officer, PriorityLevel priority) {
    double score = 0.0;

    // Factor 1: Workload (lower is better) - 40% weight
    final currentWorkload = _officerWorkload[officer.id]?.length ?? 0;
    final workloadScore = _calculateWorkloadScore(currentWorkload, officer.maxCapacity);
    score += workloadScore * 0.4;

    // Factor 2: Reliability score - 30% weight
    score += officer.reliabilityScore * 0.3;

    // Factor 3: Average resolution time (faster is better) - 20% weight
    final resolutionScore = _calculateResolutionScore(officer.avgResolutionHours);
    score += resolutionScore * 0.2;

    // Factor 4: Priority specialization - 10% weight
    if (_isSpecializedForPriority(officer, priority)) {
      score += 10.0 * 0.1;
    }

    return score;
  }

  /// Calculate workload score (0-10, higher is better)
  double _calculateWorkloadScore(int currentWorkload, int maxCapacity) {
    if (currentWorkload >= maxCapacity) {
      return 0.0; // Overloaded
    }

    final utilization = currentWorkload / maxCapacity;
    return (1.0 - utilization) * 10.0;
  }

  /// Calculate resolution time score (0-10, higher is better)
  double _calculateResolutionScore(double avgResolutionHours) {
    // Ideal resolution time: 24 hours
    // Penalize for slower resolution
    if (avgResolutionHours <= 24) {
      return 10.0;
    } else if (avgResolutionHours <= 48) {
      return 7.0;
    } else if (avgResolutionHours <= 72) {
      return 5.0;
    } else {
      return 3.0;
    }
  }

  /// Check if officer specializes in priority level
  bool _isSpecializedForPriority(Officer officer, PriorityLevel priority) {
    return officer.specialization.contains(priority);
  }

  /// Get officers in specific department
  List<Officer> _getOfficersInDepartment(String department) {
    return _officers.values
        .where((officer) => officer.department == department && officer.isActive)
        .toList();
  }

  /// Remove complaint from officer's workload (when resolved)
  void releaseOfficer(String officerId, String complaintId) {
    _officerWorkload[officerId]?.remove(complaintId);
  }

  /// Get department head
  String? getDepartmentHead(String department) {
    final head = _officers.values.firstWhere(
      (officer) => officer.department == department && officer.isDepartmentHead,
      orElse: () => Officer(
        id: 'HEAD_${department.hashCode}',
        name: '$department Head',
        department: department,
        designation: 'Department Head',
        isDepartmentHead: true,
      ),
    );
    return head.id;
  }

  /// Get district authority
  String? getDistrictAuthority(String city) {
    final authority = _officers.values.firstWhere(
      (officer) => officer.city == city && officer.isDistrictAuthority,
      orElse: () => Officer(
        id: 'DISTRICT_${city.hashCode}',
        name: '$city District Magistrate',
        department: 'Administration',
        designation: 'District Authority',
        city: city,
        isDistrictAuthority: true,
      ),
    );
    return authority.id;
  }

  /// Get officer by ID
  Officer? getOfficer(String officerId) {
    return _officers[officerId];
  }

  /// Get officer workload
  int getOfficerWorkload(String officerId) {
    return _officerWorkload[officerId]?.length ?? 0;
  }

  /// Get all officers
  List<Officer> getAllOfficers() {
    return _officers.values.toList();
  }

  /// Update officer performance metrics
  void updateOfficerMetrics(
    String officerId, {
    double? reliabilityScore,
    double? avgResolutionHours,
  }) {
    final officer = _officers[officerId];
    if (officer != null) {
      if (reliabilityScore != null) {
        officer.reliabilityScore = reliabilityScore.clamp(0.0, 10.0);
      }
      if (avgResolutionHours != null) {
        officer.avgResolutionHours = avgResolutionHours;
      }
    }
  }

  /// Generate assignment reasoning
  String _generateAssignmentReason(Officer officer) {
    final workload = _officerWorkload[officer.id]?.length ?? 0;
    return 'Assigned to ${officer.name}: '
           'Workload: $workload/${officer.maxCapacity}, '
           'Reliability: ${officer.reliabilityScore.toStringAsFixed(1)}/10, '
           'Avg Resolution: ${officer.avgResolutionHours.toStringAsFixed(1)}h';
  }

  /// Initialize sample officers
  void _initializeOfficers() {
    // Public Works Department
    _registerOfficer(Officer(
      id: 'PWD_001',
      name: 'Rajesh Kumar',
      department: 'Public Works Department',
      designation: 'Junior Engineer',
      reliabilityScore: 8.5,
      avgResolutionHours: 36.0,
      maxCapacity: 10,
      specialization: [PriorityLevel.p3, PriorityLevel.p4],
    ));

    _registerOfficer(Officer(
      id: 'PWD_002',
      name: 'Priya Sharma',
      department: 'Public Works Department',
      designation: 'Senior Engineer',
      reliabilityScore: 9.2,
      avgResolutionHours: 24.0,
      maxCapacity: 15,
      specialization: [PriorityLevel.p1, PriorityLevel.p2],
    ));

    // Water Supply & Sanitation
    _registerOfficer(Officer(
      id: 'WSS_001',
      name: 'Anil Verma',
      department: 'Water Supply & Sanitation',
      designation: 'Water Inspector',
      reliabilityScore: 7.8,
      avgResolutionHours: 48.0,
      maxCapacity: 12,
      specialization: [PriorityLevel.p2, PriorityLevel.p3],
    ));

    // Electricity Board
    _registerOfficer(Officer(
      id: 'EB_001',
      name: 'Sanjay Patel',
      department: 'Electricity Board',
      designation: 'Line Inspector',
      reliabilityScore: 8.0,
      avgResolutionHours: 18.0,
      maxCapacity: 8,
      specialization: [PriorityLevel.p1],
    ));

    // Add more officers as needed
  }

  /// Register an officer
  void _registerOfficer(Officer officer) {
    _officers[officer.id] = officer;
  }

  /// Register custom officer
  void registerOfficer(Officer officer) {
    _registerOfficer(officer);
  }
}

/// Officer model
class Officer {
  final String id;
  final String name;
  final String department;
  final String designation;
  final String? city;
  final bool isDepartmentHead;
  final bool isDistrictAuthority;
  final bool isActive;
  
  double reliabilityScore; // 0-10 scale
  double avgResolutionHours;
  final int maxCapacity; // Max concurrent complaints
  final List<PriorityLevel> specialization;

  Officer({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    this.city,
    this.isDepartmentHead = false,
    this.isDistrictAuthority = false,
    this.isActive = true,
    this.reliabilityScore = 7.0,
    this.avgResolutionHours = 48.0,
    this.maxCapacity = 10,
    List<PriorityLevel>? specialization,
  }) : specialization = specialization ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'designation': designation,
        'city': city,
        'isDepartmentHead': isDepartmentHead,
        'isDistrictAuthority': isDistrictAuthority,
        'isActive': isActive,
        'reliabilityScore': reliabilityScore,
        'avgResolutionHours': avgResolutionHours,
        'maxCapacity': maxCapacity,
        'specialization': specialization.map((p) => p.toString()).toList(),
      };

  @override
  String toString() => '$name ($designation, $department)';
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
