# 🚀 GrievBot with Groq AI Setup Guide

## Why Groq?

Groq provides **ultra-fast inference** with their LPU™ technology:
- ✅ **Free tier**: 30 requests/minute, 6,000 requests/day
- ⚡ **Blazing fast**: Up to 100x faster than traditional GPUs
- 🎯 **High accuracy**: Using Llama 3.3 70B model
- 💰 **No credit card required** for free tier

## Setup Steps

### 1. Get Your Free Groq API Key

1. Visit: https://console.groq.com/keys
2. Sign up with Google/GitHub (takes 30 seconds)
3. Click "Create API Key"
4. Copy your API key (starts with `gsk_...`)

### 2. Add API Key to Your App

Open `lib/services/grievbot_service.dart` and replace:

```dart
static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
```

With your actual API key:

```dart
static const String _apiKey = 'gsk_your_actual_key_here';
```

### 3. Install Dependencies

Run in terminal:
```bash
cd my_app
flutter pub get
```

### 4. Hot Restart

Press `R` in the Flutter terminal to restart the app.

## Testing

1. Open the app and navigate to **GrievBot**
2. Try submitting a complaint:
   - "Road broken near my house for 2 days"
   - Take a photo of something
   - Add additional text
3. Click "Submit Complaint"
4. You should see structured output with category, severity, etc.

## Available Models

Currently using: `llama-3.3-70b-versatile` (recommended)

Other options in `grievbot_service.dart`:
- `llama-3.1-8b-instant` - Fastest, good for simple tasks
- `mixtral-8x7b-32768` - Good balance of speed and accuracy
- `llama-3.3-70b-versatile` - Best accuracy (default)

## Troubleshooting

### "Configuration error" - API key not set
- Open `grievbot_service.dart`
- Replace `YOUR_GROQ_API_KEY_HERE` with your actual key
- Hot restart the app

### "Authentication error" - Invalid API key
- Check that your API key is correct
- Make sure it starts with `gsk_`
- Generate a new key if needed: https://console.groq.com/keys

### "Rate limit reached"
- Free tier: 30 requests/minute
- Wait 60 seconds and try again
- Or upgrade at: https://console.groq.com/settings/billing

### "Network error"
- Check your internet connection
- Verify you can access: https://api.groq.com
- Check firewall settings

### Slow responses
- Default model is very fast (~500 tokens/sec)
- If slow, check your network speed
- Try switching to `llama-3.1-8b-instant` for even faster responses

## Features

✅ **Multi-language support**: Hindi, English, Hinglish
✅ **Multi-modal input**: Text, images (OCR), location
✅ **Smart categorization**: Automatically detects complaint type
✅ **Severity assessment**: Low, Medium, High, Critical
✅ **Professional formatting**: Converts informal → formal government language
✅ **Location extraction**: Pulls location from text or uses GPS

## API Limits (Free Tier)

- **Rate limit**: 30 requests/minute
- **Daily limit**: 6,000 requests/day
- **Context window**: 32K tokens
- **No credit card required**

## Next Steps

1. Set up your API key
2. Test with various complaints
3. Monitor usage at: https://console.groq.com/usage
4. Consider upgrading if you need higher limits

## Support

- Groq Documentation: https://console.groq.com/docs
- Groq Playground: https://console.groq.com/playground
- LokSetu GrievBot Issues: Check app logs with `flutter run --hot`
