/// Trust & Reputation System - Trust Score Model
/// Calculates and tracks citizen trust based on complaint patterns
/// NEVER rejects complaints - only flags for optional verification

enum TrustStatus {
  high,
  medium,
  low,
}

extension TrustStatusExtension on TrustStatus {
  String get displayName {
    switch (this) {
      case TrustStatus.high:
        return 'High confidence';
      case TrustStatus.medium:
        return 'Additional clarification may help';
      case TrustStatus.low:
        return 'Sent for verification';
    }
  }

  String get internalLabel {
    switch (this) {
      case TrustStatus.high:
        return 'HIGH';
      case TrustStatus.medium:
        return 'MEDIUM';
      case TrustStatus.low:
        return 'LOW';
    }
  }
}

/// Trust calculation factors
class TrustFactors {
  final double inputConsistency; // 0.0 to 1.0
  final double photoTextMatch; // 0.0 to 1.0 (IMPORTANT: mismatch is risk signal)
  final double evidencePresence; // 0.0 to 1.0
  final double historicalBehavior; // 0.0 to 1.0
  final double severityMisuse; // 0.0 to 1.0 (1.0 = no misuse)

  TrustFactors({
    required this.inputConsistency,
    required this.photoTextMatch,
    required this.evidencePresence,
    required this.historicalBehavior,
    required this.severityMisuse,
  });

  /// Calculate overall trust score (0-100)
  int calculateScore() {
    // Weighted calculation - photo-text match is most important
    final weightedScore = (inputConsistency * 0.2) +
        (photoTextMatch * 0.35) + // Highest weight - mismatch is critical
        (evidencePresence * 0.15) +
        (historicalBehavior * 0.2) +
        (severityMisuse * 0.1);

    return (weightedScore * 100).round();
  }

  /// Determine trust status from score
  TrustStatus getTrustStatus(int score) {
    if (score >= 80) return TrustStatus.high;
    if (score >= 60) return TrustStatus.medium;
    return TrustStatus.low;
  }
}

/// Clarification request from official (Yes/No questions)
class ClarificationRequest {
  final String requestedBy; // Official ID
  final DateTime requestedAt;
  final List<ClarificationQuestion> questions;
  DateTime? respondedAt;

  ClarificationRequest({
    required this.requestedBy,
    required this.requestedAt,
    required this.questions,
    this.respondedAt,
  });

  bool get isAnswered => questions.every((q) => q.answer != null);

  Map<String, dynamic> toJson() => {
        'requestedBy': requestedBy,
        'requestedAt': requestedAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory ClarificationRequest.fromJson(Map<String, dynamic> json) =>
      ClarificationRequest(
        requestedBy: json['requestedBy'],
        requestedAt: DateTime.parse(json['requestedAt']),
        questions: (json['questions'] as List)
            .map((q) => ClarificationQuestion.fromJson(q))
            .toList(),
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'])
            : null,
      );
}

/// Individual clarification question
class ClarificationQuestion {
  final String question;
  bool? answer; // null = not answered, true = yes, false = no

  ClarificationQuestion({
    required this.question,
    this.answer,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

  factory ClarificationQuestion.fromJson(Map<String, dynamic> json) =>
      ClarificationQuestion(
        question: json['question'],
        answer: json['answer'],
      );
}

/// Validation request from official
class ValidationRequest {
  final String requestedBy; // Official ID
  final DateTime requestedAt;
  final String? question; // Optional clarification question
  bool? citizenConfirmed; // null = no response, true/false = response
  DateTime? respondedAt;

  ValidationRequest({
    required this.requestedBy,
    required this.requestedAt,
    this.question,
    this.citizenConfirmed,
    this.respondedAt,
  });

  Map<String, dynamic> toJson() => {
        'requestedBy': requestedBy,
        'requestedAt': requestedAt.toIso8601String(),
        'question': question,
        'citizenConfirmed': citizenConfirmed,
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory ValidationRequest.fromJson(Map<String, dynamic> json) =>
      ValidationRequest(
        requestedBy: json['requestedBy'],
        requestedAt: DateTime.parse(json['requestedAt']),
        question: json['question'],
        citizenConfirmed: json['citizenConfirmed'],
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'])
            : null,
      );
}
