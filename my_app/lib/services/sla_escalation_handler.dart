import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../models/autogov_complaint.dart';
import 'complaint_service.dart';
import 'firestore_service.dart';
import 'officers_firestore_service.dart';

/// SLA Escalation Handler
/// Handles escalation of overdue pending complaints
class SLAEscalationHandler {
  static final SLAEscalationHandler _instance = SLAEscalationHandler._internal();
  factory SLAEscalationHandler() => _instance;
  SLAEscalationHandler._internal();

  final ComplaintService _complaintService = ComplaintService();
  final FirestoreService _firestoreService = FirestoreService();
  final OfficersFirestoreService _officersService = OfficersFirestoreService();

  /// Check and escalate overdue pending complaints
  Future<void> checkAndEscalateOverdueComplaints() async {
    final now = DateTime.now();
    final complaints = _complaintService.getAllComplaints();

    // Filter pending complaints that are overdue
    final overdueComplaints = complaints.where((c) {
      if (c.status != ComplaintStatus.submitted && 
          c.status != ComplaintStatus.acknowledged && 
          c.status != ComplaintStatus.inProgress) {
        return false; // Skip non-pending complaints
      }

      if (c.autoGovSlaDeadline == null) {
        return false; // Skip complaints without SLA
      }

      if (c.escalatedToHead) {
        return false; // Already escalated
      }

      return now.isAfter(c.autoGovSlaDeadline!);
    }).toList();

    for (final complaint in overdueComplaints) {
      await _escalateComplaint(complaint, now);
    }
  }

  /// Escalate a single overdue complaint
  Future<void> _escalateComplaint(Complaint complaint, DateTime now) async {
    try {
      final delayDuration = now.difference(complaint.autoGovSlaDeadline!);
      final delayHours = delayDuration.inHours;
      final delayDays = delayDuration.inDays;

      print('═══════════════════════════════════════════════════════════');
      print('⚡ ESCALATION TRIGGERED');
      print('═══════════════════════════════════════════════════════════');
      print('📋 Complaint ID: ${complaint.id}');
      print('📌 Title: ${complaint.title}');
      print('⏰ Original Deadline: ${DateFormat('dd-MM-yyyy HH:mm').format(complaint.autoGovSlaDeadline!)}');
      print('⏳ Overdue Duration: $delayDays days, ${delayDuration.inHours % 24} hours');
      print('👤 Assigned Officer: ${complaint.assignedOfficerId}');
      print('───────────────────────────────────────────────────────────');

      // 1. Mark complaint as escalated
      complaint.escalatedToHead = true;
      complaint.escalationReason = 
          'SLA Breached: Overdue by ${delayDays}d ${delayDuration.inHours % 24}h - Escalated to Department Head on ${DateFormat('dd-MM-yyyy HH:mm').format(now)}';

      // 2. Set new 2-day deadline
      final newDeadline = now.add(const Duration(days: 2));
      complaint.autoGovSlaDeadline = newDeadline;

      print('🆕 New SLA Deadline: ${DateFormat('dd-MM-yyyy HH:mm').format(newDeadline)}');
      print('───────────────────────────────────────────────────────────');

      // 3. Record escalation in local storage and Firestore
      await _complaintService.saveComplaints();
      await _firestoreService.upsertComplaint(complaint);

      print('✅ Complaint escalation status updated in Firestore');

      // 4. Penalize assigned officer
      if (complaint.assignedOfficerId != null) {
        await _penalizeOfficer(complaint.assignedOfficerId!, delayDays);
      }

      // 5. Log escalation for audit trail
      _logEscalationHistory(complaint, delayDays, delayHours, now);

      // 6. Citizen notification
      _notifyCitizen(complaint, delayDays);

      print('═══════════════════════════════════════════════════════════');
      print('✨ Escalation Complete - Complaint now with Department Head');
      print('═══════════════════════════════════════════════════════════\n');
    } catch (e) {
      print('❌ Failed to escalate complaint ${complaint.id}: $e');
    }
  }

  /// Penalize officer for SLA breach
  Future<void> _penalizeOfficer(String officerId, int delayDays) async {
    try {
      await _officersService.addPenaltyPoint(officerId);
      print('⚠️  Officer Penalty: -1 point (SLA breach by $delayDays days)');
      print('📊 Performance Impact: Penalty recorded in officer record');
    } catch (e) {
      print('❌ Failed to penalize officer: $e');
    }
  }

  /// Log escalation for audit trail
  void _logEscalationHistory(
    Complaint complaint,
    int delayDays,
    int delayHours,
    DateTime escalationTime,
  ) {
    final escalationLog = '''
╔═══════════════════════════════════════════════════════════╗
║                 ESCALATION AUDIT LOG                      ║
╠═══════════════════════════════════════════════════════════╣
║ Complaint ID:      ${complaint.id.padRight(46)}║
║ Title:             ${complaint.title.padRight(46)}║
║ Status:            ${complaint.status.displayName.padRight(46)}║
║ Escalation Time:   ${DateFormat('dd-MM-yyyy HH:mm:ss').format(escalationTime).padRight(46)}║
║ Delay Duration:    ${delayDays}d ${delayHours % 24}h${' '.padRight(39)}║
║ Escalated To:      Department Head${' '.padRight(32)}║
║ New Deadline:      ${DateFormat('dd-MM-yyyy HH:mm').format(complaint.autoGovSlaDeadline!).padRight(46)}║
║ Officer ID:        ${(complaint.assignedOfficerId ?? 'None').padRight(46)}║
║ Officer Name:      ${(complaint.autoGovOfficerName ?? 'Unassigned').padRight(46)}║
║ Department:        ${(complaint.autoGovDepartment ?? 'N/A').padRight(46)}║
╠═══════════════════════════════════════════════════════════╣
║ Action: Case escalated due to SLA deadline breach         ║
║ Accountability: Officer penalized (-1 point)              ║
║ Monitoring: Active until resolution                       ║
╚═══════════════════════════════════════════════════════════╝
''';
    print(escalationLog);
  }

  /// Notify citizen of escalation
  void _notifyCitizen(Complaint complaint, int delayDays) {
    print('📢 CITIZEN NOTIFICATION');
    print('─────────────────────────────────────────────────────────');
    print('Dear ${complaint.citizenName},');
    print('');
    print('Your complaint (ID: ${complaint.id}) has been escalated');
    print('to the Department Head due to a delay of $delayDays days.');
    print('');
    print('📌 Your Matter Has Escalated To: DEPARTMENT HEAD');
    print('⏰ New Resolution Deadline: ${DateFormat('dd-MM-yyyy HH:mm').format(complaint.autoGovSlaDeadline!)}');
    print('📱 Phone: ${complaint.citizenPhone}');
    print('');
    print('Your complaint is now receiving priority attention.');
    print('You can track progress in the Citizen Portal.');
    print('─────────────────────────────────────────────────────────\n');
  }

  /// Get escalation status of a complaint
  Map<String, dynamic> getEscalationStatus(String complaintId) {
    final complaint = _complaintService.getComplaintById(complaintId);
    if (complaint == null) {
      return {'escalated': false, 'reason': 'Complaint not found'};
    }

    if (!complaint.escalatedToHead) {
      final now = DateTime.now();
      if (complaint.autoGovSlaDeadline != null && now.isAfter(complaint.autoGovSlaDeadline!)) {
        final delay = now.difference(complaint.autoGovSlaDeadline!);
        return {
          'escalated': false,
          'overdue': true,
          'delayDays': delay.inDays,
          'delayHours': delay.inHours % 24,
          'deadline': complaint.autoGovSlaDeadline?.toIso8601String(),
          'reason': 'Pending escalation (check will trigger escalation)',
        };
      }
      return {'escalated': false, 'onTrack': true};
    }

    return {
      'escalated': true,
      'escalationTime': complaint.autoGovSlaDeadline?.toIso8601String(),
      'reason': complaint.escalationReason,
      'newDeadline': complaint.autoGovSlaDeadline?.toIso8601String(),
    };
  }
}
