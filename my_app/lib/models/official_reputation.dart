import 'citizen_feedback.dart';

/// Trust & Reputation System - Official Reputation Model
/// Admin-only reputation tracking based on performance metrics

class OfficialReputation {
  final String officerId;
  final String officerName;
  
  // Performance metrics
  int totalComplaints;
  int resolvedComplaints;
  int reopenedComplaints;
  double averageResponseTimeHours;
  
  // Citizen feedback aggregation
  int positiveFeedbacks;
  int neutralFeedbacks;
  int negativeFeedbacks;
  
  // Calculated reputation score (0-100)
  int reputationScore;
  
  DateTime lastUpdated;

  OfficialReputation({
    required this.officerId,
    required this.officerName,
    this.totalComplaints = 0,
    this.resolvedComplaints = 0,
    this.reopenedComplaints = 0,
    this.averageResponseTimeHours = 0.0,
    this.positiveFeedbacks = 0,
    this.neutralFeedbacks = 0,
    this.negativeFeedbacks = 0,
    this.reputationScore = 50, // Start neutral
    required this.lastUpdated,
  });

  /// Calculate reputation score based on all factors
  void calculateReputationScore() {
    if (totalComplaints == 0) {
      reputationScore = 50; // Neutral for new officials
      return;
    }

    double score = 50.0; // Base score

    // 1. Resolution rate (30% weight)
    final resolutionRate = resolvedComplaints / totalComplaints;
    score += (resolutionRate - 0.5) * 30;

    // 2. Citizen feedback (40% weight) - MOST IMPORTANT
    final totalFeedbacks = positiveFeedbacks + neutralFeedbacks + negativeFeedbacks;
    if (totalFeedbacks > 0) {
      final feedbackScore = (positiveFeedbacks * 1.0 + 
                             neutralFeedbacks * 0.5 + 
                             negativeFeedbacks * 0.0) / totalFeedbacks;
      score += (feedbackScore - 0.5) * 40;
    }

    // 3. Reopen penalty (15% weight)
    if (resolvedComplaints > 0) {
      final reopenRate = reopenedComplaints / resolvedComplaints;
      score -= reopenRate * 15;
    }

    // 4. Response time (15% weight) - faster is better
    // Target: 24 hours or less = bonus, >72 hours = penalty
    if (averageResponseTimeHours <= 24) {
      score += 15;
    } else if (averageResponseTimeHours > 72) {
      score -= 15;
    } else {
      // Proportional between 24-72 hours
      final timeRatio = (72 - averageResponseTimeHours) / 48;
      score += timeRatio * 15;
    }

    // Clamp between 0-100
    reputationScore = score.round().clamp(0, 100);
    lastUpdated = DateTime.now();
  }

  /// Add citizen feedback
  void addFeedback(CitizenFeedback feedback) {
    switch (feedback) {
      case CitizenFeedback.positive:
        positiveFeedbacks++;
        break;
      case CitizenFeedback.neutral:
        neutralFeedbacks++;
        break;
      case CitizenFeedback.negative:
        negativeFeedbacks++;
        break;
    }
    calculateReputationScore();
  }

  /// Update metrics after complaint resolution
  void updateMetrics({
    required bool resolved,
    required double responseTimeHours,
    bool? reopened,
  }) {
    totalComplaints++;
    if (resolved) resolvedComplaints++;
    if (reopened == true) reopenedComplaints++;
    
    // Update rolling average for response time
    averageResponseTimeHours = 
        ((averageResponseTimeHours * (totalComplaints - 1)) + responseTimeHours) / 
        totalComplaints;
    
    calculateReputationScore();
  }

  /// Get reputation tier
  String get reputationTier {
    if (reputationScore >= 80) return 'Excellent';
    if (reputationScore >= 60) return 'Good';
    if (reputationScore >= 40) return 'Average';
    return 'Needs Improvement';
  }

  Map<String, dynamic> toJson() => {
        'officerId': officerId,
        'officerName': officerName,
        'totalComplaints': totalComplaints,
        'resolvedComplaints': resolvedComplaints,
        'reopenedComplaints': reopenedComplaints,
        'averageResponseTimeHours': averageResponseTimeHours,
        'positiveFeedbacks': positiveFeedbacks,
        'neutralFeedbacks': neutralFeedbacks,
        'negativeFeedbacks': negativeFeedbacks,
        'reputationScore': reputationScore,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory OfficialReputation.fromJson(Map<String, dynamic> json) =>
      OfficialReputation(
        officerId: json['officerId'],
        officerName: json['officerName'],
        totalComplaints: json['totalComplaints'] ?? 0,
        resolvedComplaints: json['resolvedComplaints'] ?? 0,
        reopenedComplaints: json['reopenedComplaints'] ?? 0,
        averageResponseTimeHours: json['averageResponseTimeHours']?.toDouble() ?? 0.0,
        positiveFeedbacks: json['positiveFeedbacks'] ?? 0,
        neutralFeedbacks: json['neutralFeedbacks'] ?? 0,
        negativeFeedbacks: json['negativeFeedbacks'] ?? 0,
        reputationScore: json['reputationScore'] ?? 50,
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}
