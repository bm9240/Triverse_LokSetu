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
    final c = category.toLowerCase();

    // 1. Streetlight & Electricity
    if (c.contains('streetlight') || c.contains('street light') || c.contains('electric') || c.contains('power') || c.contains('light')) {
      return 'Electricity Board';
    }

    // 2. Roads & Infrastructure
    if (c.contains('road') || c.contains('pothole') || c.contains('pavement') || c.contains('footpath') || c.contains('infrastructure')) {
      return 'Public Works Department';
    }

    // 3. Water Supply
    if (c.contains('water') || c.contains('pipe') || c.contains('leak') || c.contains('quality')) {
      return 'Water Supply & Sanitation';
    }

    // 4. Sanitation & Waste
    if (c.contains('sanitation') || c.contains('garbage') || c.contains('waste') || c.contains('collection') || c.contains('disposal')) {
      return 'Waste Management';
    }

    // 5. Drainage & Flooding
    if (c.contains('drain') || c.contains('drainage') || c.contains('sewer') || c.contains('flood') || c.contains('waterlogging') || c.contains('water logging')) {
      return 'Water Supply & Sanitation';
    }

    // 6. Traffic & Transport
    if (c.contains('traffic') || c.contains('signal') || c.contains('parking') || c.contains('transport') || c.contains('bus') || c.contains('public transport')) {
      return 'Traffic Police';
    }

    // 7. Public Safety
    if (c.contains('safety') || c.contains('security') || c.contains('harass') || c.contains('crime') || c.contains('assault') || c.contains('law & order')) {
      return 'Public Safety & Services';
    }

    // 8. Parks & Public Spaces
    if (c.contains('park') || c.contains('garden') || c.contains('playground') || c.contains('public space') || c.contains('tree')) {
      return 'Parks & Recreation';
    }

    // 9. Public Health
    if (c.contains('health') || c.contains('hospital') || c.contains('clinic') || c.contains('sanitary') || c.contains('disease')) {
      return 'Health Department';
    }

    // 10. Environment
    if (c.contains('pollution') || c.contains('air quality') || c.contains('noise') || c.contains('environment')) {
      return 'Environment Department';
    }

    // 11. Housing & Urban Services
    if (c.contains('housing') || c.contains('urban') || c.contains('property') || c.contains('building') || c.contains('encroachment')) {
      return 'Urban Development';
    }

    // 12. Government Services
    if (c.contains('government service') || c.contains('service delivery') || c.contains('certificate') || c.contains('document') || c.contains('application')) {
      return 'Citizen Services Center';
    }

    // 13. Other Civic Issue
    if (c.contains('other civic') || c.contains('other') || c.contains('misc')) {
      return 'General Administration';
    }

    // Fallback: heuristic using previous general mapping
    if (c.contains('education') || c.contains('school')) {
      return 'Education Department';
    }
    if (c.contains('tax')) {
      return 'Revenue Department';
    }

    return 'General Administration';
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
