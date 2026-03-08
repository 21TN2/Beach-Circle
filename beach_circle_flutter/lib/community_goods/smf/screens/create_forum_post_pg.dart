// Creates the Forum Posts

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    // reply shows usernane otherwise anonymous ---- Student Work Review 2
    final rawDisplayName = user.displayName?.trim();
    final rawEmailName = user.email?.split('@').first.trim();

    final authorName = // grabs the post user name based on the email used to login
        (rawDisplayName != null && rawDisplayName.isNotEmpty)
            ? rawDisplayName
            : ((rawEmailName != null && rawEmailName.isNotEmpty)
                ? rawEmailName
                : "Anonymous");

    final imageUrl = _imageUrlCtrl.text.trim(); // url image

    setState(() => _isSubmitting = true); // when they submit

    try {
      await widget.forumService.createPost(
        // details for post
        categoryId: widget.category.id,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        authorId: user.uid,
        authorName: authorName,
        mediaUrl:
            imageUrl.isEmpty
                ? null
                : imageUrl, // NEW PART FOR SW2: IMAGE URL to post image
        mediaType: imageUrl.isEmpty ? null : "image",
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post failed: $e")),
      ); // if posts fails
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // this is for the url preview
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
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? "Title is required."
                              : null,
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
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? "Body is required."
                              : null,
                ),

                const SizedBox(height: 16),

                const Text(
                  // shown to users to upload image
                  "Post Media (Optional)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _imageUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText:
                        "Paste an image URL", // helps user to paste url image
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => _showPreview = true);
                      },
                    ),
                  ),
                  validator: (v) {
                    // checks if image is proper url i.e http
                    final text = (v ?? "").trim();
                    if (text.isEmpty) return null;
                    if (!_looksLikeUrl(text)) {
                      return "Please enter a valid http/https URL."; // displays message
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_showPreview) setState(() {}); // shows preview
                  },
                ),

                const SizedBox(height: 10),

                if (_showPreview &&
                    _looksLikeUrl(previewUrl)) // if it is a proper image url
                  ClipRRect(
                    // show image preview to user
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        previewUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          // how the image review will look
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: // error handling: show to users that preview can't load --> image cant be posted
                            (_, __, ___) => Container(
                              alignment: Alignment.center,
                              color: Colors.black12,
                              child: const Text("Preview failed to load"),
                            ),
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                /// CANCEL / SUBMIT BUTTONS
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
