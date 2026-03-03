// Creates the Forum Posts
// TO DO: Implement the image upload media

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

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // Submit post
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

    final authorName =
        user.displayName ?? user.email?.split('@').first ?? "Anonymous";

    setState(() => _isSubmitting = true);

    try {
      await widget.forumService.createPost(
        categoryId: widget.category.id,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        authorId: user.uid,
        authorName: authorName,
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
    return Scaffold(
      backgroundColor: Colors.white,

      // Header
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
                /// CATEGORY TITLE
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

                /// CREATE POST TITLE
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

                /// POST TITLE FIELD
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
                    if (v == null || v.trim().isEmpty) {
                      return "Title is required.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                /// POST BODY FIELD
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
                    if (v == null || v.trim().isEmpty) {
                      return "Body is required.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// POST MEDIA TITLE
                const Text(
                  "Post Media",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                /// ATTACH MEDIA BUTTON
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Media upload coming soon")),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          "Attach Media",
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                      ),

                      Icon(Icons.add, color: Colors.black),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// CANCEL / POST BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
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
