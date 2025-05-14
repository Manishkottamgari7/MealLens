import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for handling iOS permission refresh issues
class PermissionFix {
  /// Platform channel for native iOS permission handling
  static const _platform = MethodChannel('com.demo.app/camera');

  /// Force refresh camera permission status on iOS
  /// This works around a common issue where iOS caches permission results
  static Future<bool> refreshCameraPermission() async {
    if (!Platform.isIOS) {
      // Only needed for iOS
      return await Permission.camera.status.isGranted;
    }

    try {
      // Force permission_handler to refresh its cache
      await Permission.camera.shouldShowRequestRationale;

      // Double-check current status
      var status = await Permission.camera.status;
      debugPrint('Camera permission status after refresh: $status');

      if (status.isGranted) {
        return true;
      }

      // If permission appears denied but might be granted in settings,
      // try secondary check method
      if (status.isDenied || status.isPermanentlyDenied) {
        // Try alternative checking method through platform channel
        try {
          final bool checkResult = await _platform.invokeMethod('checkCameraPermission');
          debugPrint('Platform channel camera check result: $checkResult');
          return checkResult;
        } catch (e) {
          debugPrint('Platform channel check failed: $e');
          // Fall back to manual request as last resort
          status = await Permission.camera.request();
          return status.isGranted;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error refreshing camera permission: $e');
      return false;
    }
  }

  /// Show permission dialog with options to open settings
  static void showPermissionDialog(BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Access Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This app needs camera access to detect food. The camera appears to be disabled in your settings.',
            ),
            const SizedBox(height: 16),
            if (Platform.isIOS)
              const Text(
                'Note: On iOS, you may need to fully restart the app after granting permission in settings.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}