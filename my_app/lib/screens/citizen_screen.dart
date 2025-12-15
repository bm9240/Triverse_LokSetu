import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import 'complaint_detail_screen.dart';
import 'grievbot_screen.dart';
import 'easyform_screen.dart';

class CitizenScreen extends StatefulWidget {
  const CitizenScreen({super.key});

  @override
  State<CitizenScreen> createState() => _CitizenScreenState();
}

class _CitizenScreenState extends State<CitizenScreen> {
  String _phoneNumber = '';
  bool _showComplaints = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Citizen Portal'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _showComplaints ? _buildComplaintsList() : _buildPhoneInput(),
      floatingActionButton: _showComplaints
          ? FloatingActionButton.extended(
              onPressed: () {
                _showComplaintOptions(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('New Complaint'),
              backgroundColor: Colors.deepPurple,
            )
          : null,
    );
  }

  Widget _buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.phone_android,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 30),
          const Text(
            'Enter Your Phone Number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'To view your complaints and track their status',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '10-digit mobile number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (value) {
              setState(() {
                _phoneNumber = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _phoneNumber.length == 10
                ? () {
                    setState(() {
                      _showComplaints = true;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'View My Complaints',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        final complaints = provider.getComplaintsByPhone(_phoneNumber);
        
        // Separate pending and completed complaints
        final pendingComplaints = complaints
            .where((c) => c.status != ComplaintStatus.completed)
            .toList();
        final completedComplaints = complaints
            .where((c) => c.status == ComplaintStatus.completed)
            .toList();

        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Complaints Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Phone: $_phoneNumber',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose an option:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                // GrievBot AI Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GrievBotScreen(
                          citizenPhone: _phoneNumber,
                          citizenName: 'Citizen',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.smart_toy, size: 28),
                  label: const Text(
                    '🤖 AI Complaint Assistant (Easy)',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    minimumSize: const Size(250, 56),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logged in as:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _phoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showComplaints = false;
                        _phoneNumber = '';
                      });
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingComplaints.length + 
                    (completedComplaints.isNotEmpty ? 1 + completedComplaints.length : 0),
                itemBuilder: (context, index) {
                  // Show completed section header
                  if (index == pendingComplaints.length && completedComplaints.isNotEmpty) {
                    return _buildCompletedSectionHeader();
                  }
                  
                  // Show completed complaints after pending ones
                  if (index > pendingComplaints.length) {
                    final completedIndex = index - pendingComplaints.length - 1;
                    return _buildComplaintCard(completedComplaints[completedIndex]);
                  }
                  
                  // Show pending complaints
                  return _buildComplaintCard(pendingComplaints[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(
                complaintId: complaint.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Escalation Banner
              if (complaint.escalatedToHead)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚡ ESCALATED TO DEPARTMENT HEAD',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              complaint.escalationReason ?? 'Your matter has been escalated for priority action',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          complaint.status.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          complaint.status.displayName,
                          style: TextStyle(
                            color: _getStatusColor(complaint.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (complaint.proofChain.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: complaint.status == ComplaintStatus.completed
                            ? Colors.green.shade600
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green,
                          width: complaint.status == ComplaintStatus.completed ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: complaint.status == ComplaintStatus.completed ? 18 : 14,
                            color: complaint.status == ComplaintStatus.completed
                                ? Colors.white
                                : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${complaint.proofChain.length} Proof${complaint.proofChain.length > 1 ? "s" : ""}',
                            style: TextStyle(
                              fontSize: complaint.status == ComplaintStatus.completed ? 12 : 11,
                              color: complaint.status == ComplaintStatus.completed
                                  ? Colors.white
                                  : Colors.green,
                              fontWeight: complaint.status == ComplaintStatus.completed
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
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
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(complaint.submittedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedSectionHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.teal.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '✨ RESOLVED COMPLAINTS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'These matters have been completed with proof from the officer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showComplaintOptions(BuildContext context) {
    // Directly open GrievBot (AI Assistant only)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GrievBotScreen(
          citizenPhone: _phoneNumber,
          citizenName: 'Citizen',
        ),
      ),
    );
  }
}
