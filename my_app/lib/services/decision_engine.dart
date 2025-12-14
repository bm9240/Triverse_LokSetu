import '../models/autogov_complaint.dart';
import 'dart:math';

/// Context-Aware Decision Engine
/// Determines department, priority, and SLA based on multiple factors
class DecisionEngine {
  static final DecisionEngine _instance = DecisionEngine._internal();
  factory DecisionEngine() => _instance;
  DecisionEngine._internal();

  // Track repeat complaints per location
  final Map<String, List<String>> _locationComplaintHistory = {};
  
  // Track department workload
  final Map<String, int> _departmentWorkload = {};

  /// Main decision-making method
  DecisionResult makeDecision(AutoGovComplaintExtension complaint) {
    // Step 1: Determine responsible department
    final department = _determineDepartment(complaint.category);
    
    // Step 2: Calculate base priority
    final basePriority = _calculateBasePriority(
      complaint.urgency,
      complaint.category,
    );
    
    // Step 3: Adjust priority based on context
    final adjustedPriority = _adjustPriorityByContext(
      basePriority,
      complaint,
      department,
    );
    
    // Step 4: Determine SLA duration
    final slaDuration = _determineSLA(
      adjustedPriority,
      complaint.category,
      complaint.urgency,
    );
    
    // Step 5: Update workload tracking
    _updateDepartmentWorkload(department);
    _trackLocationHistory(complaint);
    
    return DecisionResult(
      department: department,
      priority: adjustedPriority,
      slaDuration: slaDuration,
      reasoning: _generateReasoning(complaint, department, adjustedPriority),
    );
  }

  /// Determine department based on complaint category
  String _determineDepartment(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('road') || 
        categoryLower.contains('pothole') ||
        categoryLower.contains('highway')) {
      return 'Public Works Department';
    } else if (categoryLower.contains('water') || 
               categoryLower.contains('drainage') ||
               categoryLower.contains('sewer')) {
      return 'Water Supply & Sanitation';
    } else if (categoryLower.contains('electric') || 
               categoryLower.contains('power') ||
               categoryLower.contains('light')) {
      return 'Electricity Board';
    } else if (categoryLower.contains('garbage') || 
               categoryLower.contains('waste') ||
               categoryLower.contains('sanitation')) {
      return 'Waste Management';
    } else if (categoryLower.contains('park') || 
               categoryLower.contains('garden') ||
               categoryLower.contains('tree')) {
      return 'Parks & Recreation';
    } else if (categoryLower.contains('traffic') || 
               categoryLower.contains('signal') ||
               categoryLower.contains('parking')) {
      return 'Traffic Police';
    } else if (categoryLower.contains('health') || 
               categoryLower.contains('hospital') ||
               categoryLower.contains('clinic')) {
      return 'Health Department';
    } else if (categoryLower.contains('education') || 
               categoryLower.contains('school')) {
      return 'Education Department';
    } else if (categoryLower.contains('tax') || 
               categoryLower.contains('property')) {
      return 'Revenue Department';
    } else {
      return 'General Administration';
    }
  }

  /// Calculate base priority from urgency and category
  PriorityLevel _calculateBasePriority(
    UrgencyLevel urgency,
    String category,
  ) {
    // Critical urgency always gets P1 or P2
    if (urgency == UrgencyLevel.critical) {
      return PriorityLevel.p1;
    }
    
    // High urgency with critical categories
    if (urgency == UrgencyLevel.high) {
      if (_isCriticalCategory(category)) {
        return PriorityLevel.p1;
      }
      return PriorityLevel.p2;
    }
    
    // Medium urgency
    if (urgency == UrgencyLevel.medium) {
      if (_isCriticalCategory(category)) {
        return PriorityLevel.p2;
      }
      return PriorityLevel.p3;
    }
    
    // Low urgency
    return PriorityLevel.p4;
  }

  /// Check if category is critical (safety/health related)
  bool _isCriticalCategory(String category) {
    final critical = [
      'water',
      'health',
      'electric',
      'fire',
      'emergency',
      'safety',
      'accident',
    ];
    final categoryLower = category.toLowerCase();
    return critical.any((c) => categoryLower.contains(c));
  }

  /// Adjust priority based on contextual factors
  PriorityLevel _adjustPriorityByContext(
    PriorityLevel basePriority,
    AutoGovComplaintExtension complaint,
    String department,
  ) {
    int adjustment = 0;
    
    // Check for repeat complaints in same location
    final locationKey = '${complaint.location.city}_${complaint.location.ward}';
    final historyCount = _locationComplaintHistory[locationKey]?.length ?? 0;
    
    if (historyCount >= 5) {
      adjustment -= 2; // Increase priority (lower number = higher priority)
    } else if (historyCount >= 3) {
      adjustment -= 1;
    }
    
    // Check department workload
    final workload = _departmentWorkload[department] ?? 0;
    if (workload > 50) {
      adjustment += 1; // Slight decrease in priority due to overload
    }
    
    // Apply adjustment
    final currentIndex = PriorityLevel.values.indexOf(basePriority);
    final newIndex = (currentIndex + adjustment).clamp(0, PriorityLevel.values.length - 1);
    
    return PriorityLevel.values[newIndex];
  }

  /// Determine SLA duration based on priority and context
  Duration _determineSLA(
    PriorityLevel priority,
    String category,
    UrgencyLevel urgency,
  ) {
    Duration baseSLA = priority.defaultSLA;
    
    // Adjust for critical categories
    if (_isCriticalCategory(category) && urgency == UrgencyLevel.critical) {
      return Duration(hours: max(2, baseSLA.inHours ~/ 2));
    }
    
    return baseSLA;
  }

  /// Update department workload counter
  void _updateDepartmentWorkload(String department) {
    _departmentWorkload[department] = (_departmentWorkload[department] ?? 0) + 1;
  }

  /// Track complaint history by location
  void _trackLocationHistory(AutoGovComplaintExtension complaint) {
    final locationKey = '${complaint.location.city}_${complaint.location.ward}';
    _locationComplaintHistory.putIfAbsent(locationKey, () => []);
    _locationComplaintHistory[locationKey]!.add(complaint.complaintId);
  }

  /// Decrease workload when complaint is resolved
  void decreaseWorkload(String department) {
    if (_departmentWorkload.containsKey(department) && 
        _departmentWorkload[department]! > 0) {
      _departmentWorkload[department] = _departmentWorkload[department]! - 1;
    }
  }

  /// Generate reasoning for decision
  String _generateReasoning(
    AutoGovComplaintExtension complaint,
    String department,
    PriorityLevel priority,
  ) {
    final locationKey = '${complaint.location.city}_${complaint.location.ward}';
    final repeatCount = _locationComplaintHistory[locationKey]?.length ?? 0;
    final workload = _departmentWorkload[department] ?? 0;
    
    final reasons = <String>[
      'Category: ${complaint.category} → $department',
      'Urgency: ${complaint.urgency.displayName}',
      'Priority: ${priority.displayName}',
    ];
    
    if (repeatCount > 0) {
      reasons.add('Repeat complaints in location: $repeatCount');
    }
    
    if (workload > 0) {
      reasons.add('Department workload: $workload active complaints');
    }
    
    return reasons.join(' | ');
  }

  /// Get current department workload
  Map<String, int> getDepartmentWorkload() {
    return Map.unmodifiable(_departmentWorkload);
  }

  /// Get location complaint history
  int getLocationComplaintCount(String city, String ward) {
    final locationKey = '${city}_${ward}';
    return _locationComplaintHistory[locationKey]?.length ?? 0;
  }

  /// Reset tracking data (for testing/admin purposes)
  void resetTracking() {
    _locationComplaintHistory.clear();
    _departmentWorkload.clear();
  }
}

/// Result of decision-making process
class DecisionResult {
  final String department;
  final PriorityLevel priority;
  final Duration slaDuration;
  final String reasoning;

  DecisionResult({
    required this.department,
    required this.priority,
    required this.slaDuration,
    required this.reasoning,
  });

  @override
  String toString() => reasoning;
}
