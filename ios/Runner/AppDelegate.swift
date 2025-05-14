import Flutter
import UIKit
import AVFoundation
import CoreML
import os.log


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // Suppress CoreML warnings - these don't affect functionality
    suppressNeuralNetworkWarnings()
    // Set up camera permission method channel
    let cameraChannel = FlutterMethodChannel(
      name: "com.demo.app/camera",
      binaryMessenger: controller.binaryMessenger)

    cameraChannel.setMethodCallHandler { [weak self] (call, result) in
      // Handle the different method calls
      switch call.method {
      case "requestCameraPermission":
        self?.requestCameraPermission(result: result)

      case "checkCameraPermission":
        // Add this new case to directly check camera permission status
        self?.checkCameraPermission(result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Pre-warm camera system to avoid lag
    prepareAVCaptureSession()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // New method to directly check camera permission status
  private func checkCameraPermission(result: @escaping FlutterResult) {
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

    switch authStatus {
    case .authorized:
      print("iOS: Camera permission is authorized")
      result(true)
    default:
      print("iOS: Camera permission is not authorized: \(authStatus)")
      result(false)
    }
  }

  // Method to request camera permission
  private func requestCameraPermission(result: @escaping FlutterResult) {
    print("iOS: Handling camera permission request")
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

    switch authStatus {
    case .authorized:
      print("iOS: Camera permission already authorized")
      result(true)

    case .notDetermined:
      print("iOS: Camera permission not determined, requesting...")
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          print("iOS: Camera permission request result: \(granted)")

          // If granted, pre-warm the capture system
          if granted {
            self.prepareAVCaptureSession()
          }

          result(granted)
        }
      }

    case .denied, .restricted:
      print("iOS: Camera permission denied or restricted")
      result(false)

    @unknown default:
      print("iOS: Unknown camera permission status")
      result(false)
    }
  }

  /// Suppress CoreML model loading warnings
  private func suppressNeuralNetworkWarnings() {
    if #available(iOS 17.0, *) {
      // Create custom log to filter CoreML warnings
      let subsystem = "com.apple.CoreML"
      let category = "NeuralNetworkEngine"

      // Disable neural network warning messages
      // This only suppresses non-critical warnings related to model loading
      UserDefaults.standard.set(true, forKey: "MLIONNGlobal_Disable_NetLogLevel_Critical")
      UserDefaults.standard.set(true, forKey: "MLIONNGlobal_Disable_NetLogLevel_Error")
      UserDefaults.standard.set(true, forKey: "MLIONNGlobal_Disable_NetLogLevel_Warning")

      // Set the logging level to silent for CoreML subsystem
      os_log("Suppressing CoreML warnings", log: OSLog(subsystem: subsystem, category: category))
    }
  }

 private func prepareAVCaptureSession() {
     DispatchQueue.global(qos: .userInitiated).async {
         print("iOS: Preparing AVCaptureSession")

         let session = AVCaptureSession()
         session.sessionPreset = .high

         guard let device = AVCaptureDevice.default(for: .video) else {
             print("iOS: No camera device found")
             return
         }

         do {
             let input = try AVCaptureDeviceInput(device: device)

             if session.canAddInput(input) {
                 session.addInput(input)

                 let output = AVCapturePhotoOutput()
                 if session.canAddOutput(output) {
                     session.addOutput(output)

                     // Configure camera focus & exposure settings for stability
                     try device.lockForConfiguration()
                     device.focusMode = .continuousAutoFocus
                     device.exposureMode = .continuousAutoExposure
                     device.whiteBalanceMode = .continuousAutoWhiteBalance
                     device.unlockForConfiguration()

                     session.startRunning()

                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                         session.stopRunning()
                         print("iOS: AVCaptureSession preparation complete")
                     }
                 }
             }
         } catch {
             print("iOS: Error setting up capture session: \(error)")
         }
     }
 }
}