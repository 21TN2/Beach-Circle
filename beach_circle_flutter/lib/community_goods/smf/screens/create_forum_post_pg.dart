// Creates the Forum Posts

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/forum_category.dart';
import '../service/cloudinary_service.dart';
import '../service/forum_service.dart';
import '../service/moderation_helper.dart';
import '../widgets/report_image_selection.dart';

class CreateForumPostPg extends StatefulWidget {
  final ForumCategory category;
  final ForumService forumService;

  const CreateForumPostPg({
    super.key,
    required this.category,
    required this.forumService,
  });

  VoidCallback? get onClose => null;

  @override
  State<CreateForumPostPg> createState() => _CreateForumPostPgState();
}

class _CreateForumPostPgState extends State<CreateForumPostPg> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  final TextEditingController _imageUrlCtrl = TextEditingController();

  bool _showPreview = false;
  bool _isSubmitting = false;
  File? _selectedImage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeUrl(String s) {
    final uri = Uri.tryParse(s.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _showPreview = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to post.")),
      );
      return;
    }

    if (ModerationHelper.containsProfanity(_titleCtrl.text) ||
        ModerationHelper.containsProfanity(_bodyCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please keep the community friendly. Remove inappropriate language before posting.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // reply shows username otherwise anonymous
    final rawDisplayName = user.displayName?.trim();
    final rawEmailName = user.email?.split('@').first.trim();

    final authorName =
        (rawDisplayName != null && rawDisplayName.isNotEmpty)
            ? rawDisplayName
            : ((rawEmailName != null && rawEmailName.isNotEmpty)
                ? rawEmailName
                : "Anonymous");

    final pastedImageUrl = _imageUrlCtrl.text.trim();

    setState(() => _isSubmitting = true);

    try {
      String? finalImageUrl;

      if (_selectedImage != null) {
        finalImageUrl = await CloudinaryService.uploadImage(_selectedImage!);
      } else if (pastedImageUrl.isNotEmpty) {
        finalImageUrl = pastedImageUrl;
      }

      await widget.forumService.createPost(
        categoryId: widget.category.id,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        authorId: user.uid,
        authorName: authorName,
        mediaUrl: finalImageUrl,
        mediaType:
            finalImageUrl == null || finalImageUrl.isEmpty ? null : "image",
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Post failed: $e")));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _imageUrlCtrl.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2D21B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onClose ?? () => Navigator.pop(context),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.category.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Post Title",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: "Enter Post Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) {
                    return v == null || v.trim().isEmpty
                        ? "Title is required."
                        : null;
                  },
                ),

                const SizedBox(height: 14),

                const Text(
                  "Post Body",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Enter Post Details",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) {
                    return v == null || v.trim().isEmpty
                        ? "Body is required."
                        : null;
                  },
                ),

                const SizedBox(height: 16),

                const Text(
                  "Attach Media",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                ReportImageSection(
                  selectedImage: _selectedImage,
                  onPickImage: () {
                    _pickImage();
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _imageUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: "Paste an image URL",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _showPreview = true;
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                  validator: (v) {
                    final text = (v ?? "").trim();
                    if (text.isEmpty) return null;
                    if (!_looksLikeUrl(text)) {
                      return "Please enter a valid http/https URL.";
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_showPreview) {
                      setState(() {});
                    }
                  },
                ),

                const SizedBox(height: 10),

                if (_showPreview && _looksLikeUrl(previewUrl))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        previewUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder:
                            (_, __, ___) => Container(
                              alignment: Alignment.center,
                              color: Colors.black12,
                              child: const Text("Preview failed to load"),
                            ),
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                              color: Color(0xFFD6D6D6),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB7B40E),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                  : const Text(
                                    "Submit",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
