import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../models/autogov_complaint.dart';
import '../services/complaint_service.dart';
import '../services/autogov_engine.dart';

class ComplaintProvider with ChangeNotifier {
  final ComplaintService _service = ComplaintService();
  final AutoGovEngine _autoGovEngine = AutoGovEngine();
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
    
    await _service.loadComplaints();
    _complaints = _service.getAllComplaints();
    
    _isLoading = false;
    notifyListeners();
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
      debugPrint('   Location: ${complaint.location}');
      debugPrint('   Severity: ${complaint.severity}');
      
      await _initializeAutoGov();
      debugPrint('🤖 AutoGov: Engine initialized');
      
      final city = _extractCity(complaint.location);
      final ward = _extractWard(complaint.location);
      debugPrint('🤖 AutoGov: Extracted - City: $city, Ward: $ward');
      
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

      debugPrint('🤖 AutoGov: Calling engine.processComplaint()...');
      // Process through AutoGov Engine
      final result = await _autoGovEngine.processComplaint(autoGovComplaint);
      
      debugPrint('🤖 AutoGov: Engine returned - Success: ${result.success}');
      if (!result.success) {
        debugPrint('⚠️ AutoGov: Processing failed - ${result.errorMessage}');
      }
      
      if (result.success) {
        // Store AutoGov data in complaint
        complaint.autoGovDepartment = result.department;
        complaint.autoGovPriority = result.priority?.displayName;
        complaint.autoGovOfficerName = result.assignedOfficer;
        complaint.autoGovOfficerDesignation = _getOfficerDesignation(result.department);
        complaint.autoGovWard = ward;
        complaint.autoGovCity = city;
        complaint.autoGovSlaDeadline = result.slaDeadline;
        
        debugPrint('🤖 AutoGov: Saving updated complaint to service...');
        // Save updated complaint
        await _service.updateComplaint(complaint);
        
        // Reload complaints to get updated data
        _complaints = _service.getAllComplaints();
        
        debugPrint('✅ AutoGov: Complaint ${complaint.id} processed');
        debugPrint('   Department: ${result.department}');
        debugPrint('   Priority: ${result.priority?.displayName}');
        debugPrint('   Officer: ${result.assignedOfficer}');
        debugPrint('   Ward: $ward, City: $city');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ AutoGov processing error: $e');
      debugPrint('Stack trace: $stackTrace');
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
