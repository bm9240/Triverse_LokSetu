import '../models/official_reputation.dart';
import '../models/citizen_feedback.dart';
import '../models/complaint.dart';

/// Trust & Reputation System - Official Reputation Service
/// Manages official performance tracking and reputation calculation
/// Admin-only visibility

class ReputationService {
  // In-memory storage (in production, use database)
  static final Map<String, OfficialReputation> _reputations = {};

  /// Get or create reputation for an official
  static OfficialReputation getReputation(String officerId, String officerName) {
    if (!_reputations.containsKey(officerId)) {
      _reputations[officerId] = OfficialReputation(
        officerId: officerId,
        officerName: officerName,
        lastUpdated: DateTime.now(),
      );
    }
    return _reputations[officerId]!;
  }

  /// Update reputation after complaint resolution
  static void updateAfterResolution({
    required String officerId,
    required String officerName,
    required Complaint complaint,
    CitizenFeedback? feedback,
  }) {
    final reputation = getReputation(officerId, officerName);

    // Calculate response time
    final responseTimeHours = DateTime.now()
        .difference(complaint.submittedAt)
        .inHours
        .toDouble();

    // Update metrics
    reputation.updateMetrics(
      resolved: complaint.status == ComplaintStatus.completed,
      responseTimeHours: responseTimeHours,
    );

    // Add feedback if provided
    if (feedback != null) {
      reputation.addFeedback(feedback);
    }

    _reputations[officerId] = reputation;
  }

  /// Record when complaint is reopened
  static void recordReopen({
    required String officerId,
    required String officerName,
  }) {
    final reputation = getReputation(officerId, officerName);
    reputation.reopenedComplaints++;
    reputation.calculateReputationScore();
    _reputations[officerId] = reputation;
  }

  /// Get all official reputations (admin-only)
  static List<OfficialReputation> getAllReputations() {
    return _reputations.values.toList()
      ..sort((a, b) => b.reputationScore.compareTo(a.reputationScore));
  }

  /// Get reputation summary for dashboard
  static Map<String, dynamic> getReputationSummary(String officerId) {
    final reputation = _reputations[officerId];
    if (reputation == null) {
      return {
        'score': 50,
        'tier': 'New',
        'totalComplaints': 0,
      };
    }

    final totalFeedbacks = reputation.positiveFeedbacks +
        reputation.neutralFeedbacks +
        reputation.negativeFeedbacks;

    return {
      'score': reputation.reputationScore,
      'tier': reputation.reputationTier,
      'totalComplaints': reputation.totalComplaints,
      'resolvedComplaints': reputation.resolvedComplaints,
      'avgResponseTime': reputation.averageResponseTimeHours.toStringAsFixed(1),
      'positiveFeedbackRate': totalFeedbacks > 0
          ? ((reputation.positiveFeedbacks / totalFeedbacks) * 100).toStringAsFixed(0)
          : '0',
    };
  }

  /// Clear all data (for testing)
  static void clearAll() {
    _reputations.clear();
  }
}
