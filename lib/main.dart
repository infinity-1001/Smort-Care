import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

// Add this function to handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // FCM and Notification setup
  await _setupFCM();

  runApp(const MyApp());
}

Future<void> _setupFCM() async {
  final fcm = FirebaseMessaging.instance;
  
  // Request permission
  await fcm.requestPermission();

  // Get the token
  String? token = await fcm.getToken();
  print("FCM Token: $token");

  // Background message handling
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground message handling
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message: ${message.notification?.title}");
    NotificationService().showNotification(
      message.notification?.title ?? '',
      message.notification?.body ?? '',
    );
  });

  // Handle notification taps
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("App opened from notification");
    // TODO: Navigate to relevant screen based on the notification
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smort Care',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
