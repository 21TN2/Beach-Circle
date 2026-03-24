import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FeedbackFlowPage(),
  ));
}

class FeedbackFlowPage extends StatefulWidget {
  const FeedbackFlowPage({super.key});

  @override
  State<FeedbackFlowPage> createState() => _FeedbackFlowPageState();
}

class _FeedbackFlowPageState extends State<FeedbackFlowPage> {
  final TextEditingController feedbackController = TextEditingController();

  final String defaultCategory = 'Make Selection';
  final String defaultFeature = 'Make Selection';

  late String selectedCategory;
  late String selectedFeature;

  int? selectedReaction;
  bool showErrors = false;

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
    feedbackController.dispose();
    super.dispose();
  }

  bool get isFormComplete {
    return selectedCategory != defaultCategory &&
        selectedFeature != defaultFeature &&
        feedbackController.text.trim().isNotEmpty &&
        selectedReaction != null;
  }

  void submitFeedback() {
    setState(() {
      showErrors = true;
    });

    final categoryFilled = selectedCategory != defaultCategory;
    final featureFilled = selectedFeature != defaultFeature;
    final descriptionFilled = feedbackController.text.trim().isNotEmpty;
    final reactionFilled = selectedReaction != null;

    final canSubmit =
        categoryFilled && featureFilled && descriptionFilled && reactionFilled;

    if (!canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ThankYouFeedbackPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryHasError = showErrors && selectedCategory == defaultCategory;
    final featureHasError = showErrors && selectedFeature == defaultFeature;
    final descriptionHasError =
        showErrors && feedbackController.text.trim().isEmpty;
    final reactionHasError = showErrors && selectedReaction == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            _topHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Help us make Beach Circle Better!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
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
                            color: descriptionHasError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: descriptionHasError
                                ? Colors.red
                                : const Color(0xFFD0D0D0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: descriptionHasError
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

                    const SizedBox(height: 14),
                    const Text(
                      'Additional Uploads',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.attach_file, size: 34),
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
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 110,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormComplete
                                ? const Color(0xFFD6E7F7)
                                : Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: submitFeedback,
                          child: const Text(
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
            _bottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Container(
      color: const Color(0xFFE7C600),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: const [
          Icon(Icons.arrow_back, size: 30),
          SizedBox(width: 8),
          Expanded(
            child: _SearchHeaderBox(),
          ),
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
          items: items.map((item) {
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
          color: isSelected
              ? const Color(0xFFD6E7F7)
              : const Color(0xFFE5E5E5),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
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
              child: const _SearchHeaderBox(),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
            _bottomNavBar(),
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

Widget _bottomNavBar() {
  return Container(
    height: 72,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color: Color(0xFFF7F7F7),
      border: Border(
        top: BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Icon(Icons.home_outlined, size: 36),
        Icon(Icons.location_on_outlined, size: 36),
        Icon(Icons.layers_outlined, size: 36),
        Icon(Icons.settings_outlined, size: 36),
      ],
    ),
  );
}