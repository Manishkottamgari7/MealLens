import 'dart:io';

import 'package:demo_ios_app/providers/food_log_provider.dart';
import 'package:demo_ios_app/providers/passio_provider.dart';
import 'package:demo_ios_app/providers/subscription_provider.dart';
import 'package:demo_ios_app/providers/user_provider.dart';
import 'package:demo_ios_app/screens/camera_service.dart';
import 'package:demo_ios_app/screens/home_screen.dart';
import 'package:demo_ios_app/services/firestore_service.dart';
import 'package:demo_ios_app/utils/IOSCameraHelper.dart';
import 'package:demo_ios_app/utils/permission_fix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize database structure if needed
  final firestoreService = FirestoreService();
  await firestoreService.initializeDatabase();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize camera service early
  await CameraService.initialize();
  IOSCameraHelper.suppressNeuralNetworkWarnings();

  // For iOS, force refresh permissions on app launch
  if (Platform.isIOS) {
    await PermissionFix.refreshCameraPermission();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PassioProvider()),
        ChangeNotifierProvider(create: (_) => FoodLogProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Nutrition Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: Colors.green,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          fontFamily: 'SF Pro Display',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
