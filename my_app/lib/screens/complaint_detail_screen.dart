import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../models/trust_score.dart';
import '../models/citizen_feedback.dart';
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

          return _buildComplaintContent(context, complaint);
        },
      ),
    );
  }

  Widget _buildComplaintContent(BuildContext context, Complaint complaint) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(complaint),
          _buildAutoGovInfo(complaint),
          _buildTrustStatusBanner(context, complaint),
          _buildClarificationSection(context, complaint),
          _buildComplaintInfo(complaint),
          if (complaint.imagePath != null) _buildComplaintPhoto(complaint, context),
          if (complaint.proofChain.isNotEmpty) _buildProofChain(complaint, context),
          _buildEmojiFeedbackSection(context, complaint),
        ],
      ),
    );
  }

  /// Trust status banner - shown only when official assigned
  Widget _buildTrustStatusBanner(BuildContext context, Complaint complaint) {
    // Only show if official is assigned AND trust status exists
    if (complaint.assignedOfficerId == null || complaint.trustStatus == null) {
      return const SizedBox.shrink();
    }

    Color bannerColor;
    IconData bannerIcon;
    
    switch (complaint.trustStatus!) {
      case TrustStatus.high:
        bannerColor = Colors.green;
        bannerIcon = Icons.verified;
        break;
      case TrustStatus.medium:
        bannerColor = Colors.orange;
        bannerIcon = Icons.info;
        break;
      case TrustStatus.low:
        bannerColor = Colors.blue;
        bannerIcon = Icons.search;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              complaint.trustStatus!.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: bannerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clarification section - shown when admin requests clarification
  Widget _buildClarificationSection(BuildContext context, Complaint complaint) {
    if (complaint.clarificationRequest == null) {
      return const SizedBox.shrink();
    }

    final request = complaint.clarificationRequest!;
    final isAnswered = request.isAnswered;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAnswered 
                      ? 'Thank you for providing clarification!' 
                      : 'Additional Clarification Needed',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isAnswered) ...[
            const Text(
              'Please answer the following questions to help us better understand your complaint:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
          ],
          ...request.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${question.question}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (question.answer != null) ...[
                    // Show answer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: question.answer! ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: question.answer! ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Text(
                        question.answer! ? 'Yes ✓' : 'No ✗',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: question.answer! ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Show Yes/No buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _answerClarification(context, complaint, index, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Yes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _answerClarification(context, complaint, index, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('No'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _answerClarification(BuildContext context, Complaint complaint, int questionIndex, bool answer) {
    complaint.clarificationRequest!.questions[questionIndex].answer = answer;
    
    // Check if all questions are answered
    if (complaint.clarificationRequest!.isAnswered) {
      complaint.clarificationRequest!.respondedAt = DateTime.now();
    }

    final provider = Provider.of<ComplaintProvider>(context, listen: false);
    provider.updateComplaint(complaint);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(complaint.clarificationRequest!.isAnswered
            ? '✅ All questions answered! Thank you.'
            : '✅ Answer recorded'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Emoji feedback section - shown after resolution
  Widget _buildEmojiFeedbackSection(BuildContext context, Complaint complaint) {
    // Only show for completed complaints from citizen view
    if (complaint.status != ComplaintStatus.completed) {
      return const SizedBox.shrink();
    }

    // If feedback already given, show it
    if (complaint.citizenFeedback != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Row(
          children: [
            Text(
              complaint.citizenFeedback!.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Feedback',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    complaint.citizenFeedback!.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // If no feedback yet, show feedback prompt
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.feedback, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How satisfied are you with the resolution?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeedbackButton(
                context,
                complaint,
                CitizenFeedback.positive,
              ),
              _buildFeedbackButton(
                context,
                complaint,
                CitizenFeedback.neutral,
              ),
              _buildFeedbackButton(
                context,
                complaint,
                CitizenFeedback.negative,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(
    BuildContext context,
    Complaint complaint,
    CitizenFeedback feedback,
  ) {
    return InkWell(
      onTap: () {
        _submitFeedback(context, complaint, feedback);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              feedback.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              feedback.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback(
    BuildContext context,
    Complaint complaint,
    CitizenFeedback feedback,
  ) {
    final provider = Provider.of<ComplaintProvider>(context, listen: false);
    
    // Update complaint with feedback
    complaint.citizenFeedback = feedback;
    provider.updateComplaint(complaint);

    // Update official reputation
    if (complaint.assignedOfficerId != null) {
      // Import and use ReputationService here
      // ReputationService.updateAfterResolution(...);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(feedback.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Thank you for your feedback!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
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

  Widget _buildAutoGovInfo(Complaint complaint) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AutoGov Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Intelligent Routing Active',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.black87),
                    SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 12),
          _buildAutoGovRow(
            Icons.business,
            'Department',
            complaint.autoGovDepartment ?? 'Not assigned',
            Colors.white,
          ),
          const SizedBox(height: 10),
          _buildAutoGovRow(
            Icons.priority_high,
            'Priority',
            complaint.autoGovPriority ?? 'Not set',
            Colors.orangeAccent,
          ),
          const SizedBox(height: 10),
          _buildAutoGovRow(
            Icons.person_outline,
            'Assigned Officer',
            complaint.autoGovOfficerName ?? 'Not assigned',
            Colors.cyanAccent,
          ),
          const SizedBox(height: 10),
          _buildAutoGovRow(
            Icons.location_city,
            'Ward/City',
            '${complaint.autoGovWard ?? "N/A"}, ${complaint.autoGovCity ?? "N/A"}',
            Colors.white70,
          ),
          const SizedBox(height: 10),
          _buildAutoGovRow(
            Icons.timer_outlined,
            'SLA Deadline',
            complaint.autoGovSlaDeadline != null 
                ? _formatSlaDeadline(complaint.autoGovSlaDeadline!)
                : 'Not set',
            _getSlaColor(complaint.autoGovSlaDeadline),
          ),
        ],
      ),
    );
  }

  String _formatSlaDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      final overdue = now.difference(deadline);
      return 'Overdue by ${overdue.inHours}h ${overdue.inMinutes % 60}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h remaining';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m remaining';
    }
  }

  Color _getSlaColor(DateTime? deadline) {
    if (deadline == null) return Colors.white70;
    
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) return Colors.redAccent;
    if (difference.inHours <= 24) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  Widget _buildAutoGovRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
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
