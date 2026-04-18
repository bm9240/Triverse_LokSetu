import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// GrievBot Service - AI-powered complaint intake layer
/// Converts raw citizen input (voice + image + text) into structured complaints
/// Uses Groq AI for NLP and intent detection
class GrievBotService {
  // API key loaded from .env file for security
  // Get your free API key from: https://console.groq.com/keys
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile'; // Fast and accurate model
  
  // Singleton pattern for efficiency
  static final GrievBotService _instance = GrievBotService._internal();
  factory GrievBotService() => _instance;
  
  GrievBotService._internal();

  /// Main function: Convert raw inputs into structured complaint
  /// 
  /// Inputs:
  /// - voiceText: Transcribed speech from user
  /// - imageText: OCR-extracted text from images
  /// - additionalText: Any typed text from user
  /// - location: User's current location (optional)
  /// 
  /// Returns: Structured complaint JSON matching the required schema
  Future<Map<String, dynamic>> processComplaint({
    String? voiceText,
    String? imageText,
    String? additionalText,
    String? location,
  }) async {
    try {
      // Aggregate all inputs
      final aggregatedInput = _aggregateInputs(
        voiceText: voiceText,
        imageText: imageText,
        additionalText: additionalText,
        location: location,
      );

      // Build Groq prompt
      final prompt = _buildGroqPrompt(aggregatedInput, location);

      // Call Groq API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = json.decode(response.body);
      final responseText = responseData['choices'][0]['message']['content'];

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Groq');
      }

      // Parse JSON response
      final structuredComplaint = _parseGroqResponse(responseText);

      return structuredComplaint;
    } catch (e) {
      throw Exception('GrievBot processing failed: $e');
    }
  }

  /// Aggregate all inputs into a single complaint session
  String _aggregateInputs({
    String? voiceText,
    String? imageText,
    String? additionalText,
    String? location,
  }) {
    final parts = <String>[];
    
    if (voiceText != null && voiceText.isNotEmpty) {
      parts.add('Voice Input: $voiceText');
    }
    
    if (imageText != null && imageText.isNotEmpty) {
      parts.add('Image Text: $imageText');
    }
    
    if (additionalText != null && additionalText.isNotEmpty) {
      parts.add('Additional Info: $additionalText');
    }
    
    if (location != null && location.isNotEmpty) {
      parts.add('Location: $location');
    }

    return parts.join('\n\n');
  }

  /// Build the Groq prompt with strict JSON output requirements
  String _buildGroqPrompt(String aggregatedInput, String? location) {
    return '''
You are GrievBot, an AI assistant for LokSetu - a citizen governance system in India.
Your job is to convert raw citizen complaints into clean, structured, government-ready format.

IMPORTANT: You MUST respond ONLY with valid JSON. No other text.

INPUT FROM CITIZEN:
$aggregatedInput

VALID CATEGORIES (choose the most appropriate one):

Municipal & Civic:
- Streetlight & Electricity (streetlight not working, open wires, power outage)
- Roads & Infrastructure (potholes, damaged roads, broken footpaths, unfinished work)
- Water Supply (no water, leakage, contaminated water, low pressure)
- Sanitation & Waste (garbage not collected, overflowing dustbins, open drains, sewer blockage)
- Drainage & Flooding (waterlogging, blocked drainage, flooded streets)

Public Safety & Services:
- Traffic & Transport (broken signals, illegal parking, road hazards, bus stop issues)
- Public Safety (open manholes, fallen trees, dangerous constructions, stray animals)
- Parks & Public Spaces (poor maintenance, broken equipment, lack of lighting)

Health & Environment:
- Public Health (mosquito breeding, unhygienic conditions, stagnant water)
- Environment (air pollution, noise pollution, tree cutting, illegal dumping)

Local Governance:
- Housing & Urban Services (damaged housing, unsafe buildings)
- Government Services (service delays, staff issues, office grievances)

General:
- Other Civic Issue (anything that doesn't fit above categories)

TASK:
Extract the following information and return ONLY a JSON object:

{
  "title": "<descriptive short title WITHOUT severity, e.g. 'Broken Streetlight in Sector 5' or 'Road Pothole Causing Accidents' (5-8 words)>",
  "issueType": "<one of the categories above>",
  "location": "<extracted or improved location>",
  "duration": "<how long this exists: '2 days', '1 week', 'today', or 'unknown'>",
  "severity": "<Low, Medium, High, or Critical>",
  "officialComplaintText": "<formal government-ready complaint in 2-3 sentences>"
}

RULES:
1. Generate a descriptive "title" WITHOUT severity - just the issue description (5-8 words)
2. Severity will be shown separately, so DO NOT include words like "High:", "Critical:", "Low:" in title
3. Title MUST be different from issueType/category - make it specific and descriptive
4. Title format: "[Specific Issue Description]" (e.g., "Broken Road Near School", "Streetlight Outage in Lane 5")
5. AUTOMATICALLY classify into issueType - user never selects category
6. Use NLP to infer the correct category from user's language (Hindi/English/Marathi)
7. If unsure about category, use "Other Civic Issue" - NEVER reject a complaint
8. Extract location from input, or use: "${location ?? 'Location not provided'}"
9. **CRITICALLY IMPORTANT - ASSESS SEVERITY CAREFULLY**:
   - "Critical": IMMEDIATE DANGER to life/health (open manholes, exposed wires, gas leaks, building collapse, accidents happening, severe flooding causing danger)
   - "High": URGENT issues affecting safety/essential services (major road damage with accident risk, complete water supply failure, overflowing sewage, dangerous animals, fire hazards)
   - "Medium": Issues affecting daily life/comfort (streetlight not working, regular garbage collection delay, minor road damage, water pressure issues, parks maintenance)
   - "Low": Minor inconveniences (cosmetic issues, small maintenance needs, non-urgent requests, minor delays)
   
   ANALYZE keywords: "accident", "danger", "khatre", "risk", "emergency", "urgent", "serious" → High/Critical
   LOOK FOR: duration mentions ("weeks", "months") → increases severity
   DEFAULT to Medium ONLY if truly unclear - ALWAYS try to assess based on actual impact
   
10. Keep officialComplaintText concise, formal, and government-ready
11. Return ONLY valid JSON, nothing else

SEVERITY ASSESSMENT EXAMPLES:

Example 1:
Input: "Open manhole on main road, someone fell yesterday"
→ severity: "Critical" (immediate danger to life, accident already happened)

Example 2:
Input: "Road toot gayi hai bahut badi, accident ho sakta hai, 2 weeks se"
→ severity: "High" (major road damage + accident risk + prolonged issue)

Example 3:
Input: "Gali mein light band hai, raat ko andhera hota hai"
→ severity: "Medium" (affects safety but not immediate danger)

Example 4:
Input: "2 din se kuda nahi uthaya, smell aa raha hai"
→ severity: "Medium" (health concern but not immediate)

Example 5:
Input: "Park bench thoda toot gaya hai"
→ severity: "Low" (minor cosmetic issue, no immediate impact)

Example 6:
Input: "Exposed electric wires hanging from pole near school"
→ severity: "Critical" (electrocution risk near children)

FULL EXAMPLES:
Input: "Gali mein light band hai" 
→ title: "Streetlight Outage in Residential Lane"
→ severity: "Medium"
→ issueType: "Streetlight & Electricity"

Input: "Road toot gayi hai, accident ho sakta hai" 
→ title: "Dangerous Pothole Causing Safety Risk"
→ severity: "High"
→ issueType: "Roads & Infrastructure"

Input: "2 din se kuda nahi uthaya" 
→ title: "Garbage Uncollected for 2 Days"
→ severity: "Medium"
→ issueType: "Sanitation & Waste"

RESPOND NOW:
''';
  }

  /// Parse Groq's response and extract the structured complaint
  Map<String, dynamic> _parseGroqResponse(String responseText) {
    try {
      // Clean response - remove markdown code blocks if present
      String cleanedText = responseText.trim();
      
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      
      cleanedText = cleanedText.trim();

      // Parse JSON
      final Map<String, dynamic> parsed = json.decode(cleanedText);

      // Validate required fields
      _validateComplaintStructure(parsed);

      return parsed;
    } catch (e) {
      throw Exception('Failed to parse Groq response: $e\nRaw response: $responseText');
    }
  }

  /// Validate that the parsed complaint has all required fields
  void _validateComplaintStructure(Map<String, dynamic> complaint) {
    final requiredFields = [
      'title',
      'issueType',
      'location',
      'duration',
      'severity',
      'officialComplaintText',
    ];

    for (final field in requiredFields) {
      if (!complaint.containsKey(field) || complaint[field] == null) {
        throw Exception('Missing required field: $field');
      }
    }
  }

  /// Map GrievBot's issueType to existing complaint categories
  String mapToExistingCategory(String issueType) {
    final normalized = issueType.toLowerCase();
    
    // Direct category matching
    final categoryMap = {
      // Municipal & Civic
      'streetlight & electricity': 'Streetlight & Electricity',
      'streetlight': 'Streetlight & Electricity',
      'electricity': 'Streetlight & Electricity',
      'roads & infrastructure': 'Roads & Infrastructure',
      'road repair': 'Roads & Infrastructure',
      'potholes': 'Roads & Infrastructure',
      'water supply': 'Water Supply',
      'water': 'Water Supply',
      'sanitation & waste': 'Sanitation & Waste',
      'garbage collection': 'Sanitation & Waste',
      'garbage': 'Sanitation & Waste',
      'waste': 'Sanitation & Waste',
      'drainage & flooding': 'Drainage & Flooding',
      'drainage': 'Drainage & Flooding',
      'flooding': 'Drainage & Flooding',
      
      // Public Safety & Services
      'traffic & transport': 'Traffic & Transport',
      'traffic': 'Traffic & Transport',
      'transport': 'Traffic & Transport',
      'public transport': 'Traffic & Transport',
      'public safety': 'Public Safety',
      'safety': 'Public Safety',
      'parks & public spaces': 'Parks & Public Spaces',
      'parks': 'Parks & Public Spaces',
      
      // Health & Environment
      'public health': 'Public Health',
      'health': 'Public Health',
      'environment': 'Environment',
      'pollution': 'Environment',
      
      // Local Governance
      'housing & urban services': 'Housing & Urban Services',
      'housing': 'Housing & Urban Services',
      'government services': 'Government Services',
      
      // General
      'other civic issue': 'Other Civic Issue',
      'other': 'Other Civic Issue',
    };

    // Try direct match first
    if (categoryMap.containsKey(normalized)) {
      return categoryMap[normalized]!;
    }
    
    // Try partial matching for flexibility
    for (final entry in categoryMap.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    
    // Default fallback - never reject a complaint
    return 'Other Civic Issue';
  }
}
