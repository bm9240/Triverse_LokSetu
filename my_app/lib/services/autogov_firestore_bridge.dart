import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import '../models/autogov_complaint.dart';
import 'autogov_engine.dart';
import 'firestore_service.dart';

/// Bridge between AutoGov Engine and Firestore
/// Handles processing complaints and syncing officer assignments to Firestore
class AutoGovFirestoreBridge {
  static final AutoGovFirestoreBridge _instance = AutoGovFirestoreBridge._internal();
  factory AutoGovFirestoreBridge() => _instance;
  AutoGovFirestoreBridge._internal();

  final AutoGovEngine _autoGovEngine = AutoGovEngine();
  final FirestoreService _firestoreService = FirestoreService();

  /// Process a complaint through AutoGov and sync to Firestore
  Future<ProcessingResult> processAndSyncComplaint(Complaint complaint) async {
    // Convert Complaint to AutoGovComplaintExtension
    final autoGovComplaint = _convertToAutoGovComplaint(complaint);

    // Process through AutoGov Engine
    final result = await _autoGovEngine.processComplaint(autoGovComplaint);

    if (result.success) {
      // Update the complaint with AutoGov data
      complaint.autoGovDepartment = result.department;
      complaint.autoGovPriority = result.priority?.displayName;
      complaint.assignedOfficerId = autoGovComplaint.assignedOfficerId; // Store officer ID only
      complaint.autoGovWard = autoGovComplaint.location.ward;
      complaint.autoGovCity = autoGovComplaint.location.city;
      complaint.autoGovSlaDeadline = result.slaDeadline;

      // Sync to Firestore
      await _firestoreService.upsertComplaint(complaint);

      print('✅ AutoGov: Complaint processed and synced to Firestore');
      print('   Complaint ID: ${complaint.id}');
      print('   Department: ${result.department}');
      print('   Officer ID: ${autoGovComplaint.assignedOfficerId}');
      print('   Priority: ${result.priority}');
    }

    return result;
  }

  /// Convert Complaint model to AutoGovComplaintExtension
  AutoGovComplaintExtension _convertToAutoGovComplaint(Complaint complaint) {
    return AutoGovComplaintExtension(
      complaintId: complaint.id,
      category: complaint.category,
      location: LocationInfo(
        city: _extractCity(complaint.location),
        ward: _extractWard(complaint.location),
        latitude: complaint.latitude,
        longitude: complaint.longitude,
        address: complaint.location,
      ),
      urgency: _mapSeverityToUrgency(complaint.severity),
      timestamp: complaint.submittedAt,
      assignedDepartment: complaint.autoGovDepartment,
      assignedOfficerId: complaint.assignedOfficerId,
    );
  }

  /// Extract city from location string
  String _extractCity(String location) {
    // Basic parsing - adjust based on your location format
    if (location.contains(',')) {
      final parts = location.split(',');
      return parts.last.trim();
    }
    return 'Mumbai'; // Default city
  }

  /// Extract ward from location string
  String _extractWard(String location) {
    // Basic parsing - adjust based on your location format
    if (location.toLowerCase().contains('ward')) {
      final match = RegExp(r'ward\s*[A-Za-z0-9]+', caseSensitive: false)
          .firstMatch(location.toLowerCase());
      if (match != null) {
        return match.group(0)!;
      }
    }
    return 'Ward A'; // Default ward
  }

  /// Map severity string to UrgencyLevel enum
  UrgencyLevel _mapSeverityToUrgency(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return UrgencyLevel.critical;
      case 'medium':
        return UrgencyLevel.high;
      case 'low':
        return UrgencyLevel.normal;
      default:
        return UrgencyLevel.normal;
    }
  }

  /// Initialize AutoGov Engine
  Future<void> initialize() async {
    await _autoGovEngine.initialize();
  }
}
