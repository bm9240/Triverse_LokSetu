## Language Support
 - **Hindi**: Uses `hi_IN` locale
 - **English**: Uses `en_IN` locale
 - **Marathi**: Uses `mr_IN` locale
### Real Device Testing
...
**Supports Hindi, English, and Marathi**
**4. GrievBot Integration**
Enhanced `lib/screens/grievbot_screen.dart` with:
 - **Multi-language support**: Hindi (hi_IN), English (en_IN), Marathi (mr_IN)
# 🎤 GrievBot with Speech-to-Text - Setup Guide

## Overview
GrievBot now supports **on-device speech recognition** to convert spoken complaints into text. This makes the app accessible for users who prefer speaking over typing.

---

## 🚀 Quick Start for Teammates

### 1. Pull Latest Code
```bash
git pull origin main
cd my_app
```

### 2. Setup Environment Variables
```bash
# Copy the example .env file
cp .env.example .env

# Edit .env and add your Groq API key
# Get free key from: https://console.groq.com/keys
nano .env  # or use any text editor
```

Your `.env` should look like:
```
GROQ_API_KEY=gsk_YourActualApiKeyHere
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run on Real Device (Recommended for Speech-to-Text)
Speech recognition works best on real Android devices:

**Option A: USB Connection**
```bash
# Connect phone via USB, enable USB debugging
flutter devices
flutter run
```

**Option B: Wireless Debugging (Android 11+)**
```bash
# On phone: Settings → Developer Options → Wireless Debugging
# Tap "Pair device with pairing code"
adb pair <IP>:<PORT> <6-DIGIT-CODE>
adb connect <IP>:<MAIN-PORT>
flutter run
```

**Option C: Test on Emulator (Limited Speech Support)**
```bash
# Speech-to-text will timeout on emulator, but other features work
flutter run
```

### 5. Test GrievBot Features
1. Open app → Tap "GrievBot"
2. Select language (Hindi/English/Marathi)
3. **Tap 🎤 microphone button** (real device only)
4. Speak your complaint
5. Watch text appear in real-time
6. Or take photo / type text manually
7. Submit complaint

---

## What Was Added

### 1. Dependencies
Added to `pubspec.yaml`:
```yaml
speech_to_text: ^7.3.0  # On-device speech recognition
```

### 2. Android Permissions
Added to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- For Android SDK 30+ -->
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

### 3. iOS Permissions
Added to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app uses speech recognition to file civic complaints</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>This app converts speech into text for complaints</string>
```

### 4. GrievBot Integration
Enhanced `lib/screens/grievbot_screen.dart` with:
- **New microphone button** below the complaint text field
- **Toggle functionality**: Tap to start listening, tap again to stop
- **Live text display**: Recognized words appear instantly in the text field
 - **Multi-language support**: Hindi (hi_IN), English (en_IN), Marathi (mr_IN)
- **Proper cleanup**: Stops listening when widget is disposed

## How It Works

1. **User taps mic button** → Speech recognition starts
2. **User speaks complaint** → Speech is converted to text on device
3. **Text appears live** in the complaint field
4. **User taps stop** or finishes speaking → Recognition stops
5. **Text is submitted** to GrievBot's AI pipeline (Groq)

## No External Changes Required
- ✅ No backend changes
- ✅ No API integrations
- ✅ No routing logic modifications
- ✅ ProofChain and AutoGov modules untouched
- ✅ Works entirely on-device

## Testing Steps

### After `git pull`:

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on device** (emulators may have limited STT support):
   ```bash
   flutter run
   ```

3. **Test the feature**:
   - Go to GrievBot screen
   - Tap the 🎤 microphone button
   - Speak a complaint (e.g., "Road is broken near my house")
   - Watch text appear in real-time
   - Tap 🛑 Stop button or finish speaking
   - Submit the complaint

### Expected Behavior:
## ⚠️ Important Notes

### Emulator Limitations
- Speech-to-text **will show timeout errors on emulator** due to limited microphone support
- This is **expected behavior** - not a bug
- All other GrievBot features work fine on emulator:
  - ✅ Groq AI processing
  - ✅ Category detection
  - ✅ Severity assessment
  - ✅ Photo capture with OCR
  - ✅ Multi-language support

### Real Device Testing
- Speech recognition works **perfectly on real Android devices**
- Requires microphone permission (granted automatically on first use)
  - Supports Hindi, English, and Marathi

### API Key Security
- Never commit the `.env` file to Git
- Each developer uses their own Groq API key
- Free tier: 30 requests/minute (sufficient for testing)

---

## 🎯 For Demo/Presentation

If you can't test on real device, demonstrate:
1. **Type in the text field** instead of using mic
2. **Take photos** with OCR text extraction
3. **Show the mic button UI** and explain it works on real devices
4. **Emphasize**: "On-device speech recognition, no audio sent to server"

---

## 🐛 Troubleshooting

**Problem: "Speech recognition error: error_speech_timeout"**
- **Solution**: This is normal on emulators. Test on real device.

**Problem: "Speech recognition not available"**
- **Solution**: Check microphone permissions on device.

**Problem: "Configuration error. Groq API key not configured"**
- **Solution**: Add your API key to the `.env` file.

**Problem: Wireless ADB not connecting**
- **Solution**: Use USB cable or continue with emulator testing.

---

**Status**: ✅ Ready for testing and deployment
**Best Experience**: Real Android device with microphone
- Mic button turns **red** when listening
- Icon changes from **mic** to **stop**
- Text updates live as you speak
- Works offline (on-device processing)

## Language Support
- **Hindi**: Uses `hi_IN` locale
- **English**: Uses `en_IN` locale
- **Marathi**: Uses `mr_IN` locale

## Error Handling
- Permission denied → Shows error message
- STT not available → Shows localized error
- Multiple listen sessions prevented
- Auto-stops on widget dispose

## Technical Details
- **Plugin**: `speech_to_text: ^7.3.0`
- **Mode**: `ListenMode.confirmation` (stops after user finishes)
- **Processing**: 100% on-device (no audio sent to backend)
- **State management**: Local state in GrievBot screen
- **Compatibility**: AGP 8+, Flutter SDK ^3.10.3

## One-Line Explanation (For Judges/Mentors)
"GrievBot uses on-device speech recognition via the speech_to_text Flutter plugin to convert spoken complaints into text, making complaint filing accessible without typing."

---

## For Developers

### Code Location
All STT code is in: `lib/screens/grievbot_screen.dart`

### Key Methods:
- `_toggleSpeechToText()`: Starts/stops speech recognition
- `_isListening`: Boolean state tracking active listening
- `_speech`: SpeechToText instance (initialized in `initState`)

### Integration Pattern:
```dart
// Initialize
_speech = stt.SpeechToText();

// Start listening
await _speech.listen(
  onResult: (result) {
    setState(() {
      _voiceTextController.text = result.recognizedWords;
    });
  },
  localeId: 'hi_IN',  // or 'en_IN'
);

// Stop listening
await _speech.stop();
```

### No conflicts with:
- ProofChain module
- AutoGov Engine
- Existing backend APIs
- Other team member's work

---

**Status**: ✅ Ready for testing and deployment
