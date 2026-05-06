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
import 'map_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    MapboxOptions.setAccessToken(mapboxAccessToken);
  }
  if (kIsWeb) {
    // WEB: Use the keys from the separate file
    await Firebase.initializeApp(options: firebaseConfigWeb);
  } else {
    // ANDROID/iOS: Use the google-services.json file automatically
    await Firebase.initializeApp();
  }

  await ModerationHelper.loadBadWords();await ModerationHelper.loadBadWords();
  
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
          // If the user is logged in, send them to Dashboard
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          // Otherwise, show the Login/Auth Screen
          return const AuthScreen();
        },
      ),
    );
  }
}