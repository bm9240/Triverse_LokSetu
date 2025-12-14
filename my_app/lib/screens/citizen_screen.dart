import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import 'complaint_detail_screen.dart';
import 'submit_complaint_screen.dart';
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
                          citizenName: 'Citizen', // Can be updated with actual name
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.smart_toy, size: 28),
                  label: const Text(
                    '🤖 AI Complaint Assistant',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    minimumSize: const Size(250, 56),
                  ),
                ),
                const SizedBox(height: 12),
                // Regular Form Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitComplaintScreen(
                          citizenPhone: _phoneNumber,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Traditional Form'),
                  style: OutlinedButton.styleFrom(
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
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${complaint.proofChain.length} Proof${complaint.proofChain.length > 1 ? "s" : ""}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose how to file complaint',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // GrievBot AI Option
            ListTile(
              leading: const Icon(Icons.smart_toy, color: Colors.deepPurple, size: 36),
              title: const Text(
                '🤖 AI Assistant (GrievBot)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Easy - Just describe or take a photo'),
              onTap: () {
                Navigator.pop(context);
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
            ),
            const Divider(),
            // Traditional Form Option
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.blue, size: 36),
              title: const Text(
                'Traditional Form',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Standard complaint form'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmitComplaintScreen(
                      citizenPhone: _phoneNumber,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
