import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/grievbot_service.dart';
import '../services/location_service.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';

/// GrievBot Screen - AI-powered complaint intake
/// Minimal UI, no forms, designed for low literacy users
/// Accepts voice, image, and text inputs
class GrievBotScreen extends StatefulWidget {
  final String citizenPhone;
  final String citizenName;

  const GrievBotScreen({
    super.key,
    required this.citizenPhone,
    required this.citizenName,
  });

  @override
  State<GrievBotScreen> createState() => _GrievBotScreenState();
}

class _GrievBotScreenState extends State<GrievBotScreen> {
  // Services
  final _grievbotService = GrievBotService();
  final _imagePicker = ImagePicker();
  late stt.SpeechToText _speech;  // STT instance for on-device speech recognition
  
  // Input aggregation
  String? _imageText;
  final _textController = TextEditingController();
  final _voiceTextController = TextEditingController();
  XFile? _capturedImage;
  
  // State
  bool _isProcessing = false;
  bool _isListening = false;  // Track if STT is actively listening
  String? _currentLocation;
  String _selectedLanguage = 'hindi'; // Default: hindi, english, hinglish

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();  // Initialize STT instance
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _textController.dispose();
    _voiceTextController.dispose();
    _speech.stop();  // Stop listening when widget is disposed
    super.dispose();
  }

  /// Toggle Speech-to-Text: Start or Stop listening
  /// Converts spoken words to text on device and displays in the complaint field
  Future<void> _toggleSpeechToText() async {
    if (_isListening) {
      // Stop listening
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    // Start listening
    print('GrievBot STT: Initializing speech recognition...');
    bool available = await _speech.initialize(
      onError: (error) {
        print('GrievBot STT: Error - ${error.errorMsg}');
        setState(() {
          _isListening = false;
        });
        
        // Provide user-friendly error messages
        String errorMessage = error.errorMsg ?? 'Unknown error';
        if (errorMessage.contains('timeout')) {
          errorMessage = _selectedLanguage == 'hindi' 
              ? 'कोई आवाज़ नहीं सुनाई दी। कृपया फिर से बोलें।'
              : (_selectedLanguage == 'hinglish' 
                  ? 'Koi awaaz nahi sunayi di. Please dobara bolo.'
                  : 'No speech detected. Please try speaking again.');
        }
        _showError(errorMessage);
      },
      onStatus: (status) {
        print('GrievBot STT: Status changed to $status');
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    print('GrievBot STT: Available = $available');
    if (!available) {
      _showError(_getText()['sttNotAvailable'] ?? 'Speech recognition not available');
      return;
    }

    // Determine locale based on selected language
    String localeId = 'hi_IN';  // Hindi by default
    if (_selectedLanguage == 'english') {
      localeId = 'en_IN';
    } else if (_selectedLanguage == 'hinglish') {
      localeId = 'en_IN';  // Use English for Hinglish
    }

    print('GrievBot STT: Starting to listen with locale $localeId');
    setState(() {
      _isListening = true;
    });

    // Start listening and update text field with recognized speech
    try {
      await _speech.listen(
        onResult: (result) {
          print('GrievBot STT: Recognized - ${result.recognizedWords}');
          setState(() {
            _voiceTextController.text = result.recognizedWords;
          });
        },
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,  // Stop after user finishes speaking
        cancelOnError: true,
        partialResults: true,  // Show results as user speaks
        listenFor: const Duration(seconds: 30),  // Listen for up to 30 seconds
        pauseFor: const Duration(seconds: 5),  // Pause detection after 5 seconds of silence
      );
    } catch (e) {
      print('GrievBot STT: Listen error - $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final locationName = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _currentLocation = locationName;
        });
      }
    } catch (e) {
      // Location optional, continue without it
    }
  }



  /// Image Input Handler + OCR
  Future<void> _captureImage() async {
    try {
      // Let user choose camera or gallery
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _capturedImage = image;
        _isProcessing = true;
      });

      // Extract text using ML Kit OCR
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();

      setState(() {
        _imageText = recognizedText.text;
        _isProcessing = false;
      });

      if (_imageText != null && _imageText!.isNotEmpty) {
        _showSuccess(_getText()['textExtracted']!);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to process image: $e');
    }
  }

  /// Show dialog to choose image source
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) {
        final text = _getText();
        return AlertDialog(
          title: Text(text['imageSourceTitle']!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, size: 32),
                title: Text(text['camera']!, style: const TextStyle(fontSize: 18)),
                subtitle: Text(text['cameraSubtitle']!),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, size: 32),
                title: Text(text['gallery']!, style: const TextStyle(fontSize: 18)),
                subtitle: Text(text['gallerySubtitle']!),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Submit Complaint - Process with GrievBot and forward to backend
  Future<void> _submitComplaint() async {
    // Validate: At least one input must be provided
    if ((_voiceTextController.text.isEmpty) &&
        (_imageText == null || _imageText!.isEmpty) &&
        _textController.text.isEmpty) {
      final text = _getText();
      _showError(text['validation']!);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Process with GrievBot (Gemini AI)
      print('GrievBot: Starting to process complaint...');
      final structuredComplaint = await _grievbotService.processComplaint(
        voiceText: _voiceTextController.text.isNotEmpty ? _voiceTextController.text : null,
        imageText: _imageText,
        additionalText: _textController.text.isNotEmpty ? _textController.text : null,
        location: _currentLocation,
      );
      print('GrievBot: Received structured complaint: $structuredComplaint');

      // Step 2: Map to existing Complaint model
      print('GrievBot: Getting location...');
      final position = await LocationService.getCurrentLocation();
      
      // Use default coordinates if location not available
      final latitude = position?.latitude ?? 0.0;
      final longitude = position?.longitude ?? 0.0;
      print('GrievBot: Location: lat=$latitude, lon=$longitude');
      
      // Validate required fields from Groq response
      if (structuredComplaint['title'] == null ||
          structuredComplaint['issueType'] == null || 
          structuredComplaint['officialComplaintText'] == null ||
          structuredComplaint['severity'] == null ||
          structuredComplaint['duration'] == null) {
        throw Exception('Invalid response from AI: Missing required fields');
      }
      
      final complaint = Complaint(
        id: const Uuid().v4(),
        title: structuredComplaint['title'] ?? 'Unknown Issue',
        description: structuredComplaint['officialComplaintText'] ?? 'No description provided',
        category: _grievbotService.mapToExistingCategory(
          structuredComplaint['issueType'] ?? 'Other',
        ),
        severity: structuredComplaint['severity'] ?? 'Medium',
        duration: structuredComplaint['duration'],
        location: structuredComplaint['location'] ?? _currentLocation ?? 'Unknown location',
        latitude: latitude,
        longitude: longitude,
        submittedAt: DateTime.now(),
        citizenName: widget.citizenName,
        citizenPhone: widget.citizenPhone,
        imagePath: _capturedImage?.path,
      );
      print('GrievBot: Created complaint object with ID: ${complaint.id}');

      // Step 3: Submit to existing ComplaintProvider (integrates with AutoGov Engine)
      print('GrievBot: Submitting to provider...');
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      await provider.addComplaint(complaint);
      print('GrievBot: Complaint added successfully');

      // Step 4: Show success and navigate back
      if (!mounted) return;
      
      await _showSuccessDialog(
        complaintId: complaint.id,
        category: structuredComplaint['issueType'] ?? 'Unknown',
        severity: structuredComplaint['severity'] ?? 'Unknown',
        duration: structuredComplaint['duration'] ?? 'Unknown',
      );

      if (!mounted) return;
      Navigator.pop(context);
      
    } catch (e, stackTrace) {
      print('GrievBot Error: $e');
      print('Stack trace: $stackTrace');
      
      // User-friendly error message based on error type
      String errorMessage;
      if (e.toString().contains('API key') || e.toString().contains('Invalid API') || e.toString().contains('YOUR_GROQ_API_KEY_HERE')) {
        errorMessage = '🔑 Configuration error.\n\nThe Groq API key is not configured. Please add your API key in grievbot_service.dart.\n\nGet a free key at: https://console.groq.com/keys';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = '🔑 Authentication error.\n\nThe Groq API key is invalid. Please check your API key configuration.';
      } else if (e.toString().contains('429')) {
        errorMessage = '⏱️ Rate limit reached.\n\nToo many requests. Please wait a moment and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        errorMessage = '🌐 Network error.\n\nPlease check your internet connection and try again.';
      } else if (e.toString().contains('Groq') || e.toString().contains('Empty response')) {
        errorMessage = '🤖 AI service error.\n\nThe Groq AI service is temporarily unavailable. Please try again in a moment.';
      } else if (e.toString().contains('Invalid response') || e.toString().contains('Missing required fields')) {
        errorMessage = '⚠️ Processing error.\n\nCouldn\'t understand the complaint properly. Please try describing it differently.';
      } else {
        // Show more of the error for debugging
        final errorStr = e.toString();
        final errorPreview = errorStr.length > 200 ? '${errorStr.substring(0, 200)}...' : errorStr;
        errorMessage = '❌ Failed to submit complaint.\n\nError: $errorPreview';
      }
      _showError(errorMessage);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Show success dialog with complaint details
  Future<void> _showSuccessDialog({
    required String complaintId,
    required String category,
    required String severity,
    required String duration,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _getText()['successTitle']!,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getText()['complaintId']}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                complaintId,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text('${_getText()['category']}: $category'),
              const SizedBox(height: 4),
              Text('${_getText()['severity']}: $severity'),
              const SizedBox(height: 4),
              Text('${_getText()['duration']}: $duration'),
              const SizedBox(height: 12),
              Text(
                _getText()['successMessage']!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Language-specific text content
  Map<String, String> _getText() {
    switch (_selectedLanguage) {
      case 'hindi':
        return {
          'title': '🤖 GrievBot - शिकायत सहायक',
          'heading': 'अपनी समस्या बताएं',
          'subheading': 'अपनी शिकायत लिखें या फोटो लें',
          'describeLabel': 'अपनी शिकायत यहां लिखें:',
          'describeHint': 'क्या हुआ, बताएं...\n\nउदाहरण:\n• "मेरे घर के पास रोड टूट गई है, 2 दिन से"\n• "गली में कूडा नहीं उठाया जा रहा"\n• "स्ट्रीटलाइट खराब है"',
          'voiceButton': '🎤 बोलकर बताएं',
          'voiceButtonStop': '🛑 बंद करें',
          'photoButton': '📷 तस्वीर खींचे',
          'sttNotAvailable': 'आपके फोन में बोलकर लिखना उपलब्ध नहीं है',
          'additionalLabel': 'कब से यह समस्या है?',
          'additionalHint': 'जैसे: "2 दिन से", "1 हफ्ते से", "आज से", "कई महीनों से"',
          'submitButton': '✅ शिकायत दर्ज करें',
          'processing': 'आपकी शिकायत दर्ज की जा रही है...',
          'validation': 'कृपया अपनी समस्या बताएं या फोटो जोड़ें',
          'successTitle': 'शिकायत दर्ज हो गई',
          'complaintId': 'शिकायत नंबर',
          'category': 'श्रेणी',
          'severity': 'गंभीरता',
          'duration': 'अवधि',
          'successMessage': 'आपकी शिकायत दर्ज हो गई है। जल्द ही कार्यवाही की जाएगी।',
          'imageSourceTitle': 'फोटो कहां से लेना है?',
          'camera': 'कैमरा',
          'cameraSubtitle': 'अभी फोटो खींचें',
          'gallery': 'गैलरी',
          'gallerySubtitle': 'पुरानी फोटो चुनें',
          'textExtracted': 'फोटो से टेक्स्ट निकाला गया',
        };
      case 'english':
        return {
          'title': '🤖 GrievBot - Complaint Assistant',
          'heading': 'Tell us about your problem',
          'subheading': 'Describe your complaint or add a photo',
          'describeLabel': 'Describe your complaint:',
          'describeHint': 'Tell us what happened...\n\nExamples:\n• "Road is broken near my house, for 2 days"\n• "Garbage not collected in my street"\n• "Streetlight not working since yesterday"',
          'voiceButton': '🎤 Speak to Tell',
          'voiceButtonStop': '🛑 Stop',
          'photoButton': '📷 Take Photo',
          'sttNotAvailable': 'Speech recognition not available on your phone',
          'additionalLabel': 'Since when is this issue bothering you?',
          'additionalHint': 'e.g., "2 days", "1 week", "today", "for months"',
          'submitButton': '✅ Submit Complaint',
          'processing': 'Processing your complaint...',
          'validation': 'Please describe your problem or add a photo',
          'successTitle': 'Complaint Submitted',
          'complaintId': 'Complaint ID',
          'category': 'Category',
          'severity': 'Severity',
          'duration': 'Duration',
          'successMessage': 'Your complaint has been registered and will be processed soon.',
          'imageSourceTitle': 'Choose Image Source',
          'camera': 'Camera',
          'cameraSubtitle': 'Take photo now',
          'gallery': 'Gallery',
          'gallerySubtitle': 'Choose existing photo',
          'textExtracted': 'Text extracted from image',
        };
      case 'hinglish':
        return {
          'title': '🤖 GrievBot - Complaint Helper',
          'heading': 'Apni problem batao',
          'subheading': 'Apni shikayat likho ya photo lo',
          'describeLabel': 'Apni shikayat yahan likho:',
          'describeHint': 'Kya hua batao...\n\nExamples:\n• "Mere ghar ke paas road toot gayi hai, 2 din se"\n• "Gali mein kuda nahi uthaya ja raha"\n• "Streetlight kharab hai kal se"',
          'voiceButton': '🎤 Bolkar Batao',
          'voiceButtonStop': '🛑 Band Karo',
          'photoButton': '📷 Photo Lo',
          'sttNotAvailable': 'Aapke phone mein bolkar likhna available nahi hai',
          'additionalLabel': 'Kab se yeh problem hai?',
          'additionalHint': 'Jaise: "2 din se", "1 week se", "aaj se", "kai mahino se"',
          'submitButton': '✅ Shikayat Submit Karo',
          'processing': 'Aapki shikayat register ho rahi hai...',
          'validation': 'Apni problem batao ya photo add karo',
          'successTitle': 'Shikayat Register Ho Gayi',
          'complaintId': 'Complaint Number',
          'category': 'Category',
          'severity': 'Severity',
          'duration': 'Duration',
          'successMessage': 'Aapki shikayat register ho gayi hai. Jaldi action liya jayega.',
          'imageSourceTitle': 'Photo kahan se lena hai?',
          'camera': 'Camera',
          'cameraSubtitle': 'Abhi photo lo',
          'gallery': 'Gallery',
          'gallerySubtitle': 'Purani photo select karo',
          'textExtracted': 'Photo se text nikala gaya',
        };
      default:
        return _getText(); // Fallback to hindi
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _getText();
    return Scaffold(
      appBar: AppBar(
        title: Text(text['title']!),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 6),
                  const SizedBox(height: 20),
                  Text(text['processing']!,
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language Selector
                  _buildLanguageSelector(),
                  const SizedBox(height: 20),
                  
                  // Header
                  Text(
                    text['heading']!,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text['subheading']!,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Complaint Description Input
                  Text(
                    text['describeLabel']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _voiceTextController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: text['describeHint']!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.message),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Speech-to-Text Button (on-device speech recognition)
                  _buildBigButton(
                    icon: _isListening ? Icons.stop : Icons.mic,
                    label: _isListening ? text['voiceButtonStop']! : text['voiceButton']!,
                    color: _isListening ? Colors.red : Colors.blue,
                    onPressed: _toggleSpeechToText,
                  ),

                  const SizedBox(height: 20),

                  // Camera Input Button
                  _buildBigButton(
                    icon: Icons.camera_alt,
                    label: text['photoButton']!,
                    color: Colors.green,
                    onPressed: _captureImage,
                  ),
                  if (_capturedImage != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_capturedImage!.path),
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  if (_imageText != null && _imageText!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildInputPreview('Image Text:', _imageText!),
                  ],

                  const SizedBox(height: 20),

                  // Optional Text Input
                  Text(
                    text['additionalLabel']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: text['additionalHint']!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      text['submitButton']!,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Build large, accessible button for primary actions
  Widget _buildBigButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 32),
      label: Text(label, style: const TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Build language selector
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Language:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _buildLanguageChip('hindi', 'हिं'),
                _buildLanguageChip('english', 'Eng'),
                _buildLanguageChip('hinglish', 'Hing'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String value, String label) {
    final isSelected = _selectedLanguage == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Build input preview card
  Widget _buildInputPreview(String label, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
