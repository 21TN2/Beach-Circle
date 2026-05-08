import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Added for real images
import 'dart:io'; // Added for File objects

import 'image_moderator.dart'; 
import 'package:beach_circle_flutter/community_goods/smf/service/cloudinary_service.dart';

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
  final TextEditingController _photoUrlController = TextEditingController(); // Keeps track of existing Firebase URL

  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  // --- NEW: Variables for handling local image picking ---
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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

  // --- NEW: Pick a real image from the gallery ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = _photoUrlController.text.trim(); // Default to existing URL

      // --- NEW LOGIC: Upload to Cloudinary & Moderate ---
      if (_selectedImage != null) {
        // 1. Upload to Cloudinary first
        String? uploadedUrl = await CloudinaryService.uploadImage(_selectedImage!);
        
        if (uploadedUrl != null) {
          // 2. Moderate the new Cloudinary URL
          String? flagReason = await ImageModerator.isUrlSafe(uploadedUrl);
          
          if (flagReason != null) {
            if (mounted) {
              _showBlockedDialog(flagReason); 
              setState(() => _isLoading = false);
            }
            return; // STOP! Do not save to Firebase.
          }
          
          // 3. It passed moderation! Set it as the final URL to save.
          finalImageUrl = uploadedUrl;
          _photoUrlController.text = finalImageUrl; // Update controller to match
        } else {
          throw Exception("Failed to upload image to Cloudinary.");
        }
      } else if (finalImageUrl.isNotEmpty) {
        // Fallback: If they didn't pick a new image but have an existing URL, moderate it just in case
        String? flagReason = await ImageModerator.isUrlSafe(finalImageUrl);
        if (flagReason != null) {
          if (mounted) {
            _showBlockedDialog(flagReason);
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // --- Save everything to Firebase ---
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'email': user!.email,
        'major': _majorController.text.trim(),
        'year': _yearController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': _interestsController.text.trim(),
        'photo_url': finalImageUrl, 
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        // Reset the selected file since it's now officially in the cloud
        setState(() {
           _selectedImage = null; 
        });
        
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
          "Please select a different image."
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
                              // --- Changed from showing URL dialog to picking a real image ---
                              onTap: _pickImage, 
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
                            const Text("Tap to upload image", style: TextStyle(fontSize: 12, color: Colors.blue)),
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

  // --- UPDATED: Show the local file if one is selected, otherwise show the network URL ---
  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }

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