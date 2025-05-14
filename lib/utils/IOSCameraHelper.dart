import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Helper class to fix common iOS camera issues when using Passio SDK
class IOSCameraHelper {
  /// Suppress warnings related to CoreML that do not impact functionality
  static void suppressNeuralNetworkWarnings() {
    if (!Platform.isIOS) return;
    debugPrint('Suppressing iOS neural network warnings');

    // You can add more iOS-specific warning suppression here
    // This is a placeholder for where you'd put iOS warning suppression code
  }

  /// Apply recommended camera settings for iOS food detection
  static Future<void> optimizeCameraForFoodDetection(CameraController controller) async {
    if (!Platform.isIOS || !controller.value.isInitialized) return;

    try {
      // Essential settings for stable camera operation on iOS
      await controller.setFlashMode(FlashMode.off);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFocusMode(FocusMode.auto);

      // Setting focus/exposure point to center helps with food detection
      await controller.setExposurePoint(const Offset(0.5, 0.5));
      await controller.setFocusPoint(const Offset(0.5, 0.5));

      try {
        // Always use 1.0 zoom for food detection - this is critical
        await controller.setZoomLevel(1.0);
        debugPrint('iOS camera zoom set to 1.0 (no zoom)');
      } catch (e) {
        debugPrint('Error setting camera zoom: $e');
      }


      debugPrint('iOS camera optimized for food detection');
    } catch (e) {
      debugPrint('Error optimizing iOS camera: $e');
    }
  }

  /// Force preview update on iOS - sometimes needed to refresh a frozen preview
  static Future<void> refreshCameraPreview(CameraController controller) async {
    if (!Platform.isIOS || !controller.value.isInitialized) return;

    try {
      // This pause/resume cycle helps reset the camera preview on iOS
      await controller.pausePreview();
      await Future.delayed(const Duration(milliseconds: 100));
      await controller.resumePreview();
      debugPrint('iOS camera preview refreshed');
    } catch (e) {
      debugPrint('Error refreshing iOS camera preview: $e');
    }
  }

  // Add this method to your IOSCameraHelper class
  static Future<void> setupCameraFocus(CameraController controller) async {
    if (Platform.isIOS) {
      try {
        // Set focus mode to continuous auto focus
        await controller.setFocusMode(FocusMode.auto);

        // Set focus point to center of the screen
        await controller.setFocusPoint(const Offset(0.5, 0.5));

        // Set exposure mode to continuous auto exposure
        await controller.setExposureMode(ExposureMode.auto);

        // Set exposure point to center as well
        await controller.setExposurePoint(const Offset(0.5, 0.5));

        debugPrint('iOS: Camera focus setup complete');
      } catch (e) {
        debugPrint('iOS: Error setting camera focus: $e');
      }
    }
  }

  /// Reset camera after detection error
  static Future<void> resetCameraAfterError(CameraController controller) async {
    if (!Platform.isIOS || !controller.value.isInitialized) return;

    try {
      // More aggressive reset for severe camera issues
      await controller.pausePreview();
      await Future.delayed(const Duration(milliseconds: 300));

      // Reset camera parameters
      await controller.setFlashMode(FlashMode.off);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFocusMode(FocusMode.auto);

      await controller.resumePreview();
      debugPrint('iOS camera reset after error');
    } catch (e) {
      debugPrint('Error resetting iOS camera: $e');
    }
  }

  /// Adapt camera preview to device orientation
  static Future<void> adaptPreviewForOrientation(
      CameraController controller,
      DeviceOrientation orientation
      ) async {
    if (!Platform.isIOS || !controller.value.isInitialized) return;

    try {
      // Lock to a specific orientation for food detection
      await controller.lockCaptureOrientation(orientation);
      debugPrint('iOS camera orientation locked to $orientation');
    } catch (e) {
      debugPrint('Error setting iOS camera orientation: $e');
    }
  }
}