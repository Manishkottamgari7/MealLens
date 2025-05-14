import 'package:flutter/foundation.dart';
import 'package:nutrition_ai/nutrition_ai.dart';

/// Configuration helper for the Passio Nutrition AI SDK
class PassioConfig {
  // Your Passio SDK API key - use the one from your code
  static const String passioKey = "k2pz9c0WJFX2AlytO6Xd2wLaPPyFYO90e7U7Venh";

  /// Get the SDK configuration with proper settings
  static PassioConfiguration getConfiguration() {
    // Create platform-specific configurations
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return PassioConfiguration(
        passioKey,
        sdkDownloadsModels: true,      // Enable model downloading
        allowInternetConnection: true,  // Allow internet for model fetching
        remoteOnly: false,              // Ensures it uses local models when available
        debugMode: kDebugMode ? 1 : 0,  // Enable debug logs in debug mode
      );
    }

    // Android configuration
    return PassioConfiguration(
      passioKey,
      sdkDownloadsModels: true,
      allowInternetConnection: true,
      debugMode: kDebugMode ? 1 : 0,
    );
  }

  /// Get food detection configuration optimized for the current platform
  static FoodDetectionConfiguration getDetectionConfig() {
    // Create platform-specific detection settings
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FoodDetectionConfiguration(
        detectVisual: true,
        detectBarcodes: true,
        detectPackagedFood: true,
        framesPerSecond: FramesPerSecond.two,         // Lower FPS for iOS for better performance
        volumeDetectionMode: VolumeDetectionMode.none, // Disable volume detection on iOS
      );
    }

    // Android settings
    return const FoodDetectionConfiguration(
      detectVisual: true,
      detectBarcodes: true,
      detectPackagedFood: true,
      framesPerSecond: FramesPerSecond.three,
      volumeDetectionMode: VolumeDetectionMode.auto,
    );
  }

  /// Check if the SDK is properly configured and ready for use
  static bool isSDKConfigured(PassioStatus status) {
    return status.mode == PassioMode.isReadyForDetection ||
        status.mode == PassioMode.isBeingConfigured;
  }

  /// Get appropriate icon size based on device scale
  static IconSize getIconSize({bool large = false}) {
    return large ? IconSize.px180 : IconSize.px90;
  }

  /// Ensure all models are downloaded
  static Future<PassioStatus> ensureModelDownload() async {
    final status = await NutritionAI.instance.configureSDK(getConfiguration());

    if (status.mode == PassioMode.isDownloadingModels) {
      debugPrint("🚀 Passio SDK is downloading models...");
    } else if (status.mode == PassioMode.isReadyForDetection) {
      debugPrint("✅ Passio SDK is ready and models are downloaded!");
    } else {
      debugPrint("❌ Passio SDK failed: ${status.mode}");
      if (status.missingFiles != null && status.missingFiles!.isNotEmpty) {
        debugPrint("Missing files: ${status.missingFiles}");
      }
    }

    return status;
  }
}