# 🎤 Speech-to-Text Setup for GrievBot

## Overview
GrievBot now supports **on-device speech recognition** to convert spoken complaints into text. This makes the app accessible for users who prefer speaking over typing.

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
- **Multi-language support**: Hindi (hi_IN), English (en_IN), Hinglish (en_IN)
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
- Mic button turns **blue** when idle
- Mic button turns **red** when listening
- Icon changes from **mic** to **stop**
- Text updates live as you speak
- Works offline (on-device processing)

## Language Support
- **Hindi**: Uses `hi_IN` locale
- **English**: Uses `en_IN` locale
- **Hinglish**: Uses `en_IN` locale

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
