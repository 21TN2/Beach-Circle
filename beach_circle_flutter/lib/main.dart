import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // <--- Added this for kIsWeb check
import 'auth_screen.dart'; 
import 'signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 THE FIX FOR THE WHITE SCREEN STARTS HERE 🔥
  if (kIsWeb) {
    // WEB: Use manual keys (Copy these from Firebase Console)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDHtKLDBgYN3ocI8zPOf8jPtE9cxHe0cnE", 
        authDomain: "test-beach-circle.firebaseapp.com",
        projectId: "test-beach-circle",
        storageBucket: "test-beach-circle.firebasestorage.app",
        messagingSenderId: "680938438818",
        appId: "1:680938438818:web:8bd12ddd9688890dcd17fb",
      ),
    );
  } else {
    // ANDROID/iOS: Use the file (google-services.json) automatically
    await Firebase.initializeApp();
  }
  // 🔥 FIX ENDS HERE 🔥

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
          //If user is logged in, show a placeholder Home Screen
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(title: const Text('Home')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Log Out'),
                ),
              ),
            );
          }
          //Otherwise, show Auth Screen
          return const AuthScreen();
        },
      ),
    );
  }
}