import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'mapbox.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'signup_screen.dart';
import 'map/map_screen.dart';
import 'eventboard_screen.dart';
import 'misc_screen.dart';
import 'dormlife_screen.dart';
import 'hourscap_screen.dart';
import 'addres_screen.dart';
import 'feedbackanalytics_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'screens/resources_page.dart';
import 'community_goods/smf/service/moderation_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


Future<void> saveUserFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM TOKEN: $token');
  if (token == null) return;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'fcmToken': token,
  }, SetOptions(merge: true)); // merge: true so you don't overwrite other fields
}

// Background handler (must be top-level function, outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can log or handle background messages here
  debugPrint('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // WEB: Use the keys from the separate file
    FirebaseOptions? firebaseConfigWeb;
    await Firebase.initializeApp(
      options: firebaseConfigWeb, 
    );
  } else {
    // ANDROID/iOS: Use the google-services.json file automatically
    MapboxOptions.setAccessToken(mapboxAccessToken);
    await Firebase.initializeApp();
  }

  await ModerationHelper.loadBadWords();await ModerationHelper.loadBadWords();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //debug
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
  });

  // Request iOS permissions
  await FirebaseMessaging.instance.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beach Circle',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PostLoginInit(
              child: const DashboardScreen(),
            );
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class PostLoginInit extends StatefulWidget {
  final Widget child;
  const PostLoginInit({super.key, required this.child});

  @override
  State<PostLoginInit> createState() => _PostLoginInitState();
}

class _PostLoginInitState extends State<PostLoginInit> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      saveUserFcmToken(); // runs once per login session
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'auth_screen.dart';
// import 'signup_screen.dart';
// import 'dashboard_screen.dart';
// import 'screens/resources_page.dart';

// const bool showResourcesOnly = true;
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   if (!showResourcesOnly) {
//     if (kIsWeb) {
//       await Firebase.initializeApp(
//         //insert stuff here
//       );
//     } else {
//       // ANDROID/iOS: Use the file (google-services.json) automatically
//       await Firebase.initializeApp();
//     }
//   }

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home:
//           showResourcesOnly
//               ? const ResourcesPage()
//               : StreamBuilder<User?>(
//                 stream: FirebaseAuth.instance.authStateChanges(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData) {
//                     return const DashboardScreen();
//                   }
//                   //Otherwise, show Auth Screen
//                   return const AuthScreen();
//                 },
//               ),
//     );
//   }
// }
