import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auth_screen.dart'; 
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import 'eventboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      //insert stuff here
    );
  } else {
    // ANDROID/iOS: Use the file (google-services.json) automatically
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
             return const DashboardScreen();
          }
          //Otherwise, show Auth Screen
          return const AuthScreen();
        },
      ),
    );
  }
}
