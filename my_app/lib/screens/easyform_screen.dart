import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/easyform_ai_service.dart';
import '../models/scheme_model.dart';
import 'document_capture_screen.dart';

class EasyFormScreen extends StatefulWidget {
  const EasyFormScreen({Key? key}) : super(key: key);

  @override
  State<EasyFormScreen> createState() => _EasyFormScreenState();
}

class _EasyFormScreenState extends State<EasyFormScreen> {
  final EasyFormAIService _aiService = EasyFormAIService();
  final TextEditingController _textController = TextEditingController();
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isProcessing = false;
  String _voiceInput = '';
  SchemeModel? _identifiedScheme;
  Map<String, dynamic>? _instructions;
  bool _speakHindi = true; // Default to Hindi
  bool _useVoice = true; // Toggle between voice and text input

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('hi-IN'); // Hindi by default
      await _flutterTts.setSpeechRate(0.5); // Very slow speed (0.5X)
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
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
      
      // Use awaitSpeakCompletion to wait until speech finishes
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(text);
      
      // Add extra small delay to ensure completion
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('TTS Error: $e');
      // Continue without TTS if it fails
    }
  }

  // Detect if input is primarily English
  bool _isEnglish(String text) {
    final lower = text.toLowerCase();
    
    // Check for common Hindi words/phrases
    final hindiWords = [
      'mujhe', 'muje', 'mai', 'main', 'mere', 'mera', 'hai', 'hain',
      'ka', 'ki', 'ke', 'ko', 'se', 'me', 'par', 'aur',
      'chahiye', 'chahie', 'banwana', 'banana', 'lena', 'karna',
      'kaise', 'kya', 'kaun', 'kab', 'kahan',
    ];
    
    // If contains any Hindi words, it's Hindi input
    for (final word in hindiWords) {
      if (lower.contains(word)) {
        return false; // It's Hindi
      }
    }
    
    // Check for common English sentence starters
    final englishStarters = ['i want', 'i need', 'how to', 'apply for', 'get a'];
    for (final starter in englishStarters) {
      if (lower.startsWith(starter)) {
        return true; // It's English
      }
    }
    
    // Default: check character ratio (but now secondary)
    final englishChars = text.split('').where((c) => 
      RegExp(r'[a-zA-Z]').hasMatch(c)
    ).length;
    final totalChars = text.replaceAll(' ', '').length;
    return totalChars > 0 && (englishChars / totalChars) > 0.7;
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          if (_voiceInput.isNotEmpty) {
            _processVoiceInput();
          }
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.errorMsg}')),
        );
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _voiceInput = '';
        _identifiedScheme = null;
        _instructions = null;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceInput = result.recognizedWords;
          });
        },
        localeId: 'en_IN', // English (India) - recognizes both English and Hindi
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    if (_voiceInput.isNotEmpty) {
      _processVoiceInput();
    }
  }

  Future<void> _processVoiceInput() async {
    setState(() => _isProcessing = true);

    try {
      // Identify the scheme from voice input
      final scheme = await _aiService.identifyScheme(_voiceInput);

      if (scheme != null) {
        // Generate bilingual document instructions
        final instructions = _aiService.getDocumentInstructions(scheme);

        setState(() {
          _identifiedScheme = scheme;
          _instructions = instructions;
        });

        // Speak mixed bilingual (Hindi with English in same sentence)
        await Future.delayed(const Duration(milliseconds: 500));
        await _speak(instructions['mixed'], isHindi: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not identify the scheme. Please try again.'),
          ),
        );
        _speak('क्षमा करें, मैं योजना की पहचान नहीं कर सका। कृपया पुनः प्रयास करें।', isHindi: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _proceedToDocumentCapture() {
    if (_identifiedScheme != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentCaptureScreen(
            scheme: _identifiedScheme!,
            voiceInput: _voiceInput,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyForm ✨'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.indigo.shade700],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _useVoice ? Icons.mic_rounded : Icons.edit_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tell us what you need',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _useVoice ? 'Speak in Hindi or English' : 'Type in Hindi or English',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Toggle between voice and text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _useVoice = true),
                              icon: const Icon(Icons.mic),
                              label: const Text('Voice'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _useVoice ? Colors.white : Colors.white30,
                                foregroundColor: _useVoice ? Colors.indigo : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _useVoice = false),
                              icon: const Icon(Icons.keyboard),
                              label: const Text('Type'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_useVoice ? Colors.white : Colors.white30,
                                foregroundColor: !_useVoice ? Colors.indigo : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Voice Input Display
                if (_voiceInput.isNotEmpty)
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
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: Colors.indigo),
                              const SizedBox(width: 8),
                              const Text(
                                'You said:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _voiceInput,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Processing Indicator
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Analyzing your request...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Identified Scheme
                if (_identifiedScheme != null && !_isProcessing)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Scheme Identified',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _identifiedScheme!.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _identifiedScheme!.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _identifiedScheme!.category,
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Document Instructions
                if (_instructions != null && !_isProcessing)
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
                            children: [
                              Icon(Icons.document_scanner,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Required Documents',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: Colors.indigo,
                                ),
                                tooltip: 'Listen',
                                onPressed: () async {
                                  await _speak(_instructions!['mixed'], isHindi: true);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Show mixed bilingual instructions
                          Text(
                            _instructions!['mixed'],
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                // Text Input or Voice Button
                if (_useVoice)
                  // Microphone Button
                  Center(
                    child: GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.red.shade400, Colors.red.shade700]
                                : [Colors.indigo, Colors.indigo.shade700],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.red.withOpacity(0.4)
                                  : Colors.indigo.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  // Text Input Field
                  Column(
                    children: [
                      TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type what you need (e.g., "PAN Card", "Voter ID")...',
                          hintStyle: const TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.indigo, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.indigo, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.edit, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() => _voiceInput = value.trim());
                            _processVoiceInput();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final text = _textController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() => _voiceInput = text);
                            _processVoiceInput();
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 16),
                if (_useVoice)
                  Center(
                    child: Text(
                      _isListening ? 'Listening...' : 'Tap to speak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isListening ? Colors.red : Colors.indigo,
                      ),
                    ),
                  ),

                // Proceed Button
                if (_identifiedScheme != null && !_isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: ElevatedButton(
                      onPressed: _proceedToDocumentCapture,
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
                          Icon(Icons.arrow_forward, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Proceed to Upload Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }
}
