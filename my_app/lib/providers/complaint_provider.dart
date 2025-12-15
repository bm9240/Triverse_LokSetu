import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../models/autogov_complaint.dart';
import '../services/complaint_service.dart';
import '../services/autogov_engine.dart';
import '../services/firestore_service.dart';
import '../services/officers_firestore_service.dart';

class ComplaintProvider with ChangeNotifier {
  final ComplaintService _service = ComplaintService();
  final AutoGovEngine _autoGovEngine = AutoGovEngine();
  final FirestoreService _firestore = FirestoreService();
  final OfficersFirestoreService _officersService = OfficersFirestoreService();
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  bool _autoGovInitialized = false;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;

  ComplaintProvider() {
    loadComplaints();
    _initializeAutoGov();
  }

  Future<void> _initializeAutoGov() async {
    if (!_autoGovInitialized) {
      await _autoGovEngine.initialize();
      _autoGovInitialized = true;
    }
  }

  Future<void> loadComplaints() async {
    _isLoading = true;
    notifyListeners();
    
    // Load from local storage
    await _service.loadComplaints();
    final localComplaints = _service.getAllComplaints();
    
    // Load from Firestore and merge (Firestore takes priority)
    try {
      final firestoreStream = _firestore.getComplaintsStream();
      firestoreStream.listen((firestoreComplaints) {
        // Create a map of Firestore complaints by ID
        final firestoreMap = {for (var c in firestoreComplaints) c.id: c};
        
        // Start with Firestore complaints (they have the latest data)
        final mergedComplaints = [...firestoreComplaints];
        
        // Add local complaints that don't exist in Firestore
        for (final localComplaint in localComplaints) {
          if (!firestoreMap.containsKey(localComplaint.id)) {
            mergedComplaints.add(localComplaint);
          }
        }
        
        _complaints = mergedComplaints;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('⚠️ Failed to load Firestore complaints: $e');
      _complaints = localComplaints;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addComplaint(Complaint complaint) async {
    await _service.addComplaint(complaint);
    
    // Process through AutoGov Engine for intelligent routing BEFORE notifying UI
    await _processWithAutoGov(complaint);
    
    // Now reload complaints with AutoGov data
    _complaints = _service.getAllComplaints();
    
    notifyListeners();
  }

  Future<void> _processWithAutoGov(Complaint complaint) async {
    try {
      debugPrint('🤖 AutoGov: Starting to process complaint ${complaint.id}');
      debugPrint('   Category: ${complaint.category}');
      debugPrint('   Severity: ${complaint.severity}');
      
      await _initializeAutoGov();
      
      final city = _extractCity(complaint.location);
      final ward = _extractWard(complaint.location);
      
      // Convert to AutoGov format
      final autoGovComplaint = AutoGovComplaintExtension(
        complaintId: complaint.id,
        category: complaint.category,
        location: LocationInfo(
          city: city,
          ward: ward,
          latitude: complaint.latitude,
          longitude: complaint.longitude,
          address: complaint.location,
        ),
        urgency: _mapSeverityToUrgency(complaint.severity),
        timestamp: complaint.submittedAt,
      );

      // Process through AutoGov Engine
      final result = await _autoGovEngine.processComplaint(autoGovComplaint);
      
      if (!result.success) {
        debugPrint('⚠️ AutoGov: Failed - ${result.errorMessage}');
        return;
      }
      
      // Get officer details from the assigned officer ID
      String? officerName;
      String? officerDesignation;
      
      if (autoGovComplaint.assignedOfficerId != null) {
        // Fetch officer details from Firestore
        try {
          final officer = await _officersService.getOfficerById(autoGovComplaint.assignedOfficerId!);
          if (officer != null) {
            officerName = officer.name;
            officerDesignation = officer.designation;
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch officer details: $e');
        }
      }
      
      // Update complaint with AutoGov data
      complaint.autoGovDepartment = result.department;
      complaint.autoGovPriority = result.priority?.displayName;
      complaint.assignedOfficerId = autoGovComplaint.assignedOfficerId;
      complaint.autoGovOfficerName = officerName ?? 'Officer Assigned';
      complaint.autoGovOfficerDesignation = officerDesignation ?? _getOfficerDesignation(result.department);
      complaint.autoGovWard = ward;
      complaint.autoGovCity = city;
      complaint.autoGovSlaDeadline = result.slaDeadline;
      
      // Save updated complaint
      await _service.updateComplaint(complaint);
      
      // Sync to Firestore
      try {
        await _firestore.upsertComplaint(complaint);
      } catch (e) {
        debugPrint('⚠️ Firestore sync failed: $e');
      }
      
      debugPrint('✅ AutoGov: Processed successfully');
      debugPrint('   Department: ${result.department}');
      debugPrint('   Officer ID: ${autoGovComplaint.assignedOfficerId}');
      debugPrint('   Officer: $officerName');
      debugPrint('   Priority: ${result.priority?.displayName}');
      
    } catch (e, stackTrace) {
      debugPrint('⚠️ AutoGov error: $e');
      debugPrint('Stack: $stackTrace');
    }
  }
  
  String _getOfficerDesignation(String? department) {
    if (department == null) return 'Officer';
    if (department.contains('Public Works')) return 'Senior Engineer';
    if (department.contains('Water')) return 'Water Inspector';
    if (department.contains('Electricity')) return 'Line Inspector';
    if (department.contains('Health')) return 'Health Officer';
    return 'Department Officer';
  }

  String _extractCity(String location) {
    // Simple extraction, can be enhanced
    final parts = location.split(',');
    return parts.length > 1 ? parts.last.trim() : 'Mumbai';
  }

  String _extractWard(String location) {
    // Default to Ward A, can be enhanced with actual ward detection
    return 'Ward A';
  }

  UrgencyLevel _mapSeverityToUrgency(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return UrgencyLevel.critical;
      case 'high':
        return UrgencyLevel.high;
      case 'medium':
        return UrgencyLevel.medium;
      default:
        return UrgencyLevel.low;
    }
  }

  // AutoGov Engine queries
  Future<void> checkEscalations() async {
    await _initializeAutoGov();
    final escalations = await _autoGovEngine.checkAndEscalate();
    if (escalations.isNotEmpty) {
      debugPrint('⚠️ ${escalations.length} complaints escalated');
      notifyListeners();
    }
  }

  String getAutoGovStats() {
    if (!_autoGovInitialized) return 'AutoGov not initialized';
    final stats = _autoGovEngine.getStatistics();
    return 'Active: ${stats.totalActiveComplaints}, Breached SLAs: ${stats.breachedSLAs}';
  }

  Future<void> updateComplaint(Complaint complaint) async {
    await _service.updateComplaint(complaint);
    _complaints = _service.getAllComplaints();
    notifyListeners();
  }

  Future<void> clearAllComplaints() async {
    await _service.clearAllComplaints();
    _complaints = [];
    try {
      await _firestore.deleteAllComplaints();
    } catch (e) {
      debugPrint('⚠️ Firestore clear failed: $e');
    }
    notifyListeners();
    debugPrint('🗑️ All complaints cleared from provider');
  }

  Future<void> addProofToComplaint(String complaintId, ProofChainEntry proof) async {
    await _service.addProofToComplaint(complaintId, proof);
    _complaints = _service.getAllComplaints();
    notifyListeners();
  }

  List<Complaint> getComplaintsByStatus(ComplaintStatus status) {
    return _service.getComplaintsByStatus(status);
  }

  List<Complaint> getComplaintsByPhone(String phone) {
    return _service.getComplaintsByPhone(phone);
  }

  Complaint? getComplaintById(String id) {
    return _service.getComplaintById(id);
  }
}
