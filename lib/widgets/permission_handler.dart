import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

class PermissionUtil {
  /// Check and request camera permission with improved iOS handling
  static Future<bool> requestCameraPermission(BuildContext context) async {
    // First check current status
    PermissionStatus status = await Permission.camera.status;

    // If already granted, return true
    if (status.isGranted) {
      return true;
    }

    // If not determined yet (first time request), request permission
    if (status.isDenied) {
      status = await Permission.camera.request();

      // If granted after request, return true
      if (status.isGranted) {
        return true;
      }
    }

    // For iOS-specific handling, try native channel if needed
    if (Platform.isIOS && (status.isPermanentlyDenied || status.isDenied)) {
      try {
        const platform = MethodChannel('com.demo.app/camera');
        final bool granted = await platform.invokeMethod('requestCameraPermission');
        return granted;
      } catch (e) {
        debugPrint('Platform channel error: $e');
      }
    }

    // Handle permanently denied case
    if (status.isPermanentlyDenied || status.isDenied) {
      if (context.mounted) {
        showPermissionDeniedDialog(
          context,
          'Camera Permission Required',
          'This app needs camera access to detect food. Please enable it in your device settings.',
        );
      }
      return false;
    }

    return false;
  }

  /// Show permission denied dialog with option to open settings
  static void showPermissionDeniedDialog(
      BuildContext context,
      String title,
      String message,
      ) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Settings'),
              onPressed: () {
                Navigator.pop(context);
                openIOSSettings();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      );
    }
  }

  /// iOS-specific settings handling that tries multiple approaches
  static Future<void> openIOSSettings() async {
    try {
      // First try the standard approach
      final bool opened = await openAppSettings();

      if (!opened) {
        // If that didn't work, try the iOS-specific approach
        final Uri settingsUrl = Uri.parse('app-settings:');
        if (await canLaunchUrl(settingsUrl)) {
          await launchUrl(settingsUrl);
        } else {
          // If that didn't work, try privacy settings
          final Uri privacyUrl = Uri.parse('App-prefs:Privacy&path=CAMERA');
          if (await canLaunchUrl(privacyUrl)) {
            await launchUrl(privacyUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening settings: $e');
    }
  }
}