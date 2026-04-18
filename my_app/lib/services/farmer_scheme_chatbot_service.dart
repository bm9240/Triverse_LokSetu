import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Farmer scheme chatbot service using free Groq API.
///
/// Flow:
/// 1) Translate user query to English
/// 2) Generate scheme guidance in English
/// 3) Translate response back to selected app language
class FarmerSchemeChatbotService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static final FarmerSchemeChatbotService _instance =
      FarmerSchemeChatbotService._internal();

  factory FarmerSchemeChatbotService() => _instance;

  FarmerSchemeChatbotService._internal();

  Future<String> _chatWithMessages({
    required List<Map<String, String>> messages,
    double temperature = 0.2,
    int maxTokens = 900,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Groq API key missing. Please configure GROQ_API_KEY in .env file.',
      );
    }

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': _model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI request failed (${response.statusCode}): ${response.body}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content']?.toString();

    if (content == null || content.trim().isEmpty) {
      throw Exception('AI returned an empty response.');
    }

    return content.trim();
  }

  Future<String> _chat({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int maxTokens = 900,
  }) {
    return _chatWithMessages(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  Future<String> translateToEnglish({
    required String input,
    required String sourceLanguage,
  }) async {
    if (sourceLanguage == 'english') return input;

    return _chat(
      systemPrompt:
          'You are a translation assistant. Translate the user text to clear English only. Keep meaning exactly same. Return only translated text.',
      userPrompt:
          'Source language: $sourceLanguage\nText:\n$input',
      temperature: 0.0,
      maxTokens: 500,
    );
  }

  Future<String> getFarmerSchemeGuidanceInEnglish({
    required String englishQuery,
  }) async {
    return _chat(
      systemPrompt: '''
You are a helpful assistant for Indian government schemes related to farmers.
Always provide practical, concise, and factual guidance.
Never invent a scheme if uncertain; clearly say user should verify at official portal.

Return response in this exact structure with these section headers:
Scheme Name:
Benefits:
Eligibility:
How to Apply:

Rules:
- Mention one best matching scheme first.
- If useful, briefly include one "Alternative Scheme" line under Scheme Name section.
- Keep each section easy to read with short bullet points.
- Use plain English.
''',
      userPrompt: 'Farmer query:\n$englishQuery',
      temperature: 0.2,
      maxTokens: 900,
    );
  }

  Future<String> getConversationalFarmerReplyInEnglish({
    required String englishQuery,
    required List<Map<String, String>> englishConversationHistory,
  }) async {
    final trimmedHistory = englishConversationHistory.length > 16
        ? englishConversationHistory.sublist(
            englishConversationHistory.length - 16,
          )
        : englishConversationHistory;

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': '''
You are LokSetu Farmer Assistant for Indian farmers.
Your goals:
1) Answer farmer questions conversationally and clearly.
2) For scheme-related questions, provide this exact section structure:
Scheme Name:
Benefits:
Eligibility:
How to Apply:
3) For follow-up questions, use conversation context and continue naturally.
4) For non-scheme farming questions (crop care, weather prep, soil, irrigation, fertilizer timing), provide practical guidance and also suggest relevant government support schemes if applicable.
5) Do not fabricate uncertain facts. If unsure, advise verification on official portals (e.g., PM-KISAN, PMFBY, state agriculture department websites, CSC centers).
6) Keep responses actionable, concise, and farmer-friendly.
''',
      },
      ...trimmedHistory,
      {
        'role': 'user',
        'content': englishQuery,
      },
    ];

    return _chatWithMessages(
      messages: messages,
      temperature: 0.25,
      maxTokens: 1100,
    );
  }

  Future<String> translateFromEnglish({
    required String input,
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'english') return input;

    final languageName = switch (targetLanguage) {
      'hindi' => 'Hindi',
      'marathi' => 'Marathi',
      _ => 'English',
    };

    return _chat(
      systemPrompt:
          'You are a translation assistant. Translate the English text to $languageName. Preserve section structure and bullet points. Return only translated text.',
      userPrompt: input,
      temperature: 0.0,
      maxTokens: 1200,
    );
  }
}
