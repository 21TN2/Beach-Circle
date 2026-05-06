/// This is for the add forum request  ///

import 'dart:io';

import 'package:beach_circle_flutter/community_goods/smf/service/cloudinary_service.dart';
import 'package:beach_circle_flutter/community_goods/smf/widgets/report_image_selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateForumPage extends StatefulWidget {
  const CreateForumPage({
    super.key,
    required this.onClose,
    required this.onSubmitted,
  });

  final VoidCallback onClose;
  final VoidCallback onSubmitted;

  @override
  State<CreateForumPage> createState() => _CreateForumPageState();
}

// firebase
class _CreateForumPageState extends State<CreateForumPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isSubmitting = false;
  bool _submitted = false; // to keep track of when users submit a request
  File? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ensures users are logged in
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to submit.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection("forum_requests").add({
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "createdBy": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "status": "pending", // pending | approved | rejected
        "reviewedBy": null,
        "reviewedAt": null,
        "imageUrl": imageUrl,
      });

      if (!mounted) return;

      setState(() {
        _submitted = true; // show thank-you message after submit
        _isSubmitting = false;
      });

      // goes back to the forum page after submitting
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) widget.onSubmitted();
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submit failed: ${e.code}")),
      ); // error handling
      debugPrint("Firestore error: ${e.code} - ${e.message}");
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Submit failed: $e")));
    }
  }

  // building the misc background
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Top yellow bar
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2D21B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onClose, //
        ),
        centerTitle: true,
        title: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "Student Miscellaneous Forum",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: _submitted ? _buildThankYou() : _buildForm(),
        ),
      ),
    );
  }

  // creating the 'create forum' layout
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.near_me, size: 28, color: Colors.black54),
              SizedBox(width: 10),
              Text(
                "Create Forum Details",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // creating the forum title
          const Text(
            "Forum Title",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: "Enter Forum Title",
              hintStyle: const TextStyle(color: Colors.black26),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) {
              // user input required
              if (v == null || v.trim().isEmpty) return "Title is required.";
              return null;
            },
          ),
          const SizedBox(height: 14),

          // creating forum description
          const Text(
            "Forum Description",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Enter Forum Description",
              hintStyle: const TextStyle(color: Colors.black26),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return "Description is required."; // user input required
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          const Text(
            "Forum Image (Optional)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          ReportImageSection(
            selectedImage: _selectedImage,
            onPickImage: () {
              _pickImage();
            },
          ),

          const SizedBox(height: 36),

          // submit and cancel buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : widget.onClose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB7B40E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "Submit",
                            style: TextStyle(color: Colors.black),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // pop up message after user submits
  Widget _buildThankYou() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Thank you for making\nBeach Circle better!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 22),
            Icon(Icons.check_box, size: 80, color: Colors.black),
            SizedBox(height: 22),
            Text(
              "Once submitted, your\nrequest will be under\nreview. We\nappreciate your\npatience.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
