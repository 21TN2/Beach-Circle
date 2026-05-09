//Packages to implement Analytics & Feedback Page
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/moderation_service.dart';

//Creates the Feedback Page
class FeedbackanalyticsScreen extends StatefulWidget {
  const FeedbackanalyticsScreen({super.key});

  @override
  State<FeedbackanalyticsScreen> createState() =>
      _FeedbackanalyticsScreenState();
}

//Deatils on the Feedback Page
class _FeedbackanalyticsScreenState extends State<FeedbackanalyticsScreen> {
  bool showFeedbackForm = false;

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  //Months to track for Analytics Data
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _monthLabel(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Month';
    final date = timestamp.toDate();
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  //Organize Feedback Forms by Month
  Map<String, List<QueryDocumentSnapshot>> _groupByMonth(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] as Timestamp?;
      final label = _monthLabel(createdAt);
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(doc);
    }

    return grouped;
  }

  Widget _buildStatusSection({
    required BuildContext context,
    required String title,
    required List<QueryDocumentSnapshot> docs,
    required String emptyMessage,
  }) {
    if (docs.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(emptyMessage),
        ),
      );
    }

    final grouped = _groupByMonth(docs);

    //Section Feedback Forms by Month
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          '$title (${docs.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children:
            grouped.entries.map((entry) {
              final month = entry.key;
              final monthDocs = entry.value;

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        month,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    ...monthDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? 'Untitled').toString();
                      final status = (data['status'] ?? '--').toString();
                      final category = (data['category'] ?? '--').toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
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
                    }),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }


  //Feedback Form for Users
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

  //Home page for Analytics & Feedback
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

          //Feedback Form Card
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

          //Analytics Card
          const Text(
            'Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          //Information for the Database
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('feedback')
                    .where('userId', isEqualTo: currentUser?.uid)
                    .where('userDeleted', isEqualTo: false)
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

              //Troubleshoot if analytics data is not popping up
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

              //Shows total feedback forms user has
              final docs = snapshot.data?.docs ?? [];
              final totalFeedbackSubmissions = docs.length;

              String mostRecentFeedbackSubmitted = '--';
              String feedbackStatus = '--';
              Map<String, dynamic>? mostRecentData;

              if (docs.isNotEmpty) {
                final latest = docs.first.data() as Map<String, dynamic>;
                mostRecentData = latest;
                mostRecentFeedbackSubmitted =
                    (latest['title'] ?? '').toString().isEmpty
                        ? 'Untitled'
                        : latest['title'].toString();
                feedbackStatus = (latest['status'] ?? '--').toString();
              }

              //Shows how many forms are submitted
              final submitted =
                  docs
                      .where(
                        (doc) =>
                            (((doc.data() as Map<String, dynamic>)['status'] ??
                                        'Submitted')
                                    .toString() ==
                                'Submitted'),
                      )
                      .toList();

              //Shows how many forms are under review
              final underReview =
                  docs
                      .where(
                        (doc) =>
                            (((doc.data() as Map<String, dynamic>)['status'] ??
                                        '')
                                    .toString() ==
                                'Under Review'),
                      )
                      .toList();

              //Shows how many forms are completed and reviewed by the moderator
              final completed =
                  docs
                      .where(
                        (doc) =>
                            (((doc.data() as Map<String, dynamic>)['status'] ??
                                        '')
                                    .toString() ==
                                'Completed'),
                      )
                      .toList();

              //Shows Users Feedback information(Submissions, Recent Feedback, Recent Feedback Status)
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
                  const SizedBox(height: 16),

                  //Shows most recent feedback information(Title, Category, Status, Month Submitted)
                  if (mostRecentData != null)
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
                            'Most Recent Feedback',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Title: ${(mostRecentData['title'] ?? 'Untitled').toString()}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Category: ${(mostRecentData['category'] ?? '--').toString()}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Status: ${(mostRecentData['status'] ?? '--').toString()}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Month Submitted: ${_monthLabel(mostRecentData['createdAt'] as Timestamp?)}',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  //Feedback History 
                  const Text(
                    'My Feedback History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  //If User has no feedback 
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
                      children: [
                        _buildStatusSection(
                          context: context,
                          title: 'Submitted',
                          docs: submitted,
                          emptyMessage: 'No submitted feedback.',
                        ),
                        _buildStatusSection(
                          context: context,
                          title: 'Under Review',
                          docs: underReview,
                          emptyMessage: 'No feedback currently under review.',
                        ),
                        _buildStatusSection(
                          context: context,
                          title: 'Completed',
                          docs: completed,
                          emptyMessage: 'No completed feedback yet.',
                        ),
                      ],
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


//Feedback Form Page Created
class FeedbackFormContent extends StatefulWidget {
  final VoidCallback onBack;

  const FeedbackFormContent({super.key, required this.onBack});

  @override
  State<FeedbackFormContent> createState() => _FeedbackFormContentState();
}

//Feedback Form Details
class _FeedbackFormContentState extends State<FeedbackFormContent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();

  //Category and Feature selection 
  final String defaultCategory = 'Make Selection';
  final String defaultFeature = 'Make Selection';

  late String selectedCategory;
  late String selectedFeature;

  int? selectedReaction;
  bool showErrors = false;
  bool isSubmitting = false;

  //Allow documents and images to be imported
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  PlatformFile? selectedDocument;

  final ImagePicker _imagePicker = ImagePicker();

  //Category List
  final List<String> categories = [
    'Make Selection',
    'Bug Report',
    'Data Error',
    'UI Issue',
  ];

  //Feature List 
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

  //Checks to see if all information are filled for the feedback form
  bool get isFormComplete {
    return titleController.text.trim().isNotEmpty &&
        selectedCategory != defaultCategory &&
        selectedFeature != defaultFeature &&
        feedbackController.text.trim().isNotEmpty &&
        selectedReaction != null;
  }

  //Allows photos from the gallery to be inputted
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //Allow files to be inputted
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        selectedImage = pickedFile;
        selectedImageBytes = bytes;
        selectedDocument = null;
      });
    }
  }

  //Allows Users to take a photo from the camera
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

  //Allows different types of document to be picked
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

  //Shows the upload option(It is optional)
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [

              //Choose from the Gallery
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),

              //From the Camera
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),

              //From files
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

  //Submission for the Feedback
  Future<void> submitFeedback() async {
    setState(() {
      showErrors = true;
    });

    //If all sections are filled and have details
    final titleFilled = titleController.text.trim().isNotEmpty;
    final categoryFilled = selectedCategory != defaultCategory;
    final featureFilled = selectedFeature != defaultFeature;
    final descriptionFilled = feedbackController.text.trim().isNotEmpty;
    final reactionFilled = selectedReaction != null;

    //Allow submissions if all these sections are filled
    final canSubmit =
        titleFilled &&
        categoryFilled &&
        featureFilled &&
        descriptionFilled &&
        reactionFilled;

    //If not all sections are filled 
    if (!canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    //This is moderation to make sure users are not writing inappropriate content
    if (ModerationService.containsBlockedContent(titleController.text) ||
        ModerationService.containsBlockedContent(feedbackController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your feedback contains inappropriate language and cannot be submitted.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    //Information for the Database
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
        'moderatorResponse': '',
        'reviewedBy': '',
        'reviewedAt': null,
        'userDeleted': false,
        'moderatorDeleted': false,
        'deletedByUserAt': null,
        'deletedByModeratorAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'hasImage': selectedImage != null,
        'hasDocument': selectedDocument != null,
        'documentName': selectedDocument?.name,
      });

      //Once the feedback is submitted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully')),
      );

      //Clears the feedback form
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

      //If feedback form fails to submit
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

  //If section has errors
  @override
  Widget build(BuildContext context) {
    final titleHasError = showErrors && titleController.text.trim().isEmpty;
    final categoryHasError = showErrors && selectedCategory == defaultCategory;
    final featureHasError = showErrors && selectedFeature == defaultFeature;
    final descriptionHasError =
        showErrors && feedbackController.text.trim().isEmpty;
    final reactionHasError = showErrors && selectedReaction == null;

    final titleHasModerationError =
        showErrors &&
        ModerationService.containsBlockedContent(titleController.text.trim());

    final descriptionHasModerationError =
        showErrors &&
        ModerationService.containsBlockedContent(
          feedbackController.text.trim(),
        );

    //Analytics and Feedback Page Build
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

                //Title page
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

                //Feedback Build

                //Title
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
                            titleHasError || titleHasModerationError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            titleHasError || titleHasModerationError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            titleHasError || titleHasModerationError
                                ? Colors.red
                                : Colors.blue,
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
                if (titleHasModerationError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Title contains inappropriate language.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),

                //Category
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

                //Features
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

                  //Description
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            descriptionHasError || descriptionHasModerationError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            descriptionHasError || descriptionHasModerationError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            descriptionHasError || descriptionHasModerationError
                                ? Colors.red
                                : Colors.blue,
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
                if (descriptionHasModerationError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Feedback contains inappropriate language.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),

                //Additional Uploads
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

                //Images
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

                  //Documents
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

                      //Document be removed
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

                //Helpful Section
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

                //If user doesn't select if it was helpful
                if (reactionHasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select how helpful it was.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 18),

                //Page Format
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 140,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFormComplete &&
                                    !ModerationService.containsBlockedContent(
                                      titleController.text,
                                    ) &&
                                    !ModerationService.containsBlockedContent(
                                      feedbackController.text,
                                    )
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

  //Image size allowed
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

  //Header for Analytics & Feedback Page
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

  //Drop down feature for category, feature, and analytics information
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

  //Reaction box for if it was helpful
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

//Thank you page after Feedback is submitted
class ThankYouFeedbackPage extends StatelessWidget {
  const ThankYouFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        //Page Build
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

                    //Message for User
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

                    //Additional Messages
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

                    //Text Build
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

//Search Header
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

//Analytics Feedback Page
class FeedbackDetailsPage extends StatelessWidget {
  final String feedbackId;
  final Map<String, dynamic> feedbackData;

  const FeedbackDetailsPage({
    super.key,
    required this.feedbackId,
    required this.feedbackData,
  });

  //If User wants to delete Feedback
  Future<void> _deleteFeedback(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .update({
            'userDeleted': true,
            'deletedByUserAt': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;

      //If user wants to hide their analytics
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback hidden from your analytics.')),
      );

      Navigator.pop(context);
    } catch (e) {

      //If User wants to delete their feedback
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete feedback: $e')));
    }
  }

  //Feedback Form Page build for moderators
  @override
  Widget build(BuildContext context) {

    //Moderator details
    final title = (feedbackData['title'] ?? 'Untitled').toString();
    final category = (feedbackData['category'] ?? '--').toString();
    final feature = (feedbackData['feature'] ?? '--').toString();
    final description = (feedbackData['description'] ?? '--').toString();
    final status = (feedbackData['status'] ?? '--').toString();
    final moderatorResponse =
        (feedbackData['moderatorResponse'] ?? '').toString();
    final reviewedBy = (feedbackData['reviewedBy'] ?? '').toString();
    final helpfulRating = feedbackData['helpfulRating']?.toString() ?? '--';
    String ratingText = '--';
    if (helpfulRating == '0') ratingText = 'Helpful 😄';
    if (helpfulRating == '1') ratingText = 'Neutral 🙂';
    if (helpfulRating == '2') ratingText = 'Not Helpful ☹️';
    final canDelete = status == 'Submitted' || status == 'Completed';

    //Feedback Form view for Moderators
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _detailRow('Title', title),
            _detailRow('Category', category),
            _detailRow('Feature', feature),
            _detailRow('Description', description),
            _detailRow('Helpful Rating', ratingText),
            _detailRow('Status', status),
            _detailRow(
              'Moderator Response',
              moderatorResponse.isEmpty
                  ? 'No response yet.'
                  : moderatorResponse,
            ),
            _detailRow('Reviewed By', reviewedBy.isEmpty ? '--' : reviewedBy),
            const SizedBox(height: 24),

            //When feedback is submitted, User can delete or hide if they want to
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
                            'Are you sure you want to hide this feedback from your analytics?',
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

            //If Feedback is under review, it cannot be deleted
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This feedback cannot be deleted while it is under review.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  //Page format for the moderator feedback form view page
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
