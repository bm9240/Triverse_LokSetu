class Complaint {
  final String id;
  final String title;
  final String description;
  final String category;
  final String severity;
  final String? duration;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime submittedAt;
  final String citizenName;
  final String citizenPhone;
  final String? imagePath;
  ComplaintStatus status;
  List<ProofChainEntry> proofChain;
  
  // AutoGov Engine fields
  String? autoGovDepartment;
  String? autoGovPriority;
  String? assignedOfficerId; // Dynamic officer assignment - stores officer ID only
  String? autoGovOfficerName; // DEPRECATED: For backward compatibility only
  String? autoGovOfficerDesignation; // DEPRECATED: For backward compatibility only
  String? autoGovWard;
  String? autoGovCity;
  DateTime? autoGovSlaDeadline;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.duration,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.submittedAt,
    required this.citizenName,
    required this.citizenPhone,
    this.imagePath,
    this.status = ComplaintStatus.submitted,
    List<ProofChainEntry>? proofChain,
    this.autoGovDepartment,
    this.autoGovPriority,
    this.assignedOfficerId,
    this.autoGovOfficerName,
    this.autoGovOfficerDesignation,
    this.autoGovWard,
    this.autoGovCity,
    this.autoGovSlaDeadline,
  }) : proofChain = proofChain ?? [];

  void addProof(ProofChainEntry proof) {
    proofChain.add(proof);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'severity': severity,
        'duration': duration,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'submittedAt': submittedAt.toIso8601String(),
        'citizenName': citizenName,
        'citizenPhone': citizenPhone,
        'imagePath': imagePath,
        'status': status.toString(),
        'proofChain': proofChain.map((e) => e.toJson()).toList(),
        'autoGovDepartment': autoGovDepartment,
        'autoGovPriority': autoGovPriority,
        'assignedOfficerId': assignedOfficerId,
        'autoGovOfficerName': autoGovOfficerName,
        'autoGovOfficerDesignation': autoGovOfficerDesignation,
        'autoGovWard': autoGovWard,
        'autoGovCity': autoGovCity,
        'autoGovSlaDeadline': autoGovSlaDeadline?.toIso8601String(),
      };

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        category: json['category'],
        severity: json['severity'] ?? 'Medium',
        duration: json['duration'],
        location: json['location'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        submittedAt: DateTime.parse(json['submittedAt']),
        citizenName: json['citizenName'],
        citizenPhone: json['citizenPhone'],
        imagePath: json['imagePath'],
        status: ComplaintStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => ComplaintStatus.submitted,
        ),
        proofChain: (json['proofChain'] as List?)
                ?.map((e) => ProofChainEntry.fromJson(e))
                .toList() ??
            [],
        autoGovDepartment: json['autoGovDepartment'],
        autoGovPriority: json['autoGovPriority'],
        assignedOfficerId: json['assignedOfficerId'],
        autoGovOfficerName: json['autoGovOfficerName'],
        autoGovOfficerDesignation: json['autoGovOfficerDesignation'],
        autoGovWard: json['autoGovWard'],
        autoGovCity: json['autoGovCity'],
        autoGovSlaDeadline: json['autoGovSlaDeadline'] != null 
            ? DateTime.parse(json['autoGovSlaDeadline'])
            : null,
      );
}

enum ComplaintStatus {
  submitted,
  acknowledged,
  inProgress,
  completed,
  rejected,
}

extension ComplaintStatusExtension on ComplaintStatus {
  String get displayName {
    switch (this) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.acknowledged:
        return 'Acknowledged';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.completed:
        return 'Completed';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  String get emoji {
    switch (this) {
      case ComplaintStatus.submitted:
        return '📝';
      case ComplaintStatus.acknowledged:
        return '👀';
      case ComplaintStatus.inProgress:
        return '🔧';
      case ComplaintStatus.completed:
        return '✅';
      case ComplaintStatus.rejected:
        return '❌';
    }
  }
}

class ProofChainEntry {
  final String id;
  final DateTime timestamp;
  final String officerName;
  final String officerDesignation;
  final String description;
  final ProofType proofType;
  final String mediaPath; // Local path to photo/video
  final double latitude;
  final double longitude;
  final String locationName;
  final ComplaintStatus statusUpdate;
  final bool isEditable; // Always false - immutable proof

  ProofChainEntry({
    required this.id,
    required this.timestamp,
    required this.officerName,
    required this.officerDesignation,
    required this.description,
    required this.proofType,
    required this.mediaPath,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.statusUpdate,
    this.isEditable = false, // Locked by default
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'officerName': officerName,
        'officerDesignation': officerDesignation,
        'description': description,
        'proofType': proofType.toString(),
        'mediaPath': mediaPath,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'statusUpdate': statusUpdate.toString(),
        'isEditable': isEditable,
      };

  factory ProofChainEntry.fromJson(Map<String, dynamic> json) =>
      ProofChainEntry(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        officerName: json['officerName'],
        officerDesignation: json['officerDesignation'],
        description: json['description'],
        proofType: ProofType.values.firstWhere(
          (e) => e.toString() == json['proofType'],
        ),
        mediaPath: json['mediaPath'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        locationName: json['locationName'],
        statusUpdate: ComplaintStatus.values.firstWhere(
          (e) => e.toString() == json['statusUpdate'],
        ),
        isEditable: json['isEditable'] ?? false,
      );
}

enum ProofType {
  photo,
  video,
}
