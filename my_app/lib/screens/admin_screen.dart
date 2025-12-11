import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import '../services/location_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedComplaintId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Admin/Officer Portal'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _selectedComplaintId.isEmpty
          ? _buildComplaintsList()
          : _buildProofUploadScreen(),
    );
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingComplaints.length,
          itemBuilder: (context, index) {
            final complaint = pendingComplaints[index];
            return _buildComplaintCard(complaint);
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(complaint.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(complaint.description, maxLines: 2),
            const SizedBox(height: 4),
            Text(
              'Status: ${complaint.status.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedComplaintId = complaint.id;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Proof'),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintProvider>(context, listen: false);
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
          const Text(
            '📸 Upload Proof of Work',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _officerNameController,
            decoration: InputDecoration(
              labelText: 'Officer Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _officerDesignationController,
            decoration: InputDecoration(
              labelText: 'Designation',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
    if (_selectedMedia == null ||
        _officerNameController.text.isEmpty ||
        _officerDesignationController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select media')),
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

    // Create proof entry
    final proof = ProofChainEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      officerName: _officerNameController.text,
      officerDesignation: _officerDesignationController.text,
      description: _descriptionController.text,
      proofType: _proofType,
      mediaPath: _selectedMedia!.path,
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
      statusUpdate: _newStatus,
    );

    final provider = Provider.of<ComplaintProvider>(context, listen: false);
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
