import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddresScreen extends StatelessWidget {
  const AddresScreen({super.key});

  //log out button
  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email ?? "User"; //in the future change this to fetching a username from Firestore (need to change signup requirements)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Additional Resources'),
        actions: [
          //log out button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _logOut,
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Hello $name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}