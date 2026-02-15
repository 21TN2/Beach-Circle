// Creates the Forum Posts
//// To DO: figure out a workaround firebase storage

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../model/forum_category.dart';
import '../service/forum_service.dart';

class CreateForumPostPg extends StatefulWidget {
  final ForumCategory category;
  final ForumService forumService;

  const CreateForumPostPg({
    super.key,
    required this.category,
    required this.forumService,
  });

  @override
  State<CreateForumPostPg> createState() => _CreateForumPostPgState();
}

class _CreateForumPostPgState extends State<CreateForumPostPg> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();

  bool _isSubmitting = false;

  XFile? _pickedImage;
  Uint8List? _webPreviewBytes;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // light compression at pick-time
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img == null) return;

    final bytes = await img.readAsBytes();
    final mb = bytes.lengthInBytes / (1024 * 1024);

    // users don't pick large files
    if (mb > 15) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("That image is too large. Choose a smaller one."),
        ),
      );
      return;
    }

    setState(() {
      _pickedImage = img;
      _webPreviewBytes = kIsWeb ? bytes : null;
    });
  }

  // Compress + resize to be tiny BEFORE uploading
  Future<Uint8List> _compressToTinyBytes(XFile image) async {
    final Uint8List originalBytes = kIsWeb
        ? (_webPreviewBytes ?? await image.readAsBytes())
        : await File(image.path).readAsBytes();

    // image fits within these bounds
    final Uint8List compressed = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 60,
      minWidth: 900,
      minHeight: 900,
      format: CompressFormat.jpeg,
    );

    return compressed;
  }

  Future<String> _uploadTinyImage({
    required String postId,
    required XFile image,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(
      'forumPosts/$postId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final bytes = await _compressToTinyBytes(image);

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to post.")),
      );
      return;
    }

    final authorName =
        user.displayName ?? user.email?.split('@').first ?? "Anonymous";

    setState(() => _isSubmitting = true);

    try {
      // 1) Create post immediately
      final postId = await widget.forumService.createPost(
        categoryId: widget.category.id,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        authorId: user.uid,
        authorName: authorName,
      );

      // 2) Upload optional media (timeout so it never hangs)
      if (_pickedImage != null) {
        try {
          final url = await _uploadTinyImage(
            postId: postId,
            image: _pickedImage!,
          ).timeout(const Duration(seconds: 25));

          await widget.forumService.attachMediaToPost(
            postId: postId,
            mediaUrl: url,
            mediaType: 'image',
          );
        } on TimeoutException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Image upload timed out. Post created without media.",
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Post created, but image upload failed: $e"),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Post failed: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Header
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2D21B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
            style: TextStyle(color: Colors.black54, fontSize: 16),
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: const [
                    Icon(Icons.near_me, size: 28, color: Colors.black54),
                    SizedBox(width: 10),
                    Text(
                      "Create Post",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                const Text(
                  "Post Title",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: "Enter Post Title",
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
                    if (v == null || v.trim().isEmpty)
                      return "Title is required.";
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                const Text(
                  "Post Body",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Enter Post Details",
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
                    if (v == null || v.trim().isEmpty)
                      return "Body is required.";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickImage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  icon: const Icon(Icons.attachment, color: Colors.black),
                  label: Text(
                    _pickedImage == null
                        ? "Attach Image"
                        : "Add Image (Optional)",
                    style: const TextStyle(color: Colors.black),
                  ),
                ),

                if (_pickedImage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Selected: ${_pickedImage!.name}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.black12,
                      height: 180,
                      width: double.infinity,
                      child: kIsWeb
                          ? (_webPreviewBytes == null
                                ? const Center(
                                    child: Text("Preview unavailable"),
                                  )
                                : Image.memory(
                                    _webPreviewBytes!,
                                    fit: BoxFit.cover,
                                  ))
                          : Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
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
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Post",
                                style: TextStyle(color: Colors.black),
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
