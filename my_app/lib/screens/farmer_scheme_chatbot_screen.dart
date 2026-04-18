import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/farmer_scheme_chatbot_service.dart';

class FarmerSchemeChatbotScreen extends StatefulWidget {
  const FarmerSchemeChatbotScreen({
    super.key,
    required this.citizenPhone,
    required this.citizenName,
  });

  final String citizenPhone;
  final String citizenName;

  @override
  State<FarmerSchemeChatbotScreen> createState() =>
      _FarmerSchemeChatbotScreenState();
}

class _FarmerSchemeChatbotScreenState extends State<FarmerSchemeChatbotScreen> {
  final _service = FarmerSchemeChatbotService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  late stt.SpeechToText _speech;

  final List<_ChatMessage> _messages = [];
  final List<Map<String, String>> _englishConversationHistory = [];

  String _selectedLanguage = 'hindi';
  bool _isProcessing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
    _messages.add(
      _ChatMessage(
        text: _getText()['welcome']!,
        isUser: false,
        language: _selectedLanguage,
      ),
    );
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Map<String, String> _getTextForLanguage(String language) {
    switch (language) {
      case 'english':
        return {
          'title': '🌾 Farmer Scheme Assistant',
          'subtitle': 'Ask anything about schemes and farming support',
          'hint': 'Ask about PM-KISAN, crop insurance, irrigation, subsidy...',
          'send': 'Send',
          'readAloud': 'Read Aloud',
          'typing': 'Thinking...',
          'voiceStart': 'Voice Input',
          'voiceStop': 'Stop',
          'sttNotAvailable': 'Speech recognition not available on your phone.',
          'sttTimeout': 'No speech detected. Please try again.',
          'assistantIntro': 'How can I help your farm today?',
          'quickAsk': 'Quick Questions',
          'languageChanged':
              'Language switched to English. Please ask your farmer scheme question.',
          'welcome':
              'Namaste! Ask me about farmer schemes in India. I will share Scheme Name, Benefits, Eligibility, and How to Apply.',
          'empty': 'Please type a question.',
          'error': 'Could not fetch answer. Please try again.',
        };
      case 'marathi':
        return {
          'title': '🌾 शेतकरी योजना सहाय्यक',
          'subtitle': 'योजना आणि शेती मदतीबद्दल काहीही विचारा',
          'hint': 'PM-KISAN, पीक विमा, सिंचन, अनुदान याबद्दल विचारा...',
          'send': 'पाठवा',
          'readAloud': 'मोठ्याने वाचा',
          'typing': 'उत्तर तयार होत आहे...',
          'voiceStart': 'आवाज इनपुट',
          'voiceStop': 'थांबवा',
          'sttNotAvailable': 'तुमच्या फोनवर आवाज ओळख उपलब्ध नाही.',
          'sttTimeout': 'कोणतीही आवाज इनपुट मिळाली नाही. कृपया पुन्हा प्रयत्न करा.',
          'assistantIntro': 'आज तुमच्या शेतीसाठी मी कशी मदत करू?',
          'quickAsk': 'झटपट प्रश्न',
          'languageChanged':
              'भाषा मराठीमध्ये बदलली आहे. कृपया तुमचा शेतकरी योजनांबद्दलचा प्रश्न विचारा.',
          'welcome':
              'नमस्कार! भारतातील शेतकरी योजनांबद्दल विचारा. मी योजना नाव, फायदे, पात्रता आणि अर्ज प्रक्रिया सांगेन.',
          'empty': 'कृपया प्रश्न टाइप करा.',
          'error': 'उत्तर मिळाले नाही. कृपया पुन्हा प्रयत्न करा.',
        };
      default:
        return {
          'title': '🌾 किसान योजना सहायक',
          'subtitle': 'योजना और खेती सहायता पर कुछ भी पूछें',
          'hint': 'PM-KISAN, फसल बीमा, सिंचाई, सब्सिडी के बारे में पूछें...',
          'send': 'भेजें',
          'readAloud': 'सुनें',
          'typing': 'उत्तर तैयार हो रहा है...',
          'voiceStart': 'आवाज़ इनपुट',
          'voiceStop': 'रोकें',
          'sttNotAvailable': 'आपके फोन पर स्पीच रिकग्निशन उपलब्ध नहीं है।',
          'sttTimeout': 'कोई आवाज़ नहीं मिली। कृपया फिर से बोलें।',
          'assistantIntro': 'आज आपकी खेती में मैं कैसे मदद करूं?',
          'quickAsk': 'झटपट सवाल',
          'languageChanged':
              'भाषा हिंदी में बदल दी गई है। कृपया किसान योजना से जुड़ा अपना सवाल पूछें।',
          'welcome':
              'नमस्ते! भारत की किसान योजनाओं के बारे में पूछिए। मैं योजना का नाम, लाभ, पात्रता और आवेदन प्रक्रिया बताऊंगा।',
          'empty': 'कृपया अपना सवाल लिखें।',
          'error': 'उत्तर नहीं मिल सका। कृपया फिर से कोशिश करें।',
        };
    }
  }

  Map<String, String> _getText() => _getTextForLanguage(_selectedLanguage);

  Future<void> _toggleSpeechToText() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final text = _getText();
    final available = await _speech.initialize(
      onError: (error) {
        setState(() {
          _isListening = false;
        });

        final message = error.errorMsg.contains('timeout')
            ? text['sttTimeout']!
            : error.errorMsg;
        _showSnack(message);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    if (!available) {
      _showSnack(text['sttNotAvailable']!);
      return;
    }

    final localeId = switch (_selectedLanguage) {
      'hindi' => 'hi_IN',
      'marathi' => 'mr_IN',
      _ => 'en_IN',
    };

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
      localeId: localeId,
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
  }

  Future<void> _speak(String text, {String? language}) async {
    final activeLanguage = language ?? _selectedLanguage;
    final langCode = switch (activeLanguage) {
      'hindi' => 'hi-IN',
      'marathi' => 'mr-IN',
      _ => 'en-IN',
    };

    await _tts.stop();
    await _tts.setLanguage(langCode);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> _sendQuery() async {
    final raw = _controller.text.trim();
    final requestLanguage = _selectedLanguage;
    final textForRequest = _getTextForLanguage(requestLanguage);

    if (raw.isEmpty) {
      _showSnack(textForRequest['empty']!);
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    }

    setState(() {
      _messages.add(_ChatMessage(text: raw, isUser: true));
      _messages.add(
        _ChatMessage(
          text: textForRequest['typing']!,
          isUser: false,
          isLoading: true,
          language: requestLanguage,
        ),
      );
      _isProcessing = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final englishQuery = await _service.translateToEnglish(
        input: raw,
        sourceLanguage: requestLanguage,
      );

      final contextualEnglishAnswer =
          await _service.getConversationalFarmerReplyInEnglish(
        englishQuery: englishQuery,
        englishConversationHistory: _englishConversationHistory,
      );

      final localizedAnswer = await _service.translateFromEnglish(
        input: contextualEnglishAnswer,
        targetLanguage: requestLanguage,
      );

      _englishConversationHistory.addAll([
        {'role': 'user', 'content': englishQuery},
        {'role': 'assistant', 'content': contextualEnglishAnswer},
      ]);

      setState(() {
        _messages.removeLast();
        _messages.add(
          _ChatMessage(
            text: localizedAnswer,
            isUser: false,
            language: requestLanguage,
          ),
        );
        _isProcessing = false;
      });
    } catch (_) {
      setState(() {
        _messages.removeLast();
        _messages.add(
          _ChatMessage(
            text: textForRequest['error']!,
            isUser: false,
            language: requestLanguage,
          ),
        );
        _isProcessing = false;
      });
    }

    _scrollToBottom();
  }

  List<String> _quickPromptsForLanguage(String language) {
    switch (language) {
      case 'english':
        return [
          'Which scheme gives direct farmer income support?',
          'Am I eligible for PM-KISAN?',
          'How to apply for PM Fasal Bima Yojana?',
          'What subsidy is available for drip irrigation?',
        ];
      case 'marathi':
        return [
          'शेतकऱ्यांसाठी थेट आर्थिक मदत कोणती योजना देते?',
          'मी PM-KISAN साठी पात्र आहे का?',
          'PM फसल विमा योजनेसाठी अर्ज कसा करायचा?',
          'ड्रिप सिंचनासाठी कोणते अनुदान उपलब्ध आहे?',
        ];
      default:
        return [
          'किसानों को सीधी आर्थिक मदद कौन सी योजना देती है?',
          'क्या मैं PM-KISAN के लिए पात्र हूं?',
          'PM फसल बीमा योजना के लिए आवेदन कैसे करें?',
          'ड्रिप सिंचाई के लिए कौन सी सब्सिडी मिलती है?',
        ];
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

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
                _buildLanguageChip('marathi', 'मर'),
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
        if (isSelected) return;

        final switchedText = _getTextForLanguage(value);
        setState(() {
          _selectedLanguage = value;

          if (_messages.length == 1 &&
              !_messages.first.isUser &&
              !_messages.first.isLoading) {
            _messages[0] = _ChatMessage(
              text: switchedText['welcome']!,
              isUser: false,
              language: value,
            );
          } else {
            _messages.add(
              _ChatMessage(
                text: switchedText['languageChanged']!,
                isUser: false,
                language: value,
              ),
            );
          }

          if (_isProcessing && _messages.isNotEmpty && _messages.last.isLoading) {
            _messages[_messages.length - 1] = _ChatMessage(
              text: switchedText['typing']!,
              isUser: false,
              isLoading: true,
              language: value,
            );
          }
        });
        _scrollToBottom();
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

  Widget _buildMessageBubble(_ChatMessage message) {
    final bubbleColor = message.isUser ? Colors.deepPurple.shade100 : Colors.white;
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: message.isUser ? Colors.deepPurple.shade200 : Colors.green.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.isUser ? Icons.person : Icons.agriculture,
                  size: 14,
                  color: message.isUser ? Colors.deepPurple : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  message.isUser ? 'You' : 'Farmer Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: message.isUser ? Colors.deepPurple : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message.text),
            if (!message.isUser && !message.isLoading) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _speak(
                  message.text,
                  language: message.language,
                ),
                icon: const Icon(Icons.volume_up, size: 18),
                label: Text(_getText()['readAloud']!),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _getText();
    return Scaffold(
      appBar: AppBar(
        title: Text(text['title']!),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: _buildLanguageSelector(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text['assistantIntro']!,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text['subtitle']!,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text['quickAsk']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickPromptsForLanguage(_selectedLanguage)
                          .map(
                            (prompt) => ActionChip(
                              label: Text(prompt),
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                      _controller.text = prompt;
                                      _sendQuery();
                                    },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (!_isProcessing) {
                              _sendQuery();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: text['hint']!,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isProcessing ? null : _toggleSpeechToText,
                        icon: Icon(
                          _isListening ? Icons.stop_circle : Icons.mic,
                          color: _isListening ? Colors.red : Colors.green.shade700,
                        ),
                        tooltip: _isListening
                            ? text['voiceStop']!
                            : text['voiceStart']!,
                      ),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _sendQuery,
                        icon: const Icon(Icons.send),
                        label: Text(text['send']!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.language,
  });

  final String text;
  final bool isUser;
  final bool isLoading;
  final String? language;
}
