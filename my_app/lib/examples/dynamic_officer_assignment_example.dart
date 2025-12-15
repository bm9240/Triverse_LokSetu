import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/autogov_firestore_bridge.dart';
import '../services/officers_firestore_service.dart';

/// Example: How to use the Dynamic Officer Assignment System
/// 
/// This demonstrates the complete workflow from complaint submission
/// to dynamic officer assignment with real-time Firestore updates.

class DynamicOfficerAssignmentExample {
  final AutoGovFirestoreBridge _bridge = AutoGovFirestoreBridge();
  final OfficersFirestoreService _officerService = OfficersFirestoreService();

  /// Example 1: Submit a complaint and assign an officer dynamically
  Future<void> submitComplaintWithDynamicAssignment() async {
    print('\n=== Example 1: Submit Complaint with Dynamic Officer Assignment ===\n');

    // Step 1: Create a complaint
    final complaint = Complaint(
      id: 'complaint_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Street Light Not Working',
      description: 'Street light on Main Road has been non-functional for 3 days',
      category: 'Street Lights',
      severity: 'High',
      location: 'Main Road, Ward B, Mumbai',
      latitude: 19.0760,
      longitude: 72.8777,
      submittedAt: DateTime.now(),
      citizenName: 'Rajesh Kumar',
      citizenPhone: '+91-9876543210',
    );

    print('📝 Created complaint: ${complaint.id}');
    print('   Category: ${complaint.category}');
    print('   Severity: ${complaint.severity}');

    // Step 2: Process through AutoGov (includes dynamic officer assignment)
    print('\n🤖 Processing through AutoGov Engine...');
    final result = await _bridge.processAndSyncComplaint(complaint);

    if (result.success) {
      print('\n✅ SUCCESS! Complaint processed and officer assigned:');
      print('   Department: ${result.department}');
      print('   Priority: ${result.priority}');
      print('   Officer ID: ${complaint.assignedOfficerId}');
      print('   SLA Deadline: ${result.slaDeadline}');

      // Step 3: Verify officer assignment in Firestore
      if (complaint.assignedOfficerId != null) {
        print('\n🔍 Fetching assigned officer details...');
        final officer = await _officerService.getOfficerById(complaint.assignedOfficerId!);
        
        if (officer != null) {
          print('   ✅ Officer: ${officer.name}');
          print('   Designation: ${officer.designation}');
          print('   Ward: ${officer.ward}');
          print('   Available: ${officer.isAvailable}');
          print('   Current Workload: ${officer.activeComplaints} complaints');
          print('   Reliability: ${(officer.reliability * 100).toStringAsFixed(0)}%');
        }
      }
    } else {
      print('\n❌ FAILED: ${result.errorMessage}');
    }
  }

  /// Example 2: Query available officers in a department
  Future<void> queryAvailableOfficers(String department) async {
    print('\n=== Example 2: Query Available Officers ===\n');
    print('🔍 Searching for available officers in: $department');

    final officers = await _officerService.getAvailableOfficersByDepartment(department);

    if (officers.isEmpty) {
      print('❌ No available officers found in $department');
      return;
    }

    print('\n✅ Found ${officers.length} available officers:\n');
    
    for (var i = 0; i < officers.length; i++) {
      final officer = officers[i];
      print('${i + 1}. ${officer.name} (${officer.designation})');
      print('   ID: ${officer.id}');
      print('   Ward: ${officer.ward}');
      print('   Workload: ${officer.activeComplaints} complaints');
      print('   Reliability: ${(officer.reliability * 100).toStringAsFixed(0)}%');
      print('   Avg Resolution: ${officer.avgResolutionTime.toStringAsFixed(1)} hours');
      print('   Available: ${officer.isAvailable ? "✅" : "❌"}');
      print('');
    }

    // The first officer in the list has the lowest workload
    print('🎯 Best candidate (lowest workload): ${officers.first.name}');
  }

  /// Example 3: Stream officer data for real-time updates
  void streamOfficerDataExample(String officerId) {
    print('\n=== Example 3: Real-Time Officer Data Stream ===\n');
    print('📡 Subscribing to officer updates: $officerId');

    final stream = _officerService.getOfficerStream(officerId);
    
    stream.listen(
      (officer) {
        if (officer != null) {
          print('\n🔄 Officer data updated:');
          print('   Name: ${officer.name}');
          print('   Available: ${officer.isAvailable}');
          print('   Workload: ${officer.activeComplaints}');
        } else {
          print('\n⚠️ Officer not found or deleted');
        }
      },
      onError: (error) {
        print('\n❌ Stream error: $error');
      },
    );

    print('✅ Listening for real-time updates...');
    print('   (Changes in Firestore will appear here automatically)');
  }

  /// Example 4: Manually update officer availability
  Future<void> updateOfficerAvailability(String officerId, bool isAvailable) async {
    print('\n=== Example 4: Update Officer Availability ===\n');
    print('🔧 Setting officer $officerId availability to: $isAvailable');

    await _officerService.updateOfficerAvailability(officerId, isAvailable);

    print('✅ Updated successfully!');
    print('   This officer will ${isAvailable ? "now be" : "no longer be"} considered for new assignments');
  }

  /// Example 5: Check officer workload before and after assignment
  Future<void> demonstrateWorkloadTracking(String department) async {
    print('\n=== Example 5: Workload Tracking Demonstration ===\n');

    // Get available officers
    final officers = await _officerService.getAvailableOfficersByDepartment(department);
    if (officers.isEmpty) {
      print('❌ No available officers in $department');
      return;
    }

    final selectedOfficer = officers.first;
    print('👤 Selected Officer: ${selectedOfficer.name}');
    print('📊 Initial Workload: ${selectedOfficer.activeComplaints} complaints\n');

    // Simulate assignment
    print('⚡ Assigning new complaint...');
    await _officerService.incrementOfficerWorkload(selectedOfficer.id);
    
    // Verify updated workload
    final updatedOfficer = await _officerService.getOfficerById(selectedOfficer.id);
    if (updatedOfficer != null) {
      print('📊 New Workload: ${updatedOfficer.activeComplaints} complaints');
      print('   Increment successful! ✅');
    }

    // Simulate resolution
    print('\n⚡ Resolving complaint...');
    await _officerService.decrementOfficerWorkload(selectedOfficer.id);
    
    // Verify updated workload
    final finalOfficer = await _officerService.getOfficerById(selectedOfficer.id);
    if (finalOfficer != null) {
      print('📊 Final Workload: ${finalOfficer.activeComplaints} complaints');
      print('   Decrement successful! ✅');
    }
  }

  /// Run all examples
  Future<void> runAllExamples() async {
    print('\n' + '=' * 70);
    print('🚀 DYNAMIC OFFICER ASSIGNMENT SYSTEM - EXAMPLES');
    print('=' * 70);

    try {
      // Initialize AutoGov Engine
      print('\n🔧 Initializing AutoGov Engine...');
      await _bridge.initialize();
      print('✅ Initialization complete!\n');

      // Run examples
      await submitComplaintWithDynamicAssignment();
      await Future.delayed(const Duration(seconds: 2));

      await queryAvailableOfficers('Electricity Board');
      await Future.delayed(const Duration(seconds: 2));

      await demonstrateWorkloadTracking('Public Works Department');
      await Future.delayed(const Duration(seconds: 2));

      // Stream example (commented out as it's infinite)
      // streamOfficerDataExample('ElectricityBoard_0');

      print('\n' + '=' * 70);
      print('✅ All examples completed successfully!');
      print('=' * 70 + '\n');

    } catch (e) {
      print('\n❌ Error running examples: $e');
    }
  }
}

/// Widget example: Using StreamBuilder in UI
class OfficerDisplayWidget extends StatelessWidget {
  final String? assignedOfficerId;

  const OfficerDisplayWidget({
    Key? key,
    required this.assignedOfficerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (assignedOfficerId == null) {
      return const Text('No officer assigned');
    }

    return StreamBuilder<Officer?>(
      stream: OfficersFirestoreService().getOfficerStream(assignedOfficerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Text('Officer not found (ID: $assignedOfficerId)');
        }

        final officer = snapshot.data!;
        
        return Card(
          child: ListTile(
            leading: Icon(
              officer.isAvailable ? Icons.person : Icons.person_off,
              color: officer.isAvailable ? Colors.green : Colors.orange,
            ),
            title: Text('${officer.name} (${officer.designation})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ward: ${officer.ward}'),
                Text('Workload: ${officer.activeComplaints} complaints'),
                Text('Status: ${officer.isAvailable ? "Available" : "Busy"}'),
              ],
            ),
            trailing: Text(
              '${(officer.reliability * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
