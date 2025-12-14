import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, child) {
          final complaint = provider.getComplaintById(complaintId);

          if (complaint == null) {
            return const Center(child: Text('Complaint not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(complaint),
                _buildComplaintInfo(complaint),
                if (complaint.imagePath != null) _buildComplaintPhoto(complaint, context),
                if (complaint.proofChain.isNotEmpty) _buildProofChain(complaint, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Complaint complaint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(complaint.status).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _getStatusColor(complaint.status),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                complaint.status.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.status.displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(complaint.status),
                      ),
                    ),
                    Text(
                      'ID: ${complaint.id}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintInfo(Complaint complaint) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complaint Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.title, 'Title', complaint.title),
          _buildInfoRow(Icons.category, 'Category', complaint.category),
          _buildSeverityRow(complaint.severity),
          if (complaint.duration != null && complaint.duration!.isNotEmpty)
            _buildInfoRow(Icons.timer, 'Duration', complaint.duration!),
          _buildInfoRow(Icons.description, 'Description', complaint.description),
          _buildInfoRow(Icons.person, 'Citizen', complaint.citizenName),
          _buildInfoRow(Icons.phone, 'Phone', complaint.citizenPhone),
          _buildInfoRow(Icons.location_on, 'Location', complaint.location),
          _buildInfoRow(
            Icons.access_time,
            'Submitted',
            DateFormat('dd MMM yyyy, hh:mm a').format(complaint.submittedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityRow(String severity) {
    Color severityColor;
    IconData severityIcon;
    
    switch (severity.toLowerCase()) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.warning;
        break;
      case 'high':
        severityColor = Colors.orange;
        severityIcon = Icons.priority_high;
        break;
      case 'medium':
        severityColor = Colors.yellow[700]!;
        severityIcon = Icons.info;
        break;
      case 'low':
        severityColor = Colors.green;
        severityIcon = Icons.check_circle;
        break;
      default:
        severityColor = Colors.grey;
        severityIcon = Icons.help;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(severityIcon, size: 20, color: severityColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Severity',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        severity,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintPhoto(Complaint complaint, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.photo_camera, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '📷 Complaint Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Photo'),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      body: Center(
                        child: PhotoView(
                          imageProvider: FileImage(File(complaint.imagePath!)),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(complaint.imagePath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              'Tap to view full size',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofChain(Complaint complaint, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  '🔗 ProofChain',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${complaint.proofChain.length} Proof${complaint.proofChain.length > 1 ? "s" : ""}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: complaint.proofChain.length,
            itemBuilder: (context, index) {
              return _buildProofCard(complaint.proofChain[index], context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard(ProofChainEntry proof, BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  proof.statusUpdate.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proof.statusUpdate.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(proof.statusUpdate),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(proof.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock, color: Colors.grey, size: 20),
              ],
            ),
            const Divider(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _PhotoViewScreen(imagePath: proof.mediaPath),
                  ),
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: proof.proofType == ProofType.photo
                      ? Image.file(
                          File(proof.mediaPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(color: Colors.black),
                            const Icon(Icons.play_circle_outline, size: 60, color: Colors.white),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              proof.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildProofInfoRow(Icons.person, 'Officer', proof.officerName),
            _buildProofInfoRow(Icons.badge, 'Designation', proof.officerDesignation),
            _buildProofInfoRow(Icons.location_on, 'Location', proof.locationName),
            _buildProofInfoRow(Icons.gps_fixed, 'GPS', '${proof.latitude.toStringAsFixed(6)}, ${proof.longitude.toStringAsFixed(6)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProofInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
}

class _PhotoViewScreen extends StatelessWidget {
  final String imagePath;

  const _PhotoViewScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('View Proof'),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}
