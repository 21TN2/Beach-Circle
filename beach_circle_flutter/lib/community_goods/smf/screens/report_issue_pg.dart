// This is where users can report an issue about a post
// created by Giselle -- for student review so i dont forget

import 'package:flutter/material.dart';
import '../service/moderation_service.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({
    super.key,
    required this.postId,
    required this.postAuthorId,
  });

  final String postId;
  final String postAuthorId;

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final ModerationService _moderationService = ModerationService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();

  // support keys
  final GlobalKey _issueFieldAnchorKey = GlobalKey();
  final GlobalKey<FormFieldState<String>> _issueFormFieldKey =
      GlobalKey<FormFieldState<String>>();

  String? _issueType;
  bool _submitting = false;

  // categories
  final List<String> _issueTypes = const [
    'Incorrect / Outdated Information',
    'Inaccessible / Unavailable',
    'Broken / Missing Link',
    'Incomplete / Missing Information',
    'Inappropriate Content',
    'Duplicate',
    'Spam',
    'Other',
  ];

  static const Color _bcYellow = Color(0xFFF2C400);
  static const Color _submitGreen = Color(0xFFB7C300);
  static const Color _cancelOrange = Color(0xFFFF8A00);

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // dropdown menu
  Future<void> _openIssueTypeMenu() async {
    final ctx = _issueFieldAnchorKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        0,
      ),
      constraints: const BoxConstraints(
        maxHeight: 260, // compact height
      ),
      items:
          _issueTypes
              .map(
                (t) => PopupMenuItem<String>(
                  value: t,
                  child: Text(t, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
    );

    if (selected != null) {
      setState(() => _issueType = selected);
      _issueFormFieldKey.currentState?.didChange(selected);
      _issueFormFieldKey.currentState?.validate();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await _moderationService.reportPost(
        postId: widget.postId,
        postAuthorId: widget.postAuthorId,
        reason: _issueType!,
        details: _descController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ReportSubmittedPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not submit report: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bcYellow,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),

        // basic header with it saying report issue
        title: SizedBox(
          height: 44,
          width: double.infinity,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6E8), // color box
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Report an Issue',
                      style: TextStyle(
                        color: Color(0xFF6E6E6E),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.blue),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report an Issue',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Help us improve Beach Circle by reporting any issues you\'ve encountered.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    const Text(
                      'Which of the following best describes\nthe type you are encountering?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dropdown menu bar
                    FormField<String>(
                      key: _issueFormFieldKey,
                      validator: (_) {
                        return (_issueType == null || _issueType!.isEmpty)
                            ? 'Select an issue type'
                            : null;
                      },
                      builder: (state) {
                        return InkWell(
                          key: _issueFieldAnchorKey,
                          onTap: _openIssueTypeMenu,
                          child: InputDecorator(
                            isEmpty: _issueType == null || _issueType!.isEmpty,
                            decoration: InputDecoration(
                              hintText: 'Select Issue Type',
                              filled: true,
                              fillColor: const Color(0xFFF1F1F1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              errorText: state.errorText,
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _issueType ?? '',
                              style: const TextStyle(color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Please describe the issue you\'re experiencing:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _descController,
                      minLines: 6,
                      maxLines: 8,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      validator: (v) {
                        final text = (v ?? '').trim();
                        if (text.isEmpty) return 'Add a short description';
                        if (text.length < 5) return 'Add a bit more detail';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Photo upload is optional (add later).',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        side: const BorderSide(color: Color(0xFFD0D0D0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '+ Add a Photo',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Optional',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE6E6E6))),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed:
                          _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _cancelOrange, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _submitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _submitGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child:
                          _submitting
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
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

// this is the report page after user press submits
class ReportSubmittedPage extends StatelessWidget {
  const ReportSubmittedPage({super.key});

  static const Color _submitGreen = Color(0xFFB7C300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935), // creating ! icon
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        fontSize: 110,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Report Submitted',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _submitGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
