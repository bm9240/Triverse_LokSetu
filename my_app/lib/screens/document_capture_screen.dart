import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/scheme_model.dart';
import '../models/document_model.dart';
import '../services/ocr_service.dart';
import '../services/easyform_ai_service.dart';
import 'form_review_screen.dart';

class DocumentCaptureScreen extends StatefulWidget {
  final SchemeModel scheme;
  final String voiceInput;

  const DocumentCaptureScreen({
    Key? key,
    required this.scheme,
    required this.voiceInput,
  }) : super(key: key);

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();
  final EasyFormAIService _aiService = EasyFormAIService();
  late FlutterTts _flutterTts;

  final Map<String, DocumentModel> _capturedDocuments = {};
  final Map<String, dynamic> _allExtractedData = {};
  bool _isProcessing = false;
  bool _speakHindi = true;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initTts();
    _speakWelcomeMessage();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('hi-IN');
      await _flutterTts.setSpeechRate(0.75); // Slower speed (0.75X)
      await _flutterTts.setVolume(1.0);
      
      // Set error handler
      _flutterTts.setErrorHandler((msg) {
        print('TTS Error Handler: $msg');
      });
    } catch (e) {
      print('TTS Init Error: $e');
    }
  }

  Future<void> _speak(String text, {bool isHindi = true}) async {
    try {
      await _flutterTts.stop(); // Stop any ongoing speech
      await _flutterTts.setLanguage(isHindi ? 'hi-IN' : 'en-US');
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
      // Continue without TTS if it fails
    }
  }

  Future<void> _speakWelcomeMessage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _speak(
      'कृपया दस्तावेज़ अपलोड करना शुरू करें। हर दस्तावेज़ पर क्लिक करें।',
      isHindi: true,
    );
    await Future.delayed(const Duration(milliseconds: 600));
    await _speak(
      'Please start uploading documents. Click on each document.',
      isHindi: false,
    );
  }

  Future<void> _captureDocument(String documentName, {bool isRequired = true}) async {
    // Speak document name in BOTH Hindi and English
    final voicePrompt = _aiService.getDocumentVoicePrompt(
      documentName,
      isRequired: isRequired,
    );
    await _speak(voicePrompt['hindi']!, isHindi: true);
    await Future.delayed(const Duration(milliseconds: 600));
    await _speak(voicePrompt['english']!, isHindi: false);
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      // Show source selection dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isProcessing = true);

        // Extract data from document using OCR
        final extractedData = await _ocrService.processDocument(
          imagePath: image.path,
          documentType: documentName,
        );

        // Create document model
        final document = DocumentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: documentName,
          type: _getDocumentType(documentName),
          imagePath: image.path,
          extractedData: extractedData,
          isVerified: true,
        );

        setState(() {
          _capturedDocuments[documentName] = document;
          _allExtractedData.addAll(extractedData);
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$documentName captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDocumentType(String documentName) {
    final lowerName = documentName.toLowerCase();
    if (lowerName.contains('aadhaar')) return 'aadhaar';
    if (lowerName.contains('pan')) return 'pan';
    if (lowerName.contains('passbook') || lowerName.contains('bank'))
      return 'passbook';
    if (lowerName.contains('address')) return 'address';
    return 'other';
  }

  Future<void> _proceedToReview() async {
    if (_capturedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture at least one document'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Extract info from voice input
      final voiceData = await _aiService.extractInfoFromVoice(widget.voiceInput);
      _allExtractedData.addAll(voiceData);

      // Map all extracted data to form fields using AI
      final mappedFields = await _aiService.mapDataToFormFields(
        scheme: widget.scheme,
        extractedData: _allExtractedData,
      );

      setState(() => _isProcessing = false);

      // Navigate to form review screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormReviewScreen(
            scheme: widget.scheme,
            documents: _capturedDocuments.values.toList(),
            formFields: mappedFields,
            extractedData: _allExtractedData,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final capturedCount = _capturedDocuments.length;
    final totalDocs = widget.scheme.requiredDocuments.length;
    final progress = totalDocs > 0 ? capturedCount / totalDocs : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Documents'),
        backgroundColor: Colors.indigo,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.scheme.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$capturedCount / $totalDocs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 ? Colors.green : Colors.indigo,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progress >= 1.0
                              ? '✅ All documents captured!'
                              : 'Capture remaining documents',
                          style: TextStyle(
                            fontSize: 14,
                            color: progress >= 1.0
                                ? Colors.green
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Required Documents
                Row(
                  children: [
                    const Text(
                      '✅ Required Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '(आवश्यक)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...widget.scheme.requiredDocuments.map((docName) {
                  final isCaptured = _capturedDocuments.containsKey(docName);
                  final document = _capturedDocuments[docName];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isCaptured ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor:
                            isCaptured ? Colors.green : Colors.grey.shade300,
                        child: Icon(
                          isCaptured ? Icons.check : Icons.document_scanner,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        docName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: isCaptured
                          ? const Text(
                              'Captured ✓',
                              style: TextStyle(color: Colors.green),
                            )
                          : const Text('Tap to capture'),
                      trailing: isCaptured && document?.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(document!.imagePath!),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              color: Colors.indigo,
                            ),
                      onTap: () => _captureDocument(docName, isRequired: true),
                    ),
                  );
                }),

                // Optional Documents
                if (widget.scheme.optionalDocuments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        '⚪ Optional Documents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '(वैकल्पिक)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.scheme.optionalDocuments.map((docName) {
                    final isCaptured = _capturedDocuments.containsKey(docName);
                    final document = _capturedDocuments[docName];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCaptured ? Colors.orange : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor:
                              isCaptured ? Colors.orange : Colors.grey.shade300,
                          child: Icon(
                            isCaptured ? Icons.check : Icons.document_scanner,
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                docName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: isCaptured
                            ? const Text(
                                'Captured ✓',
                                style: TextStyle(color: Colors.orange),
                              )
                            : const Text('Tap to capture (if available)'),
                        trailing: isCaptured && document?.imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(document!.imagePath!),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                color: Colors.orange,
                              ),
                        onTap: () => _captureDocument(docName, isRequired: false),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 30),

                // Proceed Button
                ElevatedButton(
                  onPressed: capturedCount > 0 ? _proceedToReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Auto-Fill Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing document...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Extracting information using OCR',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
