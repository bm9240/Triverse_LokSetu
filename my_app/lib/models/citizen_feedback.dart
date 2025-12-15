/// Trust & Reputation System - Citizen Feedback Model
/// Emoji-only feedback after complaint resolution

enum CitizenFeedback {
  positive, // Satisfied
  neutral, // Partially resolved
  negative, // Not resolved
}

extension CitizenFeedbackExtension on CitizenFeedback {
  String get emoji {
    switch (this) {
      case CitizenFeedback.positive:
        return '😊';
      case CitizenFeedback.neutral:
        return '😐';
      case CitizenFeedback.negative:
        return '😞';
    }
  }

  String get label {
    switch (this) {
      case CitizenFeedback.positive:
        return 'Satisfied';
      case CitizenFeedback.neutral:
        return 'Partially Resolved';
      case CitizenFeedback.negative:
        return 'Not Resolved';
    }
  }

  double get scoreValue {
    switch (this) {
      case CitizenFeedback.positive:
        return 1.0;
      case CitizenFeedback.neutral:
        return 0.5;
      case CitizenFeedback.negative:
        return 0.0;
    }
  }
}

class FeedbackEntry {
  final String complaintId;
  final CitizenFeedback feedback;
  final DateTime submittedAt;

  FeedbackEntry({
    required this.complaintId,
    required this.feedback,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'complaintId': complaintId,
        'feedback': feedback.toString(),
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
        complaintId: json['complaintId'],
        feedback: CitizenFeedback.values.firstWhere(
          (e) => e.toString() == json['feedback'],
        ),
        submittedAt: DateTime.parse(json['submittedAt']),
      );
}
