import '../models/trust_score.dart';
import '../models/complaint.dart';

/// Trust & Reputation System - Trust Calculation Service
/// Calculates citizen trust based on complaint patterns
/// NEVER rejects complaints - only provides risk signals

class TrustService {
  /// Calculate trust score for a new complaint
  static TrustFactors calculateTrustFactors({
    required Complaint complaint,
    required List<Complaint> citizenHistory,
  }) {
    return TrustFactors(
      inputConsistency: _assessInputConsistency(complaint),
      photoTextMatch: _assessPhotoTextMatch(complaint),
      evidencePresence: _assessEvidencePresence(complaint),
      historicalBehavior: _assessHistoricalBehavior(citizenHistory),
      severityMisuse: _assessSeverityMisuse(complaint, citizenHistory),
    );
  }

  /// Assess input consistency (category, location, duration logic)
  static double _assessInputConsistency(Complaint complaint) {
    double score = 1.0;

    // Check if duration matches severity
    if (complaint.duration != null) {
      final isUrgent = complaint.severity == 'High' || complaint.severity == 'Critical';
      final isLongDuration = complaint.duration!.toLowerCase().contains('month') ||
          complaint.duration!.toLowerCase().contains('year');

      // Inconsistency: Critical + reported just today
      if (isUrgent && 
          (complaint.duration!.contains('today') || complaint.duration!.contains('1 day'))) {
        score -= 0.2;
      }

      // Inconsistency: Low severity + very long duration
      if (complaint.severity == 'Low' && isLongDuration) {
        score -= 0.1;
      }
    }

    // Check if category matches description keywords
    final categoryKeywords = {
      'Streetlight & Electricity': ['light', 'electricity', 'power', 'bulb'],
      'Roads & Infrastructure': ['road', 'pothole', 'street', 'pavement'],
      'Water Supply': ['water', 'tap', 'pipe', 'supply'],
      'Sanitation & Waste': ['garbage', 'waste', 'trash', 'cleaning'],
      'Drainage & Flooding': ['drain', 'flood', 'water logging', 'overflow'],
    };

    final keywords = categoryKeywords[complaint.category];
    if (keywords != null) {
      final descLower = complaint.description.toLowerCase();
      final hasMatch = keywords.any((kw) => descLower.contains(kw));
      if (!hasMatch) score -= 0.15;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Assess photo-text match (CRITICAL: category-level mismatch is risk signal)
  static double _assessPhotoTextMatch(Complaint complaint) {
    // If no photo, neutral (no penalty for text-only)
    if (complaint.imagePath == null) return 0.7;

    // Photo present - use category-level matching
    // In real implementation, this would use ML/Computer Vision
    // For now, check if photo category context matches complaint category

    final category = complaint.category;
    final descLower = complaint.description.toLowerCase();

    // Category-level match indicators
    final categoryContexts = {
      'Streetlight & Electricity': ['light', 'electricity', 'power', 'dark', 'bulb', 'pole'],
      'Roads & Infrastructure': ['road', 'pothole', 'crack', 'street', 'pavement', 'damage'],
      'Water Supply': ['water', 'tap', 'pipe', 'leak', 'supply', 'dry'],
      'Sanitation & Waste': ['garbage', 'waste', 'trash', 'dump', 'cleaning', 'dirty'],
      'Drainage & Flooding': ['drain', 'flood', 'water', 'overflow', 'clog', 'block'],
    };

    final contexts = categoryContexts[category];
    if (contexts != null) {
      final hasMatch = contexts.any((ctx) => descLower.contains(ctx));
      if (hasMatch) {
        return 1.0; // Clear category match
      } else {
        return 0.5; // Ambiguous - category unclear
      }
    }

    // Default: assume match for other categories
    return 0.7;
  }

  /// Assess evidence presence (REWARD ONLY - no punishment for lack of tech)
  static double _assessEvidencePresence(Complaint complaint) {
    // Photo or video attached
    if (complaint.imagePath != null) return 1.0;

    // Check for structured details (location, duration, severity)
    bool hasStructuredDetails = 
        complaint.location.isNotEmpty &&
        complaint.duration != null &&
        complaint.severity.isNotEmpty;

    if (hasStructuredDetails) return 0.8; // Structured text details
    
    // Basic text-only complaint (neutral - no penalty)
    return 0.6;
  }

  /// Assess historical behavior (pattern-based, context-aware)
  static double _assessHistoricalBehavior(List<Complaint> citizenHistory) {
    if (citizenHistory.isEmpty) return 0.8; // Higher base for new citizens

    double score = 1.0;

    final today = DateTime.now();
    
    // Check for rapid-fire complaints (within 1 hour) - These are highly suspicious
    final recentComplaints = citizenHistory.where((c) {
      final timeDiff = today.difference(c.submittedAt).inMinutes;
      return timeDiff <= 60; // Within last hour
    }).toList();

    // Rapid-fire penalty (very strong)
    if (recentComplaints.length >= 4) {
      score -= 0.7; // 4+ complaints in 1 hour - severe penalty
    } else if (recentComplaints.length >= 3) {
      score -= 0.6; // 3 complaints in 1 hour - major penalty
    } else if (recentComplaints.length >= 2) {
      score -= 0.5; // 2 complaints in 1 hour - significant penalty
    } else if (recentComplaints.length == 1) {
      score -= 0.3; // 1 complaint in last hour - warning
    }

    // Check for same-day complaints (separate from rapid-fire)
    final todayComplaints = citizenHistory.where((c) {
      final submittedDate = c.submittedAt;
      return submittedDate.year == today.year &&
             submittedDate.month == today.month &&
             submittedDate.day == today.day;
    }).toList();

    // Add 1 to count current complaint
    final totalTodayIncludingCurrent = todayComplaints.length + 1;

    // Progressive same-day penalties (only apply if not already rapid-fire)
    if (recentComplaints.length == 0) {
      // No rapid-fire, but multiple today
      if (totalTodayIncludingCurrent >= 5) {
        score -= 0.5; // 5+ complaints today - major penalty
      } else if (totalTodayIncludingCurrent >= 4) {
        score -= 0.4; // 4 complaints today - significant penalty
      } else if (totalTodayIncludingCurrent >= 3) {
        score -= 0.3; // 3 complaints today - moderate penalty
      } else if (totalTodayIncludingCurrent == 2) {
        score -= 0.1; // 2 complaints today - light warning
      }
    }

    // Calculate accuracy from past complaints
    int totalPast = citizenHistory.length;
    int suspiciousCount = 0;

    for (var past in citizenHistory) {
      // Count complaints that were marked as low trust
      if (past.trustStatus == TrustStatus.low) {
        suspiciousCount++;
      }
    }

    // Pattern-based: Single mistake is fine, repeated issues reduce trust
    if (suspiciousCount == 0) {
      // Keep current score
    } else if (suspiciousCount == 1 && totalPast >= 3) {
      score -= 0.1; // One mistake is OK
    } else if (suspiciousCount >= 2) {
      final accuracyPenalty = (suspiciousCount / totalPast) * 0.3;
      score -= accuracyPenalty; // Reduced penalty
    }
    
    return score.clamp(0.2, 1.0); // Lowered minimum to 0.2 for severe cases
  }

  /// Assess severity misuse
  static double _assessSeverityMisuse(
    Complaint complaint,
    List<Complaint> citizenHistory,
  ) {
    if (citizenHistory.isEmpty) return 1.0;

    // Count how often citizen uses High/Critical severity
    int highSeverityCount = citizenHistory
        .where((c) => c.severity == 'High' || c.severity == 'Critical')
        .length;

    // If >70% complaints are high severity, potential misuse
    final highSeverityRate = highSeverityCount / citizenHistory.length;
    if (highSeverityRate > 0.7) return 0.5;
    if (highSeverityRate > 0.5) return 0.7;

    return 1.0;
  }

  /// Update trust after validation response
  static int adjustTrustAfterValidation({
    required int currentScore,
    required bool citizenConfirmed,
  }) {
    if (citizenConfirmed) {
      // Citizen confirmed - partially restore trust
      return (currentScore + 20).clamp(0, 100);
    } else {
      // Citizen did not confirm - maintain low trust
      return currentScore;
    }
  }

  /// Check if validation should be allowed
  static bool canRequestValidation(TrustStatus status) {
    return status == TrustStatus.low;
  }
}
