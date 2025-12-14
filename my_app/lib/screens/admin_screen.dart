import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import '../services/location_service.dart';
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

  final List<String> _departments = [
    'Public Works Department',
    'Water Supply & Sanitation',
    'Electricity Board',
    'Waste Management',
    'Parks & Recreation',
    'Traffic Police',
    'Health Department',
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
      ),
      drawer: _buildDrawer(),
      body: _selectedComplaintId.isEmpty
          ? (_selectedView == 'home' 
              ? _buildComplaintsList()
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
        ],
      ),
    );
  }

  Widget _buildDepartmentList() {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _departments.length,
          itemBuilder: (context, index) {
            final dept = _departments[index];
            final deptComplaints = provider.complaints
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
                subtitle: Text('$deptComplaints pending complaints'),
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
    if (dept.contains('Parks')) return Icons.park;
    if (dept.contains('Traffic')) return Icons.traffic;
    if (dept.contains('Health')) return Icons.local_hospital;
    if (dept.contains('Education')) return Icons.school;
    if (dept.contains('Revenue')) return Icons.account_balance;
    return Icons.business;
  }

  Widget _buildDepartmentView() {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        final deptComplaints = provider.complaints
            .where((c) => c.autoGovDepartment == _selectedDepartment && c.status != ComplaintStatus.completed)
            .toList();

        final performers = _calculatePerformers(provider.complaints, _selectedDepartment!);

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
                      child: Text(
                        _selectedDepartment!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
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
      });
    });

    performers.sort((a, b) {
      final rateDiff = b['resolutionRate'].compareTo(a['resolutionRate']);
      if (rateDiff != 0) return rateDiff;
      if (a['avgHoursValue'] == 0) return 1;
      if (b['avgHoursValue'] == 0) return -1;
      return a['avgHoursValue'].compareTo(b['avgHoursValue']);
    });

    final top = performers.take(3).toList();
    final worst = performers.length > 3 
        ? performers.reversed.take(3).toList().cast<Map<String, dynamic>>() 
        : <Map<String, dynamic>>[];

    return {
      'top': top,
      'worst': worst,
    };
  }

  Widget _buildComplaintsList() {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        final pendingComplaints = provider.complaints
            .where((c) => c.status != ComplaintStatus.completed)
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pendingComplaints.length,
                itemBuilder: (context, index) {
                  final complaint = pendingComplaints[index];
                  return _buildComplaintCard(complaint);
                },
              ),
            ),
          ],
        );
      },
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
