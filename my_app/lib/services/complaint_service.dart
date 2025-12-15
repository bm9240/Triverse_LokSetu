import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint.dart';
import 'firestore_service.dart';
import 'officers_firestore_service.dart';

class ComplaintService {
  static const String _complaintsKey = 'complaints';
  
  // Singleton pattern
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal();

  List<Complaint> _complaints = [];

  Future<void> loadComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final String? complaintsJson = prefs.getString(_complaintsKey);
    
    if (complaintsJson != null) {
      final List<dynamic> decoded = json.decode(complaintsJson);
      _complaints = decoded.map((e) => Complaint.fromJson(e)).toList();
    }
  }

  Future<void> saveComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_complaints.map((e) => e.toJson()).toList());
    await prefs.setString(_complaintsKey, encoded);
  }

  Future<void> addComplaint(Complaint complaint) async {
    _complaints.add(complaint);
    await saveComplaints();
  }

  Future<void> updateComplaint(Complaint complaint) async {
    final index = _complaints.indexWhere((c) => c.id == complaint.id);
    if (index != -1) {
      _complaints[index] = complaint;
      await saveComplaints();
      print('📝 Complaint updated in service: ${complaint.id}');
      print('   Officer: ${complaint.autoGovOfficerName}');
      print('   Department: ${complaint.autoGovDepartment}');
    }
  }

  Future<void> addProofToComplaint(String complaintId, ProofChainEntry proof) async {
    final complaint = _complaints.firstWhere((c) => c.id == complaintId);
    complaint.addProof(proof);
    
    // Update status based on proof
    complaint.status = proof.statusUpdate;
    
    // Save to local storage
    await saveComplaints();
    
    // Sync status update to Firestore
    await FirestoreService().upsertComplaint(complaint);
    
    print('✅ Complaint ${complaintId} status updated to ${proof.statusUpdate} and synced to Firestore');
    
    // If complaint is completed, decrement officer workload
    if (proof.statusUpdate == ComplaintStatus.completed && complaint.assignedOfficerId != null) {
      try {
        await OfficersFirestoreService().decrementOfficerWorkload(complaint.assignedOfficerId!);
        print('✅ Officer ${complaint.assignedOfficerId} workload decremented');

        // Reward officer with a resolution point
        await OfficersFirestoreService().addResolutionPoint(complaint.assignedOfficerId!);
        print('✅ Officer ${complaint.assignedOfficerId} awarded +1 resolution point');
      } catch (e) {
        print('⚠️ Failed to decrement officer workload: $e');
      }
    }
  }

  List<Complaint> getAllComplaints() => List.unmodifiable(_complaints);

  Complaint? getComplaintById(String id) {
    try {
      final complaint = _complaints.firstWhere((c) => c.id == id);
      print('🔍 Retrieved complaint: ${complaint.id}');
      print('   Officer: ${complaint.autoGovOfficerName}');
      print('   Department: ${complaint.autoGovDepartment}');
      print('   Ward: ${complaint.autoGovWard}');
      return complaint;
    } catch (e) {
      return null;
    }
  }

  List<Complaint> getComplaintsByStatus(ComplaintStatus status) {
    return _complaints.where((c) => c.status == status).toList();
  }

  List<Complaint> getComplaintsByPhone(String phone) {
    return _complaints.where((c) => c.citizenPhone == phone).toList();
  }

  Future<void> clearAllComplaints() async {
    _complaints.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_complaintsKey);
    print('🗑️ All complaints cleared from storage');
  }
}
