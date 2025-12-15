import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import '../models/trust_score.dart';
import '../models/citizen_feedback.dart';
import '../models/official_reputation.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/reputation_service.dart';
import 'complaint_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedComplaintId = '';
  String _selectedView = 'home'; // 'home' or 'department'
  String? _selectedDepartment;

  // Keep department names in sync with DecisionEngine mappings
  final List<String> _departments = [
    'Public Works Department',
    'Water Supply & Sanitation',
    'Electricity Board',
    'Waste Management',
    'Traffic Police',
    'Public Safety & Services',
    'Parks & Recreation',
    'Health Department',
    'Environment Department',
    'Urban Development',
    'Citizen Services Center',
    'Education Department',
    'Revenue Department',
    'General Administration',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedView == 'home' 
            ? '🛡️ Admin Portal - Home'
            : _selectedDepartment != null
                ? '🏢 $_selectedDepartment'
                : '🏢 Departments'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedView == 'home' && _selectedDepartment == null)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All Complaints',
              onPressed: () => _showClearConfirmation(context),
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedComplaintId.isEmpty
          ? (_selectedView == 'home' 
              ? _buildComplaintsList()
              : _selectedView == 'reputation'
                  ? _buildReputationView()
                  : (_selectedDepartment != null
                      ? _buildDepartmentView()
                      : _buildDepartmentList()))
          : _buildProofUploadScreen(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.green),
            title: const Text('Home'),
            selected: _selectedView == 'home',
            onTap: () {
              setState(() {
                _selectedView = 'home';
                _selectedDepartment = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: const Text('Departments'),
            selected: _selectedView == 'department',
            onTap: () {
              setState(() {
                _selectedView = 'department';
                _selectedDepartment = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.stars, color: Colors.orange),
            title: const Text('Official Reputation'),
            selected: _selectedView == 'reputation',
            onTap: () {
              setState(() {
                _selectedView = 'reputation';
                _selectedDepartment = null;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentList() {
    final firestoreService = FirestoreService();
    
    return StreamBuilder<List<Complaint>>(
      stream: firestoreService.getComplaintsStream(),
      builder: (context, snapshot) {
        List<Complaint> complaints = [];
        
        // Use Firestore data if available, otherwise fall back to Provider
        if (snapshot.hasData) {
          complaints = snapshot.data ?? [];
        } else {
          complaints = context.read<ComplaintProvider>().complaints;
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _departments.length,
          itemBuilder: (context, index) {
            final dept = _departments[index];
            final deptComplaints = complaints
                .where((c) => c.autoGovDepartment == dept && c.status != ComplaintStatus.completed)
                .length;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(_getDepartmentIcon(dept), color: Colors.green.shade700),
                ),
                title: Text(
                  dept,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$deptComplaints pending complaints'),
                    if (snapshot.hasData)
                      const Text(
                        '🔴 Live data',
                        style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  setState(() {
                    _selectedDepartment = dept;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  IconData _getDepartmentIcon(String dept) {
    if (dept.contains('Public Works')) return Icons.construction;
    if (dept.contains('Water')) return Icons.water_drop;
    if (dept.contains('Electricity')) return Icons.electric_bolt;
    if (dept.contains('Waste')) return Icons.delete;
    if (dept.contains('Safety')) return Icons.shield_moon;
    if (dept.contains('Parks')) return Icons.park;
    if (dept.contains('Environment')) return Icons.eco;
    if (dept.contains('Urban')) return Icons.location_city;
    if (dept.contains('Citizen Services')) return Icons.miscellaneous_services;
    if (dept.contains('Traffic')) return Icons.traffic;
    if (dept.contains('Health')) return Icons.local_hospital;
    if (dept.contains('Education')) return Icons.school;
    if (dept.contains('Revenue')) return Icons.account_balance;
    return Icons.business;
  }

  Widget _buildDepartmentView() {
    final firestoreService = FirestoreService();
    
    return StreamBuilder<List<Complaint>>(
      stream: firestoreService.getComplaintsStream(),
      builder: (context, snapshot) {
        List<Complaint> complaints = [];
        
        // Use Firestore data if available, otherwise fall back to local Provider data
        if (snapshot.hasData) {
          complaints = snapshot.data ?? [];
        } else {
          // Fallback to Provider data while Firestore loads
          complaints = context.read<ComplaintProvider>().complaints;
        }
        
        final deptComplaints = complaints
            .where((c) => c.autoGovDepartment == _selectedDepartment && c.status != ComplaintStatus.completed)
            .toList();

        final performers = _calculatePerformers(complaints, _selectedDepartment!);

        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Loading real-time data from $_selectedDepartment...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedDepartment = null;
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDepartment!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (snapshot.hasData)
                            Text(
                              '🔴 Live • ${deptComplaints.length} pending',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildPerformersSection('🏆 Top Performers of the Month', performers['top']!, Colors.green),
              const SizedBox(height: 16),
              _buildPerformersSection('⚠️ Needs Improvement', performers['worst']!, Colors.orange),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Pending Complaints (${deptComplaints.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (deptComplaints.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text('No pending complaints in $_selectedDepartment'),
                          ],
                        ),
                      )
                    else
                      ...deptComplaints.map((complaint) => _buildComplaintCard(complaint)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformersSection(String title, List<Map<String, dynamic>> performers, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color == Colors.green ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (performers.isEmpty)
            const Text('No data available yet')
          else
            ...performers.asMap().entries.map((entry) {
              final index = entry.key;
              final performer = entry.value;
              final escalatedCount = performer['escalatedCount'] as int? ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: escalatedCount > 0 
                      ? Border.all(color: Colors.red, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            performer['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            performer['designation'],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${performer['resolved']} resolved',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Avg: ${performer['avgTime']}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (escalatedCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-$escalatedCount SLA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _calculatePerformers(List<Complaint> allComplaints, String department) {
    final deptComplaints = allComplaints.where((c) => c.autoGovDepartment == department).toList();
    
    final Map<String, List<Complaint>> officerComplaints = {};
    for (var complaint in deptComplaints) {
      final officer = complaint.autoGovOfficerName ?? 'Unknown';
      officerComplaints.putIfAbsent(officer, () => []);
      officerComplaints[officer]!.add(complaint);
    }

    final List<Map<String, dynamic>> performers = [];
    
    officerComplaints.forEach((officer, complaints) {
      if (officer == 'Unknown' || officer == 'Not assigned') return;
      
      final resolved = complaints.where((c) => c.status == ComplaintStatus.completed).length;
      final total = complaints.length;
      
      // Count SLA breaches/escalations for this officer
      final escalatedCount = complaints.where((c) => c.escalatedToHead).length;
      
      final resolvedComplaints = complaints.where((c) => c.status == ComplaintStatus.completed).toList();
      double avgHours = 0;
      if (resolvedComplaints.isNotEmpty) {
        int totalHours = 0;
        for (var c in resolvedComplaints) {
          if (c.proofChain.isNotEmpty) {
            final lastProof = c.proofChain.last;
            totalHours += lastProof.timestamp.difference(c.submittedAt).inHours;
          }
        }
        avgHours = totalHours / resolvedComplaints.length;
      }

      final designation = complaints.first.autoGovOfficerDesignation ?? 'Officer';
      
      performers.add({
        'name': officer,
        'designation': designation,
        'resolved': resolved,
        'total': total,
        'avgTime': avgHours > 0 ? '${avgHours.toStringAsFixed(1)}h' : 'N/A',
        'avgHoursValue': avgHours,
        'resolutionRate': total > 0 ? resolved / total : 0,
        'escalatedCount': escalatedCount, // SLA breaches
        'penaltyMarked': escalatedCount > 0, // Marked for improvement if escalated
      });
    });

    performers.sort((a, b) {
      // Sort by escalations (those with more go to "Needs Improvement")
      final escalationDiff = b['escalatedCount'].compareTo(a['escalatedCount']);
      if (escalationDiff != 0) return escalationDiff;
      
      // Then by resolution rate
      final rateDiff = b['resolutionRate'].compareTo(a['resolutionRate']);
      if (rateDiff != 0) return rateDiff;
      if (a['avgHoursValue'] == 0) return 1;
      if (b['avgHoursValue'] == 0) return -1;
      return a['avgHoursValue'].compareTo(b['avgHoursValue']);
    });

    final top = performers.where((p) => p['escalatedCount'] == 0).take(3).toList();
    final worst = performers.where((p) => p['escalatedCount'] > 0).take(3).toList();

    return {
      'top': top,
      'worst': worst,
    };
  }

  Widget _buildComplaintsList() {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        final pendingComplaints = provider.complaints
            .where((c) => c.status != ComplaintStatus.completed && !c.escalatedToHead)
            .toList();
        final escalatedComplaints = provider.complaints
            .where((c) => c.escalatedToHead && c.status != ComplaintStatus.completed)
            .toList();

        if (pendingComplaints.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No Pending Complaints',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'All complaints have been resolved!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // AutoGov Engine Status Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AutoGov Engine Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          provider.getAutoGovStats(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => provider.checkEscalations(),
                    tooltip: 'Check Escalations',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (escalatedComplaints.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade600, Colors.orange.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.report, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Escalated Complaints',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'These require department head attention. Prioritize resolution.',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Text(
                              '${escalatedComplaints.length} total',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (escalatedComplaints.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...escalatedComplaints.map((c) => _buildComplaintCard(c)),
                        ],
                      ),
                    ),
                  ...pendingComplaints.map((complaint) => _buildComplaintCard(complaint)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReputationView() {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        // Get all resolved complaints with assigned officers
        final resolvedComplaints = provider.complaints
            .where((c) => 
                c.status == ComplaintStatus.completed && 
                c.assignedOfficerId != null)
            .toList();

        // Calculate reputation for each officer
        final officerReputations = <String, Map<String, dynamic>>{};
        
        for (var complaint in resolvedComplaints) {
          final officerId = complaint.assignedOfficerId!;
          final officerName = complaint.autoGovOfficerName ?? 'Unknown Officer';
          
          if (!officerReputations.containsKey(officerId)) {
            officerReputations[officerId] = {
              'name': officerName,
              'totalComplaints': 0,
              'resolvedComplaints': 0,
              'positiveFeedbacks': 0,
              'neutralFeedbacks': 0,
              'negativeFeedbacks': 0,
              'totalResponseTime': 0.0,
            };
          }

          final data = officerReputations[officerId]!;
          data['totalComplaints']++;
          data['resolvedComplaints']++;
          
          // Add feedback
          if (complaint.citizenFeedback != null) {
            if (complaint.citizenFeedback == CitizenFeedback.positive) {
              data['positiveFeedbacks']++;
            } else if (complaint.citizenFeedback == CitizenFeedback.neutral) {
              data['neutralFeedbacks']++;
            } else if (complaint.citizenFeedback == CitizenFeedback.negative) {
              data['negativeFeedbacks']++;
            }
          }

          // Calculate response time
          final responseTime = DateTime.now()
              .difference(complaint.submittedAt)
              .inHours
              .toDouble();
          data['totalResponseTime'] += responseTime;
        }

        // Calculate reputation scores
        final officerList = officerReputations.entries.map((entry) {
          final data = entry.value;
          final totalFeedbacks = data['positiveFeedbacks'] + 
                                 data['neutralFeedbacks'] + 
                                 data['negativeFeedbacks'];
          
          // Calculate reputation score
          double score = 50.0;
          
          // Feedback score (40%)
          if (totalFeedbacks > 0) {
            final feedbackScore = (data['positiveFeedbacks'] * 1.0 + 
                                   data['neutralFeedbacks'] * 0.5) / totalFeedbacks;
            score += (feedbackScore - 0.5) * 40;
          }
          
          // Resolution rate (30%)
          final resolutionRate = data['resolvedComplaints'] / data['totalComplaints'];
          score += (resolutionRate - 0.5) * 30;
          
          // Response time (30%)
          final avgResponseTime = data['totalResponseTime'] / data['totalComplaints'];
          if (avgResponseTime <= 24) {
            score += 30;
          } else if (avgResponseTime > 72) {
            score -= 30;
          } else {
            final timeRatio = (72 - avgResponseTime) / 48;
            score += timeRatio * 30;
          }
          
          return {
            'id': entry.key,
            'name': data['name'],
            'score': score.round().clamp(0, 100),
            'totalComplaints': data['totalComplaints'],
            'positiveFeedbacks': data['positiveFeedbacks'],
            'neutralFeedbacks': data['neutralFeedbacks'],
            'negativeFeedbacks': data['negativeFeedbacks'],
            'avgResponseTime': avgResponseTime,
          };
        }).toList();

        // Sort by score descending
        officerList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

        if (officerList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stars_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No Official Reputation Data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Reputation will be calculated once complaints are resolved',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.orange.shade700, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Reputation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Performance based on citizen feedback',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: officerList.length,
                itemBuilder: (context, index) {
                  final officer = officerList[index];
                  return _buildOfficerReputationCard(officer, index + 1);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfficerReputationCard(Map<String, dynamic> officer, int rank) {
    final score = officer['score'] as int;
    final name = officer['name'] as String;
    final totalComplaints = officer['totalComplaints'] as int;
    final positiveFeedbacks = officer['positiveFeedbacks'] as int;
    final neutralFeedbacks = officer['neutralFeedbacks'] as int;
    final negativeFeedbacks = officer['negativeFeedbacks'] as int;
    final avgResponseTime = officer['avgResponseTime'] as double;

    Color scoreColor;
    String tier;
    if (score >= 80) {
      scoreColor = Colors.green;
      tier = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.blue;
      tier = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      tier = 'Average';
    } else {
      scoreColor = Colors.red;
      tier = 'Needs Improvement';
    }

    final totalFeedbacks = positiveFeedbacks + neutralFeedbacks + negativeFeedbacks;
    final positiveRate = totalFeedbacks > 0 
        ? ((positiveFeedbacks / totalFeedbacks) * 100).toStringAsFixed(0)
        : '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scoreColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scoreColor.withOpacity(0.2),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tier,
                        style: TextStyle(
                          fontSize: 14,
                          color: scoreColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: scoreColor, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        score.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReputationStat(
                  Icons.assignment,
                  totalComplaints.toString(),
                  'Total',
                  Colors.blue,
                ),
                _buildReputationStat(
                  Icons.sentiment_satisfied,
                  '$positiveRate%',
                  'Positive',
                  Colors.green,
                ),
                _buildReputationStat(
                  Icons.access_time,
                  '${avgResponseTime.toStringAsFixed(0)}h',
                  'Avg Time',
                  Colors.orange,
                ),
              ],
            ),
            if (totalFeedbacks > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Feedback: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('😊 $positiveFeedbacks', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Text('😐 $neutralFeedbacks', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Text('😞 $negativeFeedbacks', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReputationStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final severityColor = _getSeverityColor(complaint.severity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor, width: 2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreenFromAdmin(
                complaintId: complaint.id,
                onAddProof: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedComplaintId = complaint.id;
                  });
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: severityColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: severityColor),
                        const SizedBox(width: 6),
                        Text(
                          complaint.severity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      complaint.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    complaint.status.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              if (complaint.duration != null && complaint.duration!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Duration: ${complaint.duration}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Trust & Reputation System - Admin View
              if (complaint.trustStatus != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTrustStatusColor(complaint.trustStatus!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getTrustStatusColor(complaint.trustStatus!),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTrustStatusIcon(complaint.trustStatus!),
                        size: 16,
                        color: _getTrustStatusColor(complaint.trustStatus!),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Trust: ${complaint.trustStatus!.internalLabel}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getTrustStatusColor(complaint.trustStatus!),
                        ),
                      ),
                      // Request Clarification for MEDIUM or LOW trust (any severity)
                      if ((complaint.trustStatus == TrustStatus.medium || 
                           complaint.trustStatus == TrustStatus.low) &&
                          complaint.clarificationRequest == null) ...[
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _requestClarification(complaint),
                          icon: const Icon(Icons.help_outline, size: 14),
                          label: const Text('Request Clarification', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ],
                      // Show clarification status
                      if (complaint.clarificationRequest != null) ...[
                        const Spacer(),
                        Text(
                          complaint.clarificationRequest!.isAnswered
                              ? 'Clarified ✓'
                              : 'Pending clarification',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                      // Request Validation for LOW trust
                      if (complaint.trustStatus == TrustStatus.low &&
                          complaint.validationRequest == null) ...[
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _requestValidation(complaint),
                          icon: const Icon(Icons.verified_user, size: 14),
                          label: const Text('Request Validation', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                          ),
                        ),
                      ],
                      if (complaint.validationRequest != null) ...[
                        const Spacer(),
                        Text(
                          complaint.validationRequest!.citizenConfirmed == null
                              ? 'Pending response'
                              : (complaint.validationRequest!.citizenConfirmed!
                                  ? 'Confirmed ✓'
                                  : 'Not confirmed'),
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: ${complaint.status.displayName}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(complaint.status),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedComplaintId = complaint.id;
                      });
                    },
                    icon: const Icon(Icons.add_a_photo, size: 16),
                    label: const Text('Add Proof'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted:
        return Colors.blue;
      case ComplaintStatus.acknowledged:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.purple;
      case ComplaintStatus.completed:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
    }
  }

  // Trust & Reputation System - Helper methods
  Color _getTrustStatusColor(TrustStatus status) {
    switch (status) {
      case TrustStatus.high:
        return Colors.green;
      case TrustStatus.medium:
        return Colors.orange;
      case TrustStatus.low:
        return Colors.blue;
    }
  }

  IconData _getTrustStatusIcon(TrustStatus status) {
    switch (status) {
      case TrustStatus.high:
        return Icons.verified;
      case TrustStatus.medium:
        return Icons.info;
      case TrustStatus.low:
        return Icons.search;
    }
  }

  void _requestClarification(Complaint complaint) {
    // Generate category-specific yes/no questions
    final questions = _generateClarificationQuestions(complaint);
    
    final request = ClarificationRequest(
      requestedBy: 'admin', // In real app, use actual admin ID
      requestedAt: DateTime.now(),
      questions: questions,
    );

    complaint.clarificationRequest = request;
    final provider = Provider.of<ComplaintProvider>(context, listen: false);
    provider.updateComplaint(complaint);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Clarification request sent to citizen'),
        backgroundColor: Colors.orange,
      ),
    );

    setState(() {});
  }

  List<ClarificationQuestion> _generateClarificationQuestions(Complaint complaint) {
    // Generate 3-4 yes/no questions based on category, severity, and trust status
    final List<ClarificationQuestion> questions = [];

    // Common questions
    questions.add(ClarificationQuestion(
      question: 'Is this issue currently affecting you or your area?',
    ));

    questions.add(ClarificationQuestion(
      question: 'Have you personally witnessed or experienced this problem?',
    ));

    // Severity-specific questions for Critical
    if (complaint.severity == 'Critical') {
      questions.add(ClarificationQuestion(
        question: 'Is there an immediate risk to life or property?',
      ));
      questions.add(ClarificationQuestion(
        question: 'Does this require emergency response within hours?',
      ));
    }
    // Severity-specific questions for Low
    else if (complaint.severity == 'Low') {
      questions.add(ClarificationQuestion(
        question: 'Is this issue causing any inconvenience to daily activities?',
      ));
      questions.add(ClarificationQuestion(
        question: 'Can this issue wait for scheduled maintenance?',
      ));
    }
    // Category-specific questions for Medium/High severity
    else if (complaint.category.contains('Road')) {
      questions.add(ClarificationQuestion(
        question: 'Is the road completely blocked or just partially damaged?',
      ));
      questions.add(ClarificationQuestion(
        question: 'Are vehicles able to pass through the affected area?',
      ));
    } else if (complaint.category.contains('Water')) {
      questions.add(ClarificationQuestion(
        question: 'Is the water supply completely stopped?',
      ));
      questions.add(ClarificationQuestion(
        question: 'Does this affect multiple households in your area?',
      ));
    } else if (complaint.category.contains('Electricity') || complaint.category.contains('Streetlight')) {
      questions.add(ClarificationQuestion(
        question: 'Is the entire street/area affected?',
      ));
      questions.add(ClarificationQuestion(
        question: 'Has this issue been reported to the electricity department before?',
      ));
    } else if (complaint.category.contains('Waste') || complaint.category.contains('Sanitation')) {
      questions.add(ClarificationQuestion(
        question: 'Has the waste been accumulating for more than 3 days?',
      ));
      questions.add(ClarificationQuestion(
        question: 'Is there a health hazard due to the waste?',
      ));
    } else {
      questions.add(ClarificationQuestion(
        question: 'Is immediate action required for this issue?',
      ));
      questions.add(ClarificationQuestion(
        question: 'Does this issue affect multiple people?',
      ));
    }

    return questions.take(4).toList(); // Return max 4 questions
  }

  void _requestValidation(Complaint complaint) {
    // Create validation request
    final request = ValidationRequest(
      requestedBy: 'admin', // In real app, use actual admin/official ID
      requestedAt: DateTime.now(),
      question: 'Please confirm if this complaint is accurate.',
    );

    // Update complaint
    complaint.validationRequest = request;
    final provider = Provider.of<ComplaintProvider>(context, listen: false);
    provider.updateComplaint(complaint);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Validation request sent to citizen'),
        backgroundColor: Colors.blue,
      ),
    );

    setState(() {});
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Clear All Complaints?'),
          content: const Text(
            'This will delete all complaints and start fresh. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _clearAllComplaints(context);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllComplaints(BuildContext context) async {
    try {
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      await provider.clearAllComplaints();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All complaints cleared! Ready for fresh start.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error clearing complaints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProofUploadScreen() {
    return ProofUploadWidget(
      complaintId: _selectedComplaintId,
      onComplete: () {
        setState(() {
          _selectedComplaintId = '';
        });
      },
    );
  }
}

class ProofUploadWidget extends StatefulWidget {
  final String complaintId;
  final VoidCallback onComplete;

  const ProofUploadWidget({
    super.key,
    required this.complaintId,
    required this.onComplete,
  });

  @override
  State<ProofUploadWidget> createState() => _ProofUploadWidgetState();
}

class _ProofUploadWidgetState extends State<ProofUploadWidget> {
  final _descriptionController = TextEditingController();
  final _officerNameController = TextEditingController();
  final _officerDesignationController = TextEditingController();
  File? _selectedMedia;
  ProofType _proofType = ProofType.photo;
  ComplaintStatus _newStatus = ComplaintStatus.inProgress;
  bool _isUploading = false;

  Widget _buildAutoGovInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        final complaint = provider.getComplaintById(widget.complaintId);

        if (complaint == null) {
          return const Center(child: Text('Complaint not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complaint Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Title: ${complaint.title}'),
                      Text('Location: ${complaint.location}'),
                      Text('Status: ${complaint.status.displayName}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Auto-Assigned by AutoGov Engine',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAutoGovInfoRow('Officer', complaint.autoGovOfficerName ?? 'Not assigned', Icons.person),
                    const SizedBox(height: 8),
                    _buildAutoGovInfoRow('Designation', complaint.autoGovOfficerDesignation ?? 'Officer', Icons.badge),
                    const SizedBox(height: 8),
                    _buildAutoGovInfoRow('Department', complaint.autoGovDepartment ?? 'General', Icons.business),
                    const SizedBox(height: 8),
                    _buildAutoGovInfoRow('Ward', complaint.autoGovWard ?? 'N/A', Icons.location_city),
                  ],
                ),
              ),
          const SizedBox(height: 20),
          const Text(
            '📸 Upload Proof of Work',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description of Work Completed',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ComplaintStatus>(
            initialValue: _newStatus,
            decoration: InputDecoration(
              labelText: 'Update Status',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ComplaintStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text('${status.emoji} ${status.displayName}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _newStatus = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          if (_selectedMedia != null)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _proofType == ProofType.photo
                    ? Image.file(_selectedMedia!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.video_library, size: 80)),
              ),
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: const Center(
                child: Text('No media selected'),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMedia(ProofType.photo, useCamera: true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMedia(ProofType.photo, useCamera: false),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('From Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMedia(ProofType.video, useCamera: true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMedia(ProofType.video, useCamera: false),
                  icon: const Icon(Icons.video_library),
                  label: const Text('From Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadProof,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Uploading...' : 'Submit Proof'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onComplete,
            child: const Text('Cancel'),
          ),
        ],
      ),
        );
      },
    );
  }

  Future<void> _pickMedia(ProofType type, {required bool useCamera}) async {
    final picker = ImagePicker();
    final XFile? file;

    if (type == ProofType.photo) {
      if (useCamera) {
        file = await picker.pickImage(source: ImageSource.camera);
      } else {
        file = await picker.pickImage(source: ImageSource.gallery);
      }
    } else {
      if (useCamera) {
        file = await picker.pickVideo(source: ImageSource.camera);
      } else {
        file = await picker.pickVideo(source: ImageSource.gallery);
      }
    }

    if (file != null) {
      setState(() {
        _selectedMedia = File(file!.path);
        _proofType = type;
      });
    }
  }

  Future<void> _uploadProof() async {
    if (_selectedMedia == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add description and select media')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Get current location
    final position = await LocationService.getCurrentLocation();
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location. Please enable GPS.')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    final locationName = await LocationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final provider = Provider.of<ComplaintProvider>(context, listen: false);
    final complaint = provider.getComplaintById(widget.complaintId);
    
    // Create proof entry with AutoGov assigned officer
    final proof = ProofChainEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      officerName: complaint?.autoGovOfficerName ?? 'Officer',
      officerDesignation: complaint?.autoGovOfficerDesignation ?? 'Department Officer',
      description: _descriptionController.text,
      proofType: _proofType,
      mediaPath: _selectedMedia!.path,
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
      statusUpdate: _newStatus,
    );

    await provider.addProofToComplaint(widget.complaintId, proof);

    setState(() {
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Proof uploaded successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    widget.onComplete();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _officerNameController.dispose();
    _officerDesignationController.dispose();
    super.dispose();
  }
}

/// Wrapper to show complaint detail screen with "Add Proof" button in admin context
class ComplaintDetailScreenFromAdmin extends StatelessWidget {
  final String complaintId;
  final VoidCallback onAddProof;

  const ComplaintDetailScreenFromAdmin({
    super.key,
    required this.complaintId,
    required this.onAddProof,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ComplaintDetailScreen(complaintId: complaintId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddProof,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Proof'),
      ),
    );
  }
}
