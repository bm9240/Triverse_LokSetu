# Complete Flutter Setup Guide 🚀

This is a step-by-step guide to set up Flutter on Windows from scratch.

---

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Install Flutter SDK](#install-flutter-sdk)
3. [Update Environment Variables](#update-environment-variables)
4. [Install Android Studio](#install-android-studio)
5. [Configure Android SDK](#configure-android-sdk)
6. [Install Visual Studio Code (Optional)](#install-visual-studio-code-optional)
7. [Run Flutter Doctor](#run-flutter-doctor)
8. [Create Your First Flutter App](#create-your-first-flutter-app)
9. [Troubleshooting](#troubleshooting)

---

## System Requirements

Before starting, ensure your system meets these requirements:
- **Operating System**: Windows 10 or later (64-bit)
- **Disk Space**: At least 2.5 GB (excluding IDE/tools)
- **Tools**: Git for Windows
- **RAM**: Minimum 4GB (8GB recommended)

---

## Step 1: Install Flutter SDK

### Download Flutter
1. Go to [Flutter's official website](https://flutter.dev/)
2. Click on **"Get Started"**
3. Select **Windows** as your operating system
4. Download the latest stable Flutter SDK (zip file)
   - Download link: https://docs.flutter.dev/get-started/install/windows

### Extract Flutter
1. Create a folder where you want to install Flutter (e.g., `C:\src\flutter`)
   - **Important**: Do NOT install in `C:\Program Files\` (requires elevated privileges)
2. Extract the downloaded zip file to your chosen location
3. The final path should look like: `C:\src\flutter\`

---

## Step 2: Update Environment Variables

### Add Flutter to PATH
1. Search for **"Environment Variables"** in Windows Search
2. Click on **"Edit the system environment variables"**
3. Click **"Environment Variables"** button
4. Under **"User variables"**, find the **Path** variable and click **"Edit"**
5. Click **"New"** and add: `C:\src\flutter\bin` (or your Flutter installation path)
6. Click **"OK"** on all windows to save

### Verify Installation
1. Open **Command Prompt** or **PowerShell**
2. Type the following command:
   ```bash
   flutter --version
   ```
3. You should see Flutter version information

---

## Step 3: Install Git for Windows

Flutter requires Git to work properly.

1. Download Git from: https://git-scm.com/download/win
2. Run the installer
3. Use default settings (click "Next" through the installation)
4. Verify installation by opening Command Prompt and typing:
   ```bash
   git --version
   ```

---

## Step 4: Install Android Studio

Android Studio is required for Android development with Flutter.

### Download and Install
1. Go to: https://developer.android.com/studio
2. Download **Android Studio**
3. Run the installer
4. Follow the setup wizard:
   - Choose **"Standard"** installation type
   - Select your preferred UI theme
   - Wait for all components to download (this may take time)

### First Launch Setup
1. Open Android Studio
2. Complete the setup wizard
3. Android Studio will download:
   - Android SDK
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android Emulator

---

## Step 5: Configure Android SDK

### Install Required SDK Components
1. In Android Studio, click on **"More Actions"** → **"SDK Manager"**
   (Or go to: File → Settings → Appearance & Behavior → System Settings → Android SDK)

2. Under **"SDK Platforms"** tab:
   - Check **Android 13.0 (Tiramisu)** or latest version
   - Click **"Apply"** to install

3. Under **"SDK Tools"** tab, ensure these are checked:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
   - ✅ Intel x86 Emulator Accelerator (HAXM installer) - for Intel processors
   - Click **"Apply"** to install

### Set Android SDK Path
1. Note down your Android SDK location (usually: `C:\Users\YourName\AppData\Local\Android\Sdk`)
2. Add to Environment Variables:
   - Variable name: `ANDROID_HOME`
   - Variable value: `C:\Users\YourName\AppData\Local\Android\Sdk`
3. Add to PATH:
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\tools`
   - `%ANDROID_HOME%\tools\bin`

### Accept Android Licenses
1. Open Command Prompt or PowerShell **as Administrator**
2. Run:
   ```bash
   flutter doctor --android-licenses
   ```
3. Type **"y"** (yes) for all licenses

---

## Step 6: Install Visual Studio Code (Optional but Recommended)

VS Code is a lightweight and popular editor for Flutter development.

1. Download from: https://code.visualstudio.com/
2. Install VS Code
3. Open VS Code
4. Install Flutter and Dart extensions:
   - Click on **Extensions** icon (or press `Ctrl+Shift+X`)
   - Search for **"Flutter"**
   - Click **"Install"** on the Flutter extension (this will also install Dart extension)

---

## Step 7: Run Flutter Doctor

Flutter Doctor checks your environment and displays a report of your setup.

### Run the Command
Open Command Prompt or PowerShell and run:
```bash
flutter doctor
```

### Expected Output
You should see something like:
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, on Microsoft Windows)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Visual Studio Code (version x.x.x)
[✓] Android Studio (version xxxx.x)
[✓] Connected device (x available)
[✓] Network resources

• No issues found!
```

### Fix Any Issues
- If you see ❌ or ⚠️ warnings, follow the instructions provided
- Run `flutter doctor -v` for detailed information
- Common issues:
  - **cmdline-tools**: Install from Android Studio SDK Manager
  - **Android licenses**: Run `flutter doctor --android-licenses`

---

## Step 8: Create Your First Flutter App

### Create a New Project
1. Open Command Prompt or PowerShell
2. Navigate to where you want to create your project:
   ```bash
   cd C:\Users\YourName\Documents\FlutterProjects
   ```
3. Create a new Flutter app:
   ```bash
   flutter create my_first_app
   ```
4. Navigate into your project:
   ```bash
   cd my_first_app
   ```

### Run Your App

#### Option A: Run on Chrome (Web)
```bash
flutter run -d chrome
```

#### Option B: Run on Android Emulator
1. Open Android Studio
2. Click **"More Actions"** → **"Virtual Device Manager"**
3. Click **"Create Device"**
4. Select a device (e.g., Pixel 5)
5. Select a system image (e.g., Android 13)
6. Click **"Finish"**
7. Click the **Play** button to start the emulator
8. In Command Prompt, run:
   ```bash
   flutter run
   ```

#### Option C: Run from VS Code
1. Open your project in VS Code
2. Open `lib/main.dart`
3. Press **F5** or click **"Run and Debug"**
4. Select your device from the dropdown in the bottom right corner

---

## Step 9: Useful Flutter Commands

Here are some essential commands you'll use frequently:

```bash
# Check Flutter version
flutter --version

# Check environment setup
flutter doctor

# Create a new Flutter project
flutter create project_name

# Run the app
flutter run

# Run on a specific device
flutter run -d chrome
flutter run -d windows

# List all connected devices
flutter devices

# Install dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Clean build files
flutter clean

# Build APK for Android
flutter build apk

# Build for release
flutter build apk --release

# Analyze code for issues
flutter analyze

# Format your code
flutter format .

# Update Flutter SDK
flutter upgrade
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. "flutter" is not recognized
- **Solution**: Check if Flutter is added to PATH correctly
- Restart Command Prompt/PowerShell after adding to PATH

#### 2. Android licenses not accepted
```bash
flutter doctor --android-licenses
```
Type "y" for all licenses

#### 3. cmdline-tools missing
- Open Android Studio → SDK Manager → SDK Tools
- Install "Android SDK Command-line Tools"

#### 4. Emulator not working
- Enable Virtualization in BIOS (Intel VT-x or AMD-V)
- Install HAXM from Android Studio SDK Manager

#### 5. Gradle build fails
```bash
flutter clean
flutter pub get
flutter run
```

#### 6. Slow performance
- Use Release mode: `flutter run --release`
- Disable unnecessary debugging features

---

## Additional Resources

- **Official Flutter Documentation**: https://docs.flutter.dev/
- **Flutter YouTube Channel**: https://www.youtube.com/@flutterdev
- **Flutter Community**: https://flutter.dev/community
- **Dart Language Tour**: https://dart.dev/guides/language/language-tour
- **Flutter Packages**: https://pub.dev/
- **Flutter Cookbook**: https://docs.flutter.dev/cookbook

---

## Next Steps

1. ✅ Complete the Flutter setup
2. 📱 Try modifying the default app
3. 📚 Follow Flutter's official codelabs
4. 🎨 Learn about widgets and layouts
5. 🔥 Build your own app!

---

## Quick Reference Card

### Project Structure
```
my_app/
├── android/          # Android-specific code
├── ios/              # iOS-specific code
├── lib/              # Your Dart code (main.dart)
├── test/             # Test files
├── pubspec.yaml      # Dependencies and assets
└── README.md         # Project documentation
```

### Main Entry Point
Every Flutter app starts from `lib/main.dart`:
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My First App',
      home: Scaffold(
        appBar: AppBar(title: Text('Hello Flutter')),
        body: Center(child: Text('Welcome to Flutter!')),
      ),
    );
  }
}
```

---

## Tips for Beginners

1. **Start Small**: Don't try to build a complex app immediately
2. **Use Hot Reload**: Press `r` in the terminal to see changes instantly
3. **Read Error Messages**: Flutter provides helpful error messages
4. **Use VS Code**: It's faster and more lightweight than Android Studio
5. **Join Communities**: Ask questions on Stack Overflow or Flutter Discord
6. **Practice Daily**: Build small projects to improve your skills

---

**Happy Flutter Development! 🎉**

Share this guide with your friends and start building amazing apps together!

---

*Last Updated: December 11, 2025*
*Guide created for Windows users*
