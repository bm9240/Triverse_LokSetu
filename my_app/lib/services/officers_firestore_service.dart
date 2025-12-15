import 'package:cloud_firestore/cloud_firestore.dart';

/// Officer model for Firestore
class Officer {
  final String id;
  final String name;
  final String designation;
  final String department;
  final String ward;
  final bool isAvailable; // Officer availability status
  final double reliability; // 0.0 to 1.0
  final int activeComplaints;
  final double avgResolutionTime; // hours
  final int resolvedPoints; // gamified score for completed complaints
  final int penaltyPoints; // penalty points for SLA breaches

  Officer({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.ward,
    this.isAvailable = true,
    this.reliability = 0.85,
    this.activeComplaints = 0,
    this.avgResolutionTime = 24.0,
    this.resolvedPoints = 0,
    this.penaltyPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'designation': designation,
      'department': department,
      'ward': ward,
      'isAvailable': isAvailable,
      'reliability': reliability,
      'activeComplaints': activeComplaints,
      'avgResolutionTime': avgResolutionTime,
      'resolvedPoints': resolvedPoints,
      'penaltyPoints': penaltyPoints,
    };
  }

  factory Officer.fromMap(Map<String, dynamic> map) {
    return Officer(
      id: map['id'],
      name: map['name'],
      designation: map['designation'],
      department: map['department'],
      ward: map['ward'],
      isAvailable: map['isAvailable'] ?? true,
      reliability: (map['reliability'] as num?)?.toDouble() ?? 0.85,
      activeComplaints: map['activeComplaints'] ?? 0,
      avgResolutionTime: (map['avgResolutionTime'] as num?)?.toDouble() ?? 24.0,
      resolvedPoints: map['resolvedPoints'] ?? 0,
      penaltyPoints: map['penaltyPoints'] ?? 0,
    );
  }
}

/// Firestore service for officers management
class OfficersFirestoreService {
  static final OfficersFirestoreService _instance = OfficersFirestoreService._internal();
  factory OfficersFirestoreService() => _instance;
  OfficersFirestoreService._internal();

  final _db = FirebaseFirestore.instance;
  static const String officersCollection = 'officers';

  /// Get available officers for a department, ordered by workload (lowest activeComplaints first)
  Future<List<Officer>> getAvailableOfficersByDepartment(String department) async {
    try {
      // Query with department filter only (to avoid index requirement)
      final snap = await _db
          .collection(officersCollection)
          .where('department', isEqualTo: department)
          .get();
      
      // Filter and sort in memory
      final officers = snap.docs
          .map((doc) => Officer.fromMap(doc.data()))
          .where((officer) => officer.isAvailable) // Filter available officers
          .toList();
      
      // Sort by activeComplaints (lowest first)
      officers.sort((a, b) => a.activeComplaints.compareTo(b.activeComplaints));
      
      return officers;
    } catch (e) {
      print('⚠️ Error fetching available officers: $e');
      return [];
    }
  }

  /// Get a specific officer by ID
  Future<Officer?> getOfficerById(String officerId) async {
    try {
      final doc = await _db.collection(officersCollection).doc(officerId).get();
      if (doc.exists) {
        return Officer.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('⚠️ Error fetching officer: $e');
      return null;
    }
  }

  /// Stream officer data for real-time updates
  Stream<Officer?> getOfficerStream(String officerId) {
    return _db.collection(officersCollection).doc(officerId).snapshots().map((doc) {
      if (doc.exists) {
        return Officer.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Increment officer's active complaints count (when assigning)
  Future<void> incrementOfficerWorkload(String officerId) async {
    try {
      await _db.collection(officersCollection).doc(officerId).update({
        'activeComplaints': FieldValue.increment(1),
      });
      print('✅ Incremented workload for officer: $officerId');
    } catch (e) {
      print('⚠️ Error incrementing officer workload: $e');
    }
  }

  /// Decrement officer's active complaints count (when resolved)
  Future<void> decrementOfficerWorkload(String officerId) async {
    try {
      await _db.collection(officersCollection).doc(officerId).update({
        'activeComplaints': FieldValue.increment(-1),
      });
      print('✅ Decremented workload for officer: $officerId');
    } catch (e) {
      print('⚠️ Error decrementing officer workload: $e');
    }
  }

  /// Add a resolution point when an officer completes a complaint
  Future<void> addResolutionPoint(String officerId) async {
    try {
      await _db.collection(officersCollection).doc(officerId).update({
        'resolvedPoints': FieldValue.increment(1),
      });
      print('✅ Added resolution point for officer: $officerId');
    } catch (e) {
      print('⚠️ Error adding resolution point: $e');
    }
  }

  /// Add penalty point when officer breaches SLA
  Future<void> addPenaltyPoint(String officerId) async {
    try {
      await _db.collection(officersCollection).doc(officerId).update({
        'penaltyPoints': FieldValue.increment(1),
      });
      print('⚠️ Added penalty point for officer: $officerId (SLA breach)');
    } catch (e) {
      print('⚠️ Error adding penalty point: $e');
    }
  }

  /// Update officer availability status
  Future<void> updateOfficerAvailability(String officerId, bool isAvailable) async {
    try {
      await _db.collection(officersCollection).doc(officerId).update({
        'isAvailable': isAvailable,
      });
      print('✅ Updated availability for officer $officerId: $isAvailable');
    } catch (e) {
      print('⚠️ Error updating officer availability: $e');
    }
  }

  /// Initialize officers in Firestore (run once)
  Future<void> initializeOfficers() async {
    final departments = [
      'Electricity Board',
      'Public Works Department',
      'Water Supply & Sanitation',
      'Waste Management',
      'Parks & Recreation',
      'Traffic Police',
      'Public Safety & Services',
      'Health Department',
      'Environment Department',
      'Urban Development',
    ];

    final officerTemplates = [
      ('Rajesh Kumar', 'Senior Inspector'),
      ('Priya Sharma', 'Inspector'),
      ('Anil Verma', 'Assistant Inspector'),
      ('Sanjay Patel', 'Officer'),
      ('Deepak Singh', 'Deputy Officer'),
    ];

    final wards = ['Ward A', 'Ward B', 'Ward C', 'Ward D', 'Ward E'];

    try {
      int counter = 0;
      for (var dept in departments) {
        for (var i = 0; i < 5; i++) {
          final (name, designation) = officerTemplates[i];
          final ward = wards[i];
          final officerId = '${dept.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}_$i';

          final officer = Officer(
            id: officerId,
            name: name,
            designation: designation,
            department: dept,
            ward: ward,
            isAvailable: true, // All officers start as available
            reliability: 0.75 + (i * 0.05),
            activeComplaints: 0,
            avgResolutionTime: 24.0 - (i * 2),
            resolvedPoints: 0,
            penaltyPoints: 0,
          );

          await _db
              .collection(officersCollection)
              .doc(officerId)
              .set(officer.toMap(), SetOptions(merge: true));

          counter++;
        }
      }
      print('✅ Initialized $counter officers in Firestore');
    } catch (e) {
      print('❌ Error initializing officers: $e');
    }
  }
}
