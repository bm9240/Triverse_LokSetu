/// AutoGov Engine - Extended Complaint Model
/// Adds autonomous governance fields without modifying existing Complaint class

class AutoGovComplaintExtension {
  final String complaintId;
  final String category;
  final LocationInfo location;
  final UrgencyLevel urgency;
  final DateTime timestamp;
  
  // AutoGov Engine fields
  String? assignedDepartment;
  PriorityLevel? priorityLevel;
  Duration? slaDuration;
  DateTime? slaDeadline;
  String? assignedOfficerId;
  ComplaintState state;
  List<EscalationRecord> escalationHistory;
  
  AutoGovComplaintExtension({
    required this.complaintId,
    required this.category,
    required this.location,
    required this.urgency,
    required this.timestamp,
    this.assignedDepartment,
    this.priorityLevel,
    this.slaDuration,
    this.slaDeadline,
    this.assignedOfficerId,
    this.state = ComplaintState.submitted,
    List<EscalationRecord>? escalationHistory,
  }) : escalationHistory = escalationHistory ?? [];

  Map<String, dynamic> toJson() => {
        'complaintId': complaintId,
        'category': category,
        'location': location.toJson(),
        'urgency': urgency.toString(),
        'timestamp': timestamp.toIso8601String(),
        'assignedDepartment': assignedDepartment,
        'priorityLevel': priorityLevel?.toString(),
        'slaDuration': slaDuration?.inHours,
        'slaDeadline': slaDeadline?.toIso8601String(),
        'assignedOfficerId': assignedOfficerId,
        'state': state.toString(),
        'escalationHistory': escalationHistory.map((e) => e.toJson()).toList(),
      };

  factory AutoGovComplaintExtension.fromJson(Map<String, dynamic> json) =>
      AutoGovComplaintExtension(
        complaintId: json['complaintId'],
        category: json['category'],
        location: LocationInfo.fromJson(json['location']),
        urgency: UrgencyLevel.values.firstWhere(
          (e) => e.toString() == json['urgency'],
        ),
        timestamp: DateTime.parse(json['timestamp']),
        assignedDepartment: json['assignedDepartment'],
        priorityLevel: json['priorityLevel'] != null
            ? PriorityLevel.values.firstWhere(
                (e) => e.toString() == json['priorityLevel'],
              )
            : null,
        slaDuration: json['slaDuration'] != null
            ? Duration(hours: json['slaDuration'])
            : null,
        slaDeadline: json['slaDeadline'] != null
            ? DateTime.parse(json['slaDeadline'])
            : null,
        assignedOfficerId: json['assignedOfficerId'],
        state: ComplaintState.values.firstWhere(
          (e) => e.toString() == json['state'],
          orElse: () => ComplaintState.submitted,
        ),
        escalationHistory: (json['escalationHistory'] as List?)
                ?.map((e) => EscalationRecord.fromJson(e))
                .toList() ??
            [],
      );
}

/// Location information with city and ward details
class LocationInfo {
  final String city;
  final String ward;
  final double latitude;
  final double longitude;
  final String? address;

  LocationInfo({
    required this.city,
    required this.ward,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'city': city,
        'ward': ward,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
        city: json['city'],
        ward: json['ward'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        address: json['address'],
      );
}

/// Urgency levels for complaints
enum UrgencyLevel {
  low,
  medium,
  high,
  critical,
}

extension UrgencyLevelExtension on UrgencyLevel {
  String get displayName {
    switch (this) {
      case UrgencyLevel.low:
        return 'Low';
      case UrgencyLevel.medium:
        return 'Medium';
      case UrgencyLevel.high:
        return 'High';
      case UrgencyLevel.critical:
        return 'Critical';
    }
  }

  int get weight {
    switch (this) {
      case UrgencyLevel.low:
        return 1;
      case UrgencyLevel.medium:
        return 2;
      case UrgencyLevel.high:
        return 3;
      case UrgencyLevel.critical:
        return 4;
    }
  }
}

/// Priority levels determined by decision engine
enum PriorityLevel {
  p1, // Highest - resolve within hours
  p2, // High - resolve within 1-2 days
  p3, // Medium - resolve within 3-5 days
  p4, // Low - resolve within 7-14 days
}

extension PriorityLevelExtension on PriorityLevel {
  String get displayName {
    switch (this) {
      case PriorityLevel.p1:
        return 'P1 - Critical';
      case PriorityLevel.p2:
        return 'P2 - High';
      case PriorityLevel.p3:
        return 'P3 - Medium';
      case PriorityLevel.p4:
        return 'P4 - Low';
    }
  }

  Duration get defaultSLA {
    switch (this) {
      case PriorityLevel.p1:
        return const Duration(minutes: 10); // Critical safety - 10 minutes
      case PriorityLevel.p2:
        return const Duration(days: 2);
      case PriorityLevel.p3:
        return const Duration(days: 5);
      case PriorityLevel.p4:
        return const Duration(days: 14);
    }
  }
}

/// Complaint lifecycle states with valid transitions
enum ComplaintState {
  submitted,
  assigned,
  inProgress,
  resolved,
  closed,
}

extension ComplaintStateExtension on ComplaintState {
  String get displayName {
    switch (this) {
      case ComplaintState.submitted:
        return 'Submitted';
      case ComplaintState.assigned:
        return 'Assigned';
      case ComplaintState.inProgress:
        return 'In Progress';
      case ComplaintState.resolved:
        return 'Resolved';
      case ComplaintState.closed:
        return 'Closed';
    }
  }

  /// Valid next states from current state
  List<ComplaintState> get validTransitions {
    switch (this) {
      case ComplaintState.submitted:
        return [ComplaintState.assigned];
      case ComplaintState.assigned:
        return [ComplaintState.inProgress];
      case ComplaintState.inProgress:
        return [ComplaintState.resolved, ComplaintState.assigned]; // Can reassign
      case ComplaintState.resolved:
        return [ComplaintState.closed, ComplaintState.inProgress]; // Can reopen
      case ComplaintState.closed:
        return []; // Terminal state
    }
  }

  bool canTransitionTo(ComplaintState nextState) {
    return validTransitions.contains(nextState);
  }
}

/// Escalation authority levels
enum EscalationLevel {
  officer,
  departmentHead,
  districtAuthority,
}

extension EscalationLevelExtension on EscalationLevel {
  String get displayName {
    switch (this) {
      case EscalationLevel.officer:
        return 'Officer';
      case EscalationLevel.departmentHead:
        return 'Department Head';
      case EscalationLevel.districtAuthority:
        return 'District Authority';
    }
  }

  EscalationLevel? get nextLevel {
    switch (this) {
      case EscalationLevel.officer:
        return EscalationLevel.departmentHead;
      case EscalationLevel.departmentHead:
        return EscalationLevel.districtAuthority;
      case EscalationLevel.districtAuthority:
        return null; // Highest level
    }
  }
}

/// Record of escalation event
class EscalationRecord {
  final String id;
  final DateTime timestamp;
  final EscalationLevel fromLevel;
  final EscalationLevel toLevel;
  final String reason;
  final String? fromOfficerId;
  final String? toOfficerId;
  final PriorityLevel newPriority;

  EscalationRecord({
    required this.id,
    required this.timestamp,
    required this.fromLevel,
    required this.toLevel,
    required this.reason,
    this.fromOfficerId,
    this.toOfficerId,
    required this.newPriority,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'fromLevel': fromLevel.toString(),
        'toLevel': toLevel.toString(),
        'reason': reason,
        'fromOfficerId': fromOfficerId,
        'toOfficerId': toOfficerId,
        'newPriority': newPriority.toString(),
      };

  factory EscalationRecord.fromJson(Map<String, dynamic> json) =>
      EscalationRecord(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        fromLevel: EscalationLevel.values.firstWhere(
          (e) => e.toString() == json['fromLevel'],
        ),
        toLevel: EscalationLevel.values.firstWhere(
          (e) => e.toString() == json['toLevel'],
        ),
        reason: json['reason'],
        fromOfficerId: json['fromOfficerId'],
        toOfficerId: json['toOfficerId'],
        newPriority: PriorityLevel.values.firstWhere(
          (e) => e.toString() == json['newPriority'],
        ),
      );
}
