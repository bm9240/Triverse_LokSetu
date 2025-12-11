import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';

class ComplaintProvider with ChangeNotifier {
  final ComplaintService _service = ComplaintService();
  List<Complaint> _complaints = [];
  bool _isLoading = false;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;

  ComplaintProvider() {
    loadComplaints();
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
    _complaints = _service.getAllComplaints();
    notifyListeners();
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
