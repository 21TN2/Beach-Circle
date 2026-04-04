import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_moderator.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists && mounted) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _majorController.text = data['major'] ?? '';
          _yearController.text = data['year'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _interestsController.text = data['interests'] ?? '';
          _photoUrlController.text = data['photo_url'] ?? ''; 
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Profile Picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Paste a direct image link from Google/Web:"),
            const SizedBox(height: 10),
            TextField(
              controller: _photoUrlController,
              decoration: const InputDecoration(
                hintText: "https://example.com/image.png",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); 
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = _photoUrlController.text.trim();

      // --- UPDATED MODERATION: CHECK FOR REASON ---
      if (imageUrl.isNotEmpty) {
        String? flagReason = await ImageModerator.isUrlSafe(imageUrl);
        
        if (flagReason != null) {
          if (mounted) {
            _showBlockedDialog(flagReason); // Pass the reason to the pop-up
            setState(() => _isLoading = false);
          }
          return; 
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'email': user!.email,
        'major': _majorController.text.trim(),
        'year': _yearController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': _interestsController.text.trim(),
        'photo_url': imageUrl, 
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UPDATED POP-UP: TELLS THE USER WHY ---
  void _showBlockedDialog(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red),
            SizedBox(width: 10),
            Text("Image Blocked"),
          ],
        ),
        content: Text(
          "This image was flagged by our safety system.\n\n"
          "Reason: $reason\n\n"
          "Please use a different image URL."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayEmail = user?.email ?? "No Email";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5C518), 
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black, size: 30),
            onPressed: _saveProfile,
            tooltip: 'Save Changes',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Basic Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Name"),
                            _buildTextField(_nameController, "Enter your name"),
                            const SizedBox(height: 15),
                            _buildLabel("Email"),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(displayEmail, style: const TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            const Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showImageUrlDialog, 
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildProfileImage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text("Tap to paste URL", style: TextStyle(fontSize: 12, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Major"), _buildTextField(_majorController, "Your Major")])),
                      const SizedBox(width: 20),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Class Year"), _buildTextField(_yearController, "e.g. Senior")])),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text("Bio Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(hintText: "Tell us about yourself...", border: OutlineInputBorder())),
                  const SizedBox(height: 25),
                  const Text("Interests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTextField(_interestsController, '"Basketball", "Coding"'),
                  const SizedBox(height: 30),
                  const Text("Security and Account Management", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.grey)), child: const Text("Change Password", style: TextStyle(color: Colors.black)))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton(onPressed: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("Log Out", style: TextStyle(color: Colors.white)))),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    String url = _photoUrlController.text.trim();
    if (url.isEmpty) return const Icon(Icons.person, size: 50, color: Colors.grey);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.red)),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)));

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))]),
      child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder(borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
    );
  }
}