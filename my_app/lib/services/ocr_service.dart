import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/document_model.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Extract text from image using ML Kit
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      print('Error extracting text: $e');
      return '';
    }
  }

  // Process document and extract structured data
  Future<Map<String, dynamic>> processDocument({
    required String imagePath,
    required String documentType,
  }) async {
    final text = await extractTextFromImage(imagePath);

    switch (documentType.toLowerCase()) {
      case 'aadhaar':
      case 'aadhaar card':
        return _extractAadhaarData(text);
      case 'pan':
      case 'pan card':
        return _extractPANData(text);
      case 'bank passbook':
      case 'passbook':
        return _extractPassbookData(text);
      case 'address proof':
        return _extractAddressData(text);
      default:
        return {'raw_text': text};
    }
  }

  // Extract Aadhaar card data
  Map<String, dynamic> _extractAadhaarData(String text) {
    final data = <String, dynamic>{};

    // Clean text - remove extra spaces and normalize
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ');
    
    print('=================== AADHAAR OCR ===================');
    print('Original Text: $text');
    print('Clean Text: $cleanText');
    
    // Extract Aadhaar number - try multiple aggressive patterns
    final patterns = [
      // Standard formats
      RegExp(r'\b(\d{4})\s*(\d{4})\s*(\d{4})\b'), // 1234 5678 9012
      RegExp(r'\b(\d{12})\b'), // 123456789012
      
      // With special characters
      RegExp(r'\b(\d{4})[-\s]*(\d{4})[-\s]*(\d{4})\b'), // With dashes
      RegExp(r'\b(\d{4})[.,\s]*(\d{4})[.,\s]*(\d{4})\b'), // With dots/commas
      
      // Anywhere in text - last resort
      RegExp(r'(\d{4})[^\d]*(\d{4})[^\d]*(\d{4})'), // Any 4-4-4 pattern
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(cleanText);
      for (final match in matches) {
        String aadhaar;
        if (match.groupCount >= 3) {
          // Combine groups
          aadhaar = match.group(1)! + match.group(2)! + match.group(3)!;
        } else {
          aadhaar = match.group(0)!.replaceAll(RegExp(r'[^\d]'), '');
        }
        
        if (aadhaar.length == 12 && RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
          data['aadhaar_number'] = aadhaar;
          print('✓ Found Aadhaar: $aadhaar');
          break;
        }
      }
      if (data.containsKey('aadhaar_number')) break;
    }
    
    if (!data.containsKey('aadhaar_number')) {
      print('✗ Aadhaar NOT FOUND');
      // Try to find any 12-digit number
      final anyDigits = RegExp(r'\d+').allMatches(cleanText);
      print('All digit sequences found:');
      for (final match in anyDigits) {
        print('  - ${match.group(0)}');
      }
    }
    print('==================================================');

    // Extract name (usually appears after "Name" or on top)
    final nameRegex = RegExp(r'(?:Name|नाम)[:\s]+([A-Z][a-z]+(?:\s[A-Z][a-z]+)*)',
        caseSensitive: false);
    final nameMatch = nameRegex.firstMatch(text);
    if (nameMatch != null) {
      data['name'] = nameMatch.group(1);
    }

    // Extract DOB
    final dobRegex =
        RegExp(r'(?:DOB|Birth|जन्म)[:\s]+(\d{2}[/-]\d{2}[/-]\d{4})');
    final dobMatch = dobRegex.firstMatch(text);
    if (dobMatch != null) {
      data['date_of_birth'] = dobMatch.group(1);
    }

    // Extract gender
    if (text.toLowerCase().contains('male') ||
        text.toLowerCase().contains('पुरुष')) {
      data['gender'] = text.toLowerCase().contains('female') ||
              text.toLowerCase().contains('महिला')
          ? 'Female'
          : 'Male';
    }

    // Try to extract address (usually multi-line after Address/पता)
    final addressRegex = RegExp(
        r'(?:Address|पता)[:\s]+(.+?)(?=\d{4}\s?\d{4}\s?\d{4}|$)',
        dotAll: true);
    final addressMatch = addressRegex.firstMatch(text);
    if (addressMatch != null) {
      data['address'] = addressMatch.group(1)!.trim();
    }

    data['document_type'] = 'aadhaar';
    data['raw_text'] = text;

    return data;
  }

  // Extract PAN card data
  Map<String, dynamic> _extractPANData(String text) {
    final data = <String, dynamic>{};

    // Extract PAN number (format: AAAAA9999A)
    final panRegex = RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b');
    final panMatch = panRegex.firstMatch(text);
    if (panMatch != null) {
      data['pan_number'] = panMatch.group(0);
    }

    // Extract name
    final nameRegex = RegExp(r'([A-Z][A-Z\s]+)\n', caseSensitive: true);
    final nameMatch = nameRegex.firstMatch(text);
    if (nameMatch != null) {
      data['name'] = nameMatch.group(1)!.trim();
    }

    // Extract father's name
    final fatherRegex =
        RegExp(r"(?:Father'?s? Name)[:\s]+([A-Z][A-Z\s]+)", caseSensitive: false);
    final fatherMatch = fatherRegex.firstMatch(text);
    if (fatherMatch != null) {
      data['father_name'] = fatherMatch.group(1)!.trim();
    }

    // Extract DOB
    final dobRegex = RegExp(r'(\d{2}[/-]\d{2}[/-]\d{4})');
    final dobMatch = dobRegex.firstMatch(text);
    if (dobMatch != null) {
      data['date_of_birth'] = dobMatch.group(1);
    }

    data['document_type'] = 'pan';
    data['raw_text'] = text;

    return data;
  }

  // Extract bank passbook data
  Map<String, dynamic> _extractPassbookData(String text) {
    final data = <String, dynamic>{};

    // Extract account number
    final accountRegex = RegExp(r'(?:A/c|Account|खाता)[:\s]+(\d{9,18})');
    final accountMatch = accountRegex.firstMatch(text);
    if (accountMatch != null) {
      data['account_number'] = accountMatch.group(1);
    }

    // Extract IFSC code
    final ifscRegex = RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b');
    final ifscMatch = ifscRegex.firstMatch(text);
    if (ifscMatch != null) {
      data['ifsc_code'] = ifscMatch.group(0);
    }

    // Extract name
    final nameRegex =
        RegExp(r'(?:Name|नाम)[:\s]+([A-Z][a-z]+(?:\s[A-Z][a-z]+)*)', caseSensitive: false);
    final nameMatch = nameRegex.firstMatch(text);
    if (nameMatch != null) {
      data['account_holder_name'] = nameMatch.group(1);
    }

    // Try to find bank name
    final bankNames = [
      'State Bank',
      'HDFC',
      'ICICI',
      'Axis',
      'Punjab National',
      'Bank of Baroda',
      'Canara Bank',
      'Union Bank'
    ];
    for (final bank in bankNames) {
      if (text.contains(bank)) {
        data['bank_name'] = bank;
        break;
      }
    }

    data['document_type'] = 'passbook';
    data['raw_text'] = text;

    return data;
  }

  // Extract address data
  Map<String, dynamic> _extractAddressData(String text) {
    final data = <String, dynamic>{};

    // Extract PIN code
    final pinRegex = RegExp(r'\b\d{6}\b');
    final pinMatch = pinRegex.firstMatch(text);
    if (pinMatch != null) {
      data['pin_code'] = pinMatch.group(0);
    }

    // Extract mobile number
    final mobileRegex = RegExp(r'\b[6-9]\d{9}\b');
    final mobileMatch = mobileRegex.firstMatch(text);
    if (mobileMatch != null) {
      data['mobile_number'] = mobileMatch.group(0);
    }

    data['address'] = text.trim();
    data['document_type'] = 'address_proof';
    data['raw_text'] = text;

    return data;
  }

  // Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
