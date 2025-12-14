import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/scheme_model.dart';

class EasyFormAIService {
  final String _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Improved scheme identification with careful thinking
  Future<SchemeModel?> identifyScheme(String userInput) async {
    try {
      final schemes = SchemeModel.getCommonSchemes();
      final schemesList = schemes
          .map((s) =>
              '- ID: "${s.id}"\n  Name: "${s.name}"\n  Category: "${s.category}"\n  Description: "${s.description}"')
          .join('\n\n');

      final prompt = '''
You are an expert Indian government scheme advisor with deep knowledge of ALL government services. Analyze requests CAREFULLY and match to the correct scheme.

AVAILABLE SCHEMES:
$schemesList

USER REQUEST: "$userInput"

STEP-BY-STEP ANALYSIS:
1. READ the user's request carefully - what document/service do they need?
2. IDENTIFY keywords (PAN, Aadhaar, driving license, ration, pension, certificate, etc.)
3. MATCH to the correct scheme from the list above
4. THINK about the PURPOSE (tax, identity, benefit, license, certificate)

COMPREHENSIVE MATCHING RULES:
IDENTITY CARDS:
- "PAN" / "पैन" / "pan card" / "tax card" / "income tax card" → pan_card
- "Aadhaar" / "आधार" / "aadhar" / "uid" / "unique id" → aadhaar_card
- "Voter" / "मतदाता" / "voter id" / "election card" → voter_id
- "Driving" / "ड्राइविंग" / "license" / "DL" / "driving permit" → driving_license

PENSIONS:
- "widow" / "विधवा" / "husband death" / "husband died" → widow_pension
- "disability" / "विकलांग" / "handicapped" / "disabled" / "handicap" → disability_pension
- "old age" / "senior citizen" / "बुजुर्ग" / "60 years" / "elderly" → old_age_pension

CERTIFICATES:
- "birth" / "जन्म" / "baby" / "newborn" / "birth certificate" → birth_certificate
- "death" / "मृत्यु" / "death certificate" / "cremation" → death_certificate
- "income" / "आय" / "income certificate" / "salary" → income_certificate
- "caste" / "जाति" / "sc st obc" / "reservation" → caste_certificate
- "domicile" / "निवास" / "residence certificate" → domicile_certificate

WELFARE & FOOD:
- "ration" / "राशन" / "food" / "food grains" / "pds" → ration_card

EDUCATION:
- "scholarship" / "छात्रवृत्ति" / "student aid" / "education help" → scholarship

BUSINESS:
- "GST" / "tax registration" / "business tax" → gst_registration
- "shop" / "दुकान" / "establishment" / "shop license" → shop_license

PROPERTY:
- "property tax" / "संपत्ति कर" / "house tax" → property_tax

CRITICAL INSTRUCTIONS:
- Think about what the user ACTUALLY needs
- Match keywords to the scheme PURPOSE
- If user says "PAN card", return "pan_card" NOT "widow_pension"
- Be PRECISE - match the actual request, not random schemes
- Return ONLY the scheme_id from the list above

Your answer (scheme ID only):''';

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are a precise scheme matching expert. Think carefully and return only the exact scheme ID.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1, // Very low temperature for precise matching
          'max_tokens': 30,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final schemeId =
            data['choices'][0]['message']['content'].toString().trim().toLowerCase();

        print('AI Response: $schemeId'); // Debug logging

        // Find the matching scheme by ID
        for (var scheme in schemes) {
          if (schemeId.contains(scheme.id) || 
              scheme.id.contains(schemeId.replaceAll(' ', '_'))) {
            return scheme;
          }
        }
      }
    } catch (e) {
      print('Error identifying scheme: $e');
    }
    return null;
  }

  // Generate bilingual document instructions
  Map<String, dynamic> getDocumentInstructions(SchemeModel scheme) {
    final requiredDocs = scheme.requiredDocuments;
    final optionalDocs = scheme.optionalDocuments;
    
    // Hindi instructions
    String hindiMsg = 'आपके ${_getHindiSchemeName(scheme.name)} आवेदन के लिए, कृपया निम्नलिखित दस्तावेज़ अपलोड करें:\n\n';
    hindiMsg += '✅ आवश्यक दस्तावेज़ (जरूरी):\n';
    for (int i = 0; i < requiredDocs.length; i++) {
      hindiMsg += '${i + 1}. ${_getHindiName(requiredDocs[i])}\n';
    }
    
    if (optionalDocs.isNotEmpty) {
      hindiMsg += '\n⚪ वैकल्पिक दस्तावेज़ (optional - अगर हो तो):\n';
      for (int i = 0; i < optionalDocs.length; i++) {
        hindiMsg += '${i + 1}. ${_getHindiName(optionalDocs[i])}\n';
      }
    }
    
    hindiMsg += '\n📸 कृपया नीचे "Upload Documents" बटन पर क्लिक करें और दस्तावेज़ अपलोड करना शुरू करें।';
    
    // English instructions
    String englishMsg = 'To complete your ${scheme.name} application, please upload the following documents:\n\n';
    englishMsg += '✅ Required Documents (Mandatory):\n';
    for (int i = 0; i < requiredDocs.length; i++) {
      englishMsg += '${i + 1}. ${requiredDocs[i]}\n';
    }
    
    if (optionalDocs.isNotEmpty) {
      englishMsg += '\n⚪ Optional Documents (if available):\n';
      for (int i = 0; i < optionalDocs.length; i++) {
        englishMsg += '${i + 1}. ${optionalDocs[i]}\n';
      }
    }
    
    englishMsg += '\n📸 Please click the "Upload Documents" button below to start uploading.';
    
    return {
      'hindi': hindiMsg,
      'english': englishMsg,
      'requiredDocs': requiredDocs,
      'optionalDocs': optionalDocs,
    };
  }
  
  // Get voice prompt for each document (bilingual)
  Map<String, String> getDocumentVoicePrompt(String documentName, {bool isRequired = true}) {
    final hindiName = _getHindiName(documentName);
    final status = isRequired ? 'आवश्यक है' : 'वैकल्पिक है';
    final statusEn = isRequired ? 'required' : 'optional';
    
    return {
      'hindi': '$hindiName अपलोड करें। यह $status।',
      'english': 'Please upload $documentName. This is $statusEn.',
    };
  }
  
  String _getHindiName(String docName) {
    final hindiNames = {
      // Identity Documents
      'Aadhaar Card': 'आधार कार्ड',
      'PAN Card': 'पैन कार्ड',
      'Voter ID Card': 'मतदाता पहचान पत्र',
      'Driving License': 'ड्राइविंग लाइसेंस',
      'Learner\'s License': 'लर्नर लाइसेंस',
      
      // Proofs
      'Address Proof': 'पता प्रमाण',
      'Age Proof': 'आयु प्रमाण',
      'Date of Birth Proof': 'जन्म तिथि प्रमाण',
      'Age Proof (Birth Certificate or School Certificate)': 'आयु प्रमाण (जन्म प्रमाणपत्र या स्कूल प्रमाणपत्र)',
      'Income Proof': 'आय प्रमाण',
      'Salary Slips or Income Proof': 'वेतन पर्ची या आय प्रमाण',
      'Photo Identity Proof': 'फोटो पहचान पत्र',
      'Owner\'s Identity Proof': 'मालिक का पहचान पत्र',
      'Deceased\'s Identity Proof': 'मृतक का पहचान पत्र',
      'Informant\'s Identity Proof': 'सूचनादाता का पहचान पत्र',
      'Address Proof (minimum 3 years)': 'पता प्रमाण (कम से कम 3 वर्ष)',
      
      // Bank & Financial
      'Bank Passbook': 'बैंक पासबुक',
      'Bank Account Details': 'बैंक खाता विवरण',
      'Bank Statement': 'बैंक स्टेटमेंट',
      
      // Certificates
      'Husband\'s Death Certificate': 'पति का मृत्यु प्रमाणपत्र',
      'Disability Certificate (40% or above)': 'विकलांगता प्रमाणपत्र (40% या अधिक)',
      'Income Certificate': 'आय प्रमाणपत्र',
      'Caste Certificate': 'जाति प्रमाणपत्र',
      'Parent\'s Caste Certificate (if available)': 'माता-पिता का जाति प्रमाणपत्र (यदि उपलब्ध हो)',
      'Parent\'s Marriage Certificate': 'माता-पिता का विवाह प्रमाणपत्र',
      'Educational Certificate': 'शैक्षिक प्रमाणपत्र',
      'School Certificate': 'स्कूल प्रमाणपत्र',
      'Birth Certificate': 'जन्म प्रमाणपत्र',
      'School Leaving Certificate': 'स्कूल छोड़ने का प्रमाणपत्र',
      'Business Registration Certificate': 'व्यवसाय पंजीकरण प्रमाणपत्र',
      
      // Medical/Hospital
      'Hospital Discharge Summary': 'अस्पताल डिस्चार्ज सारांश',
      'Hospital Death Summary or Cremation Certificate': 'अस्पताल मृत्यु सारांश या अंत्येष्टि प्रमाणपत्र',
      'Disability Certificate': 'विकलांगता प्रमाणपत्र',
      
      // Family Documents
      'Family Photo': 'परिवार की फोटो',
      'Parent\'s Aadhaar Card': 'माता-पिता का आधार कार्ड',
      
      // Photos
      'Passport Size Photo': 'पासपोर्ट साइज फोटो',
      
      // Education
      'Educational Marksheets': 'शैक्षिक अंकपत्र',
      
      // Business
      'Business Address Proof': 'व्यवसाय पता प्रमाण',
      'Partnership Deed': 'साझेदारी विलेख',
      'NOC from Property Owner': 'संपत्ति मालिक से अनापत्ति प्रमाणपत्र',
      
      // Property
      'Property Documents': 'संपत्ति दस्तावेज़',
      'Previous Tax Receipt': 'पिछली कर रसीद',
    };
    return hindiNames[docName] ?? docName;
  }
  
  String _getHindiSchemeName(String schemeName) {
    final hindiSchemes = {
      // Pensions
      'Widow Pension Scheme': 'विधवा पेंशन योजना',
      'Disability Pension Scheme': 'विकलांगता पेंशन योजना',
      'Old Age Pension Scheme': 'वृद्धावस्था पेंशन योजना',
      
      // Identity Cards
      'PAN Card Application': 'पैन कार्ड आवेदन',
      'Aadhaar Card Enrollment': 'आधार कार्ड नामांकन',
      'Voter ID Card': 'मतदाता पहचान पत्र',
      'Driving License': 'ड्राइविंग लाइसेंस',
      
      // Food & Welfare
      'Ration Card': 'राशन कार्ड',
      
      // Certificates
      'Birth Certificate': 'जन्म प्रमाणपत्र',
      'Death Certificate': 'मृत्यु प्रमाणपत्र',
      'Income Certificate': 'आय प्रमाणपत्र',
      'Caste Certificate': 'जाति प्रमाणपत्र',
      'Domicile Certificate': 'निवास प्रमाणपत्र',
      
      // Education
      'Education Scholarship': 'शिक्षा छात्रवृत्ति',
      
      // Business
      'GST Registration': 'जीएसटी पंजीकरण',
      'Shop and Establishment License': 'दुकान और प्रतिष्ठान लाइसेंस',
      
      // Property
      'Property Tax Registration': 'संपत्ति कर पंजीकरण',
    };
    return hindiSchemes[schemeName] ?? schemeName;
  }

  // Map extracted OCR data to form fields using AI
  Future<Map<String, String>> mapDataToFormFields({
    required SchemeModel scheme,
    required Map<String, dynamic> extractedData,
  }) async {
    try {
      final prompt = '''
You are an AI assistant filling a government form.

Form: ${scheme.formType}
Scheme: ${scheme.name}

Extracted data from documents:
${jsonEncode(extractedData)}

Map this extracted data to appropriate form fields. Common form fields include:
- Full Name / Applicant Name
- Father's/Husband's Name
- Date of Birth / Age
- Gender
- Address
- Pin Code
- Mobile Number
- Aadhaar Number
- Bank Account Number
- IFSC Code
- District
- State

Return a JSON object mapping field names to values. Only include fields where you have data.
Example: {"Full Name": "Ram Kumar", "Aadhaar Number": "1234 5678 9012", "Mobile Number": "9876543210"}

Return ONLY the JSON object, no other text.
''';

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString();

        // Try to extract JSON from the response
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final mappedData = jsonDecode(jsonStr) as Map<String, dynamic>;
          return mappedData.map((key, value) => MapEntry(key, value.toString()));
        }
      }
    } catch (e) {
      print('Error mapping data to form fields: $e');
    }
    return {};
  }

  // Extract additional information from voice input
  Future<Map<String, String>> extractInfoFromVoice(String voiceText) async {
    try {
      final prompt = '''
Extract personal information from this voice input: "$voiceText"

Look for: name, age, address, mobile number, any other relevant details.

Return a JSON object with extracted information.
Example: {"name": "Ram Kumar", "age": "45", "mobile": "9876543210"}

Return ONLY the JSON object, no other text. If no information found, return {}.
''';

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString();

        // Try to extract JSON from the response
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final extractedData = jsonDecode(jsonStr) as Map<String, dynamic>;
          return extractedData.map((key, value) => MapEntry(key, value.toString()));
        }
      }
    } catch (e) {
      print('Error extracting info from voice: $e');
    }
    return {};
  }
}
