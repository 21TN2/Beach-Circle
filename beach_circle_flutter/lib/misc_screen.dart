import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MiscScreen extends StatefulWidget {
  const MiscScreen({super.key});

  @override
  State<MiscScreen> createState() => _MiscScreenState();
}

class _MiscScreenState extends State<MiscScreen> {
  final TextEditingController _postController = TextEditingController();

  // Function to add a post
  void _postMessage() async {
    if (_postController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('student_misc').add({
        'message': _postController.text,
        'user_email': FirebaseAuth.instance.currentUser?.email ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _postController.clear(); // Clear the text box after posting
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Misc Forum'),
        backgroundColor: const Color(0xFFD7EBFF),
      ),
      body: Column(
        children: [
          // 1. THE LIST OF POSTS (Live Feed)
          Expanded(
            child: StreamBuilder(
              // Listen to the collection, ordered by newest first
              stream: FirebaseFirestore.instance
                  .collection('student_misc')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If no posts exist yet
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No posts yet. Be the first!"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data!.docs[index];
                    // Handle cases where data might be missing safely
                    var email = (post.data() as Map)['user_email'] ?? 'Anonymous';
                    var message = (post.data() as Map)['message'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(
                          message, 
                          style: const TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. THE INPUT FIELD
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: 'Ask or share something...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _postMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}