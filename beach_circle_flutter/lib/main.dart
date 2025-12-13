import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart'; // Make sure this matches your file name

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
          // If user is logged in, show a placeholder Home Screen
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
          // Otherwise, show Auth Screen
          return const AuthScreen();
        },
      ),
    );
  }
}