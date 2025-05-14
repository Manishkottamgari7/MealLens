# MealLens

> "Focus on food. We'll do the math."

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Passio_AI-00D084?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTEyIDJDNi40OCAyIDIgNi40OCAyIDEyQzIgMTcuNTIgNi40OCAyMiAxMiAyMkMxNy41MiAyMiAyMiAxNy41MiAyMiAxMkMyMiA2LjQ4IDE3LjUyIDIgMTIgMloiIGZpbGw9IndoaXRlIi8+Cjwvc3ZnPg==" alt="Passio AI">
</p>

## 📱 About MealLens

MealLens is an intelligent nutrition tracking app that leverages advanced AI technology to make food logging effortless. Simply point your camera at any food item, and MealLens will instantly identify it, calculate nutritional information, and log it to your daily diary. Built with Flutter for cross-platform compatibility and powered by Passio AI's cutting-edge food recognition technology.

### ✨ Key Features

- **🎯 AI-Powered Food Detection**: Real-time food recognition using your device's camera
- **📊 Comprehensive Nutrition Tracking**: Automatically calculate calories, macros, and nutrients
- **📝 Detailed Food Diary**: Track all meals, water intake, and activities throughout your day
- **🔍 Food Search**: Search from a vast database of foods when camera detection isn't available
- **📱 Cross-Platform**: Runs seamlessly on both iOS and Android devices
- **☁️ Cloud Sync**: Secure data storage with Firebase integration
- **🍽️ Meal Planning**: Subscription-based meal plans with customizable options
- **💳 Membership Tiers**: Free and Pro membership options with exclusive benefits

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter](https://flutter.dev/docs/get-started/install) (version 3.7.0 or higher)
- [Dart](https://dart.dev/get-dart) (included with Flutter)
- Android Studio or Xcode for mobile development
- A valid Passio AI SDK API key
- Firebase project for backend services

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/meallens.git
   cd meallens
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API keys**
   - Update the Passio AI API key in `lib/config/passio_config.dart`:
     ```dart
     static const String passioKey = "YOUR_PASSIO_API_KEY_HERE";
     ```

4. **Set up Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add your Android and iOS apps to the project
   - Download and add the configuration files:
     - `google-services.json` for Android (place in `android/app/`)
     - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
   - Run Firebase configuration:
     ```bash
     flutterfire configure
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
meallens/
├── lib/
│   ├── config/         # Configuration files (API keys, settings)
│   ├── models/         # Data models
│   ├── providers/      # State management (Provider pattern)
│   ├── screens/        # UI screens
│   ├── services/       # Backend services (Firebase, APIs)
│   ├── utils/          # Utility functions and helpers
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # App entry point
├── assets/             # Images, fonts, and other assets
├── android/            # Android-specific code
├── ios/                # iOS-specific code
└── pubspec.yaml        # Project dependencies
```

## 🎯 Core Technologies

- **Flutter & Dart**: Cross-platform mobile development framework
- **Passio AI SDK**: Advanced food recognition and nutrition analysis
- **Firebase**: Backend services including Firestore for data storage
- **Provider**: State management solution
- **Camera Plugin**: Native camera integration for food scanning

## 📸 How It Works

1. **Food Detection**: Uses the device camera with Passio AI to detect food in real-time
2. **Nutrition Analysis**: Automatically calculates nutritional information for detected items
3. **Food Logging**: Saves food entries to your daily diary with timestamp and meal type
4. **Progress Tracking**: Monitors daily nutritional goals and provides insights

## 🔧 Configuration

### iOS Setup

1. Add camera usage description to `ios/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>MealLens needs camera access to detect and analyze food items</string>
   ```

2. Enable background modes if needed for continuous tracking

### Android Setup

1. Ensure minimum SDK version is set in `android/app/build.gradle`:
   ```gradle
   minSdkVersion 21
   ```

2. Camera permissions are automatically handled by the permission_handler package

## 🎨 Customization

- **Themes**: Modify the app theme in `lib/main.dart`
- **Colors**: Update the color scheme in the theme configuration
- **Icons**: Custom icons can be added to `lib/widgets/app_icons.dart`

## 🧪 Testing

Run the test suite:
```bash
flutter test
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Passio AI](https://passio.ai/) for their incredible food recognition technology
- [Flutter](https://flutter.dev/) team for the amazing framework
- [Firebase](https://firebase.google.com/) for backend services
- All contributors who have helped make MealLens better

## 📞 Support

For support, email support@meallens.app or open an issue on GitHub.

---

<p align="center">Made with ❤️ by the MealLens Team</p>
