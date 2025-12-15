import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/complaint.dart';

/// Firestore persistence for complaints with AutoGov data.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _db = FirebaseFirestore.instance;
  static const String complaintsCollection = 'complaints';

  /// Create or update complaint document.
  Future<void> upsertComplaint(Complaint complaint) async {
    try {
      await _db.collection(complaintsCollection).doc(complaint.id).set(
        _toMap(complaint),
        SetOptions(merge: true),
      );
      debugPrint('✅ Firestore: Complaint ${complaint.id} synced');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore: Firebase error - ${e.code}: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Firestore: Unexpected error - $e');
      rethrow;
    }
  }

  /// Stream of all complaints for real-time updates.
  Stream<List<Complaint>> getComplaintsStream() {
    return _db.collection(complaintsCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromMap(doc.data(), doc.id)).toList();
    }).handleError((e) {
      debugPrint('❌ Firestore Stream Error: $e');
    });
  }

  /// Delete all complaints (use carefully in admin flows).
  Future<void> deleteAllComplaints() async {
    try {
      final batch = _db.batch();
      final snap = await _db.collection(complaintsCollection).get();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('✅ Firestore: All complaints cleared');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore: Firebase error during delete - ${e.code}: ${e.message}');
      rethrow;
    }
  }

  Map<String, dynamic> _toMap(Complaint c) {
    return {
      'id': c.id,
      'title': c.title,
      'description': c.description,
      'category': c.category,
      'severity': c.severity,
      'duration': c.duration,
      'location': c.location,
      'latitude': c.latitude,
      'longitude': c.longitude,
      'submittedAt': c.submittedAt.toIso8601String(),
      'citizenName': c.citizenName,
      'citizenPhone': c.citizenPhone,
      'imagePath': c.imagePath,
      'status': c.status.toString(),
      'proofChain': c.proofChain.map((p) => p.toJson()).toList(),
      'autoGovDepartment': c.autoGovDepartment,
      'autoGovPriority': c.autoGovPriority,
      'assignedOfficerId': c.assignedOfficerId, // Dynamic officer reference
      'autoGovOfficerName': c.autoGovOfficerName,
      'autoGovOfficerDesignation': c.autoGovOfficerDesignation,
      'autoGovWard': c.autoGovWard,
      'autoGovCity': c.autoGovCity,
      'autoGovSlaDeadline': c.autoGovSlaDeadline?.toIso8601String(),
      'escalatedToHead': c.escalatedToHead,
      'escalationReason': c.escalationReason,
    };
  }

  /// Public method to deserialize complaint from Firestore data
  Complaint deserializeComplaint(Map<String, dynamic> map, String id) {
    return _fromMap(map, id);
  }

  Complaint _fromMap(Map<String, dynamic> map, String id) {
    return Complaint(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      severity: map['severity'] ?? '',
      duration: map['duration'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      submittedAt: DateTime.parse(map['submittedAt'] ?? DateTime.now().toIso8601String()),
      citizenName: map['citizenName'] ?? '',
      citizenPhone: map['citizenPhone'] ?? '',
      imagePath: map['imagePath'],
      status: _parseStatus(map['status']),
        proofChain: (map['proofChain'] as List<dynamic>?)
            ?.map((e) => ProofChainEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
          [],
      autoGovDepartment: map['autoGovDepartment'],
      autoGovPriority: map['autoGovPriority'],
      assignedOfficerId: map['assignedOfficerId'], // Dynamic officer reference
      autoGovOfficerName: map['autoGovOfficerName'],
      autoGovOfficerDesignation: map['autoGovOfficerDesignation'],
      autoGovWard: map['autoGovWard'],
      autoGovCity: map['autoGovCity'],
      autoGovSlaDeadline: map['autoGovSlaDeadline'] != null 
          ? DateTime.parse(map['autoGovSlaDeadline'])
          : null,
      escalatedToHead: map['escalatedToHead'] ?? false,
      escalationReason: map['escalationReason'],
    );
  }

  ComplaintStatus _parseStatus(String? status) {
    if (status == null) return ComplaintStatus.submitted;
    if (status.contains('completed')) return ComplaintStatus.completed;
    if (status.contains('inProgress')) return ComplaintStatus.inProgress;
    if (status.contains('acknowledged')) return ComplaintStatus.acknowledged;
    if (status.contains('rejected')) return ComplaintStatus.rejected;
    return ComplaintStatus.submitted;
  }
}