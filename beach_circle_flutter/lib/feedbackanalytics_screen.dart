import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FeedbackanalyticsScreen extends StatefulWidget {
  const FeedbackanalyticsScreen({super.key});

  @override
  State<FeedbackanalyticsScreen> createState() =>
      _FeedbackanalyticsScreenState();
}

class _FeedbackanalyticsScreenState extends State<FeedbackanalyticsScreen> {
  bool showFeedbackForm = false;

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? "User";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: Text(
          showFeedbackForm ? 'Analytics & Feedback' : 'Feedback and Analytics',
        ),
        actions: [
          if (!showFeedbackForm)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log Out',
              onPressed: _logOut,
            ),
        ],
      ),
      body:
          showFeedbackForm
              ? FeedbackFormContent(
                onBack: () {
                  setState(() {
                    showFeedbackForm = false;
                  });
                },
              )
              : _analyticsHome(
                name: name,
                onOpenFeedback: () {
                  setState(() {
                    showFeedbackForm = true;
                  });
                },
              ),
    );
  }

  Widget _analyticsHome({
    required String name,
    required VoidCallback onOpenFeedback,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello $name',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'Feedback',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Open Feedback Form'),
              subtitle: const Text('Submit feedback about Beach Circle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenFeedback,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('feedback')
                    .where('userId', isEqualTo: currentUser?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Error loading analytics: ${snapshot.error}'),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final totalFeedbackSubmissions = docs.length;

              String mostRecentFeedbackSubmitted = '--';
              String feedbackStatus = '--';

              if (docs.isNotEmpty) {
                final latest = docs.first.data() as Map<String, dynamic>;
                mostRecentFeedbackSubmitted =
                    (latest['title'] ?? '').toString().isEmpty
                        ? 'Untitled'
                        : latest['title'].toString();
                feedbackStatus = (latest['status'] ?? '--').toString();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total feedback submissions: $totalFeedbackSubmissions',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Most recent feedback submitted: $mostRecentFeedbackSubmitted',
                        ),
                        const SizedBox(height: 6),
                        Text('Feedback status: $feedbackStatus'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'My Feedback History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E9E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No feedback submitted yet.'),
                    )
                  else
                    Column(
                      children:
                          docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final title =
                                (data['title'] ?? 'Untitled').toString();
                            final status = (data['status'] ?? '--').toString();
                            final category =
                                (data['category'] ?? '--').toString();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(title),
                                subtitle: Text('$category • $status'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => FeedbackDetailsPage(
                                            feedbackId: doc.id,
                                            feedbackData: data,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class FeedbackFormContent extends StatefulWidget {
  final VoidCallback onBack;

  const FeedbackFormContent({super.key, required this.onBack});

  @override
  State<FeedbackFormContent> createState() => _FeedbackFormContentState();
}

class _FeedbackFormContentState extends State<FeedbackFormContent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();

  final String defaultCategory = 'Make Selection';
  final String defaultFeature = 'Make Selection';

  late String selectedCategory;
  late String selectedFeature;

  int? selectedReaction;
  bool showErrors = false;
  bool isSubmitting = false;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  PlatformFile? selectedDocument;

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> categories = [
    'Make Selection',
    'Bug Report',
    'Data Error',
    'UI Issue',
  ];

  final List<String> features = [
    'Make Selection',
    'Maps',
    'Dashboard',
    'Hours & Capacity',
    'AdditionalResources4U',
    'MISC Forum',
    'Location Pins',
    'Food Alert',
    'Bathroom Finder',
    'Parking Difficulty',
    'Event Board',
    'Available Classrooms',
    'Outlets in Classrooms',
    'Dorm Life',
    'Weather',
    'Route Options',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = defaultCategory;
    selectedFeature = defaultFeature;
  }

  @override
  void dispose() {
    titleController.dispose();
    feedbackController.dispose();
    super.dispose();
  }

  bool get isFormComplete {
    return titleController.text.trim().isNotEmpty &&
        selectedCategory != defaultCategory &&
        selectedFeature != defaultFeature &&
        feedbackController.text.trim().isNotEmpty &&
        selectedReaction != null;
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        selectedImage = pickedFile;
        selectedImageBytes = bytes;
        selectedDocument = null;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        selectedImage = pickedFile;
        selectedImageBytes = bytes;
        selectedDocument = null;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      withData: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedDocument = result.files.first;
        selectedImage = null;
        selectedImageBytes = null;
      });
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Choose Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> submitFeedback() async {
    setState(() {
      showErrors = true;
    });

    final titleFilled = titleController.text.trim().isNotEmpty;
    final categoryFilled = selectedCategory != defaultCategory;
    final featureFilled = selectedFeature != defaultFeature;
    final descriptionFilled = feedbackController.text.trim().isNotEmpty;
    final reactionFilled = selectedReaction != null;

    final canSubmit =
        titleFilled &&
        categoryFilled &&
        featureFilled &&
        descriptionFilled &&
        reactionFilled;

    if (!canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'title': titleController.text.trim(),
        'category': selectedCategory,
        'feature': selectedFeature,
        'description': feedbackController.text.trim(),
        'helpfulRating': selectedReaction,
        'status': 'Submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'hasImage': selectedImage != null,
        'hasDocument': selectedDocument != null,
        'documentName': selectedDocument?.name,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully')),
      );

      setState(() {
        titleController.clear();
        feedbackController.clear();
        selectedCategory = defaultCategory;
        selectedFeature = defaultFeature;
        selectedReaction = null;
        selectedImage = null;
        selectedImageBytes = null;
        selectedDocument = null;
        showErrors = false;
      });

      widget.onBack();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit feedback: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleHasError = showErrors && titleController.text.trim().isEmpty;
    final categoryHasError = showErrors && selectedCategory == defaultCategory;
    final featureHasError = showErrors && selectedFeature == defaultFeature;
    final descriptionHasError =
        showErrors && feedbackController.text.trim().isEmpty;
    final reactionHasError = showErrors && selectedReaction == null;

    return Column(
      children: [
        _topHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Help us make Beach Circle Better!',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Share Your Feedback!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFE3E3E3),
                  child: const Text(
                    'Thank you for sharing your ideas, issues, or appreciations. '
                    'We will make it our priority to satisfy our customers and make sure '
                    'Beach Circle is running well.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Title',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter a title',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            titleHasError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            titleHasError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: titleHasError ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                ),
                if (titleHasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Please enter a title.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _dropdownField(
                  value: selectedCategory,
                  items: categories,
                  hasError: categoryHasError,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                if (categoryHasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Please select a category.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Which Feature?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _dropdownField(
                  value: selectedFeature,
                  items: features,
                  hasError: featureHasError,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedFeature = value;
                    });
                  },
                ),
                if (featureHasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Please select a feature.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Whats your feedback?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            descriptionHasError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            descriptionHasError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: descriptionHasError ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                ),
                if (descriptionHasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Please enter your feedback.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Additional Uploads',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showUploadOptions,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.attach_file, size: 34),
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedImage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildSelectedImagePreview(),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedImage = null;
                            selectedImageBytes = null;
                          });
                        },
                        child: const Text('Remove Image'),
                      ),
                    ],
                  ),
                if (selectedDocument != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0D0D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insert_drive_file),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selectedDocument!.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedDocument = null;
                          });
                        },
                        child: const Text('Remove Document'),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Was this Helpful?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _reactionBox(0, '😄'),
                    const SizedBox(width: 10),
                    _reactionBox(1, '🙂'),
                    const SizedBox(width: 10),
                    _reactionBox(2, '☹️'),
                  ],
                ),
                if (reactionHasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select how helpful it was.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 140,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFormComplete
                                ? const Color(0xFFD6E7F7)
                                : Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: isSubmitting ? null : submitFeedback,
                      child:
                          isSubmitting
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Send Feedback',
                                style: TextStyle(fontSize: 12),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImagePreview() {
    if (selectedImageBytes != null) {
      return Image.memory(
        selectedImageBytes!,
        height: 120,
        width: 120,
        fit: BoxFit.cover,
      );
    }

    if (!kIsWeb && selectedImage != null) {
      return Image.file(
        File(selectedImage!.path),
        height: 120,
        width: 120,
        fit: BoxFit.cover,
      );
    }

    return Container(
      height: 120,
      width: 120,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _topHeader() {
    return Container(
      color: const Color(0xFFE7C600),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
          const Expanded(child: _SearchHeaderBox()),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool hasError,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: hasError ? Colors.red : const Color(0xFFD0D0D0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items:
              items.map((item) {
                final isDefault = item == 'Make Selection';
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDefault ? Colors.grey : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _reactionBox(int index, String emoji) {
    final isSelected = selectedReaction == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedReaction = index;
        });
      },
      child: Container(
        width: 48,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD6E7F7) : const Color(0xFFE5E5E5),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class ThankYouFeedbackPage extends StatelessWidget {
  const ThankYouFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFE7C600),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: _SearchHeaderBox()),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.celebration, size: 44),
                        Icon(Icons.celebration, size: 44),
                      ],
                    ),
                    const SizedBox(height: 42),
                    const Text(
                      'Thank you for making\nBeach Circle better!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 52),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 52),
                    const Text(
                      'Your feedback has\nbeen submitted and\nis under review. We\nappreciate your\npatience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 80,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6E7F7),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Exit'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeaderBox extends StatelessWidget {
  const _SearchHeaderBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              'Analytics & Feedback',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.blue),
        ],
      ),
    );
  }
}

class FeedbackDetailsPage extends StatelessWidget {
  final String feedbackId;
  final Map<String, dynamic> feedbackData;

  const FeedbackDetailsPage({
    super.key,
    required this.feedbackId,
    required this.feedbackData,
  });

  Future<void> _deleteFeedback(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback deleted successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete feedback: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (feedbackData['title'] ?? 'Untitled').toString();
    final category = (feedbackData['category'] ?? '--').toString();
    final feature = (feedbackData['feature'] ?? '--').toString();
    final description = (feedbackData['description'] ?? '--').toString();
    final status = (feedbackData['status'] ?? '--').toString();
    final helpfulRating = feedbackData['helpfulRating']?.toString() ?? '--';
    String ratingText = '--';
    if (helpfulRating == '0') ratingText = 'Helpful 😄';
    if (helpfulRating == '1') ratingText = 'Neutral 🙂';
    if (helpfulRating == '2') ratingText = 'Not Helpful ☹️';
    final canDelete = status == 'Submitted';

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Title', title),
            _detailRow('Category', category),
            _detailRow('Feature', feature),
            _detailRow('Description', description),
            _detailRow('Helpful Rating', ratingText),
            _detailRow('Status', status),
            const SizedBox(height: 24),
            if (canDelete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete Feedback'),
                          content: const Text(
                            'Are you sure you want to delete this feedback?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await _deleteFeedback(context);
                    }
                  },
                  child: const Text('Delete Feedback'),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This feedback can no longer be deleted because it is already being processed or completed.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
