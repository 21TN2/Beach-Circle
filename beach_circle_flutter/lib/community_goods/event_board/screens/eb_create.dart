// eb_create.dart
// Create event screen for Event Board

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import 'package:beach_circle_flutter/community_goods/event_board/models/eb_event.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/eb_services.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/eb_cloudinary.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/moderation_helper.dart';
import 'package:beach_circle_flutter/community_goods/event_board/widgets/eb_category_dot.dart';

class EBCreatePage extends StatefulWidget {
  const EBCreatePage({super.key});

  @override
  State<EBCreatePage> createState() => _EBCreatePageState();
}

class _EBCreatePageState extends State<EBCreatePage> {
  static const Color kYellow    = Color(0xFFFFCC00);
  static const Color kYellowBtn = Color(0xFFD4A800);
  static const Color kPurple    = Color(0xFF3B3599);
  static const Color kBg        = Color(0xFFF0F0F0);

  String?      _selectedBuildingCode;
  String?      _selectedBuildingName;
  EBCategory   _selectedCategory = EBCategory.sports;
  bool         _isAllDay         = false;
  bool         _isSubmitting     = false;

  XFile?     _pickedFile;
  Uint8List? _imageBytes;

  final _roomController       = TextEditingController();
  final _eventNameController  = TextEditingController();
  final _eventDescController  = TextEditingController();
  final _eventLinksController = TextEditingController();

  late final List<DateTime> _days;
  int  _selectedDayIndex = 0;
  int  _selectedHour     = 9;
  int  _selectedMinute   = 0;
  bool _isAM             = true;

  int  _endHour   = 10;
  int  _endMinute = 0;
  bool _endIsAM   = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(30, (i) => today.add(Duration(days: i)));
  }

  @override
  void dispose() {
    _roomController.dispose();
    _eventNameController.dispose();
    _eventDescController.dispose();
    _eventLinksController.dispose();
    super.dispose();
  }

  TimeOfDay _toTimeOfDay(int hour12, int minute, bool isAM) {
    int hour24 = hour12 % 12;
    if (!isAM) hour24 += 12;
    return TimeOfDay(hour: hour24, minute: minute);
  }

  String _dayLabel(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${names[d.weekday - 1]} ${months[d.month - 1]} ${d.day}';
  }

  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) return;
    final bytes = kIsWeb ? await picked.readAsBytes() : null;
    setState(() {
      _pickedFile = picked;
      _imageBytes = bytes;
    });
  }

  void _removeImage() => setState(() {
        _pickedFile = null;
        _imageBytes = null;
      });

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (_eventNameController.text.trim().isEmpty) {
      _showError('Please enter an Event Name.');
      return;
    }
    if (_selectedBuildingCode == null) {
      _showError('Please select a Building Location.');
      return;
    }

    // ── Profanity check ───────────────────────────────────────────────
    if (ModerationHelper.containsProfanity(_eventNameController.text) ||
        ModerationHelper.containsProfanity(_eventDescController.text)) {
      _showError('Your event contains inappropriate language. Please revise.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_pickedFile != null) {
        if (kIsWeb) {
          imageUrl = await EBCloudinaryService.uploadImageBytes(
            _imageBytes!,
            _pickedFile!.name,
          );
        } else {
          imageUrl = await EBCloudinaryService.uploadImage(
            File(_pickedFile!.path),
          );
        }
      }

      final selectedDay = _days[_selectedDayIndex];
      final buildings = await EBServices.fetchBuildings();
      final building = buildings.firstWhere(
        (b) => b['code'] == _selectedBuildingCode,
        orElse: () => {'code': _selectedBuildingCode!, 'name': _selectedBuildingName ?? _selectedBuildingCode!},
      );
      final locationDisplay = building['code']!.isEmpty
          ? building['name']!
          : '${building['name']}';

      final event = EBEvent(
        id: '',
        title: _eventNameController.text.trim(),
        location: locationDisplay,
        buildingCode: _selectedBuildingCode!,
        roomNumber: _roomController.text.trim(),
        date: selectedDay,
        startTime: _toTimeOfDay(_selectedHour, _selectedMinute, _isAM),
        endTime: _isAllDay
            ? null
            : _toTimeOfDay(_endHour, _endMinute, _endIsAM),
        isAllDay: _isAllDay,
        description: _eventDescController.text.trim(),
        links: _eventLinksController.text.trim(),
        category: _selectedCategory,
        imageUrl: imageUrl,
      );

      await EBServices.addEvent(event);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Event submitted!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showError('Failed to submit event. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/lb_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildFormHeader(),
                    const SizedBox(height: 16),
                    _buildDateTimePicker(),
                    const SizedBox(height: 16),
                    _buildAllDayToggle(),
                    const SizedBox(height: 20),
                    _buildBuildingDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Room Number',
                      hint: 'Enter Room Number',
                      controller: _roomController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Event Name',
                      hint: 'Enter Event Name',
                      controller: _eventNameController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Event Description',
                      hint: 'Enter Event Description',
                      controller: _eventDescController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Event Links',
                      hint: 'Enter Event Links',
                      controller: _eventLinksController,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: kYellow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9D6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Event Board',
                    style: TextStyle(fontSize: 15, color: Color(0xFF555555)),
                  ),
                  Text(
                    '›',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kBg,
                border: Border.all(color: const Color(0xFFD8D8D8), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_outlined, size: 24, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Add Event Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            EBCategorySelector(
              selected: _selectedCategory,
              onChanged: (cat) => setState(() => _selectedCategory = cat),
              dotSize: 14,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    final hours   = List.generate(12, (i) => i + 1);
    final minutes = List.generate(60, (i) => i);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              'Start',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _pickerCol(
                    items: _days.map(_dayLabel).toList(),
                    initialIndex: _selectedDayIndex,
                    onChanged: (i) => setState(() => _selectedDayIndex = i),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _pickerCol(
                    items: hours.map((h) => h.toString()).toList(),
                    initialIndex: hours.indexOf(_selectedHour),
                    onChanged: (i) => setState(() => _selectedHour = hours[i]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _pickerCol(
                    items: minutes.map((m) => m.toString().padLeft(2, '0')).toList(),
                    initialIndex: _selectedMinute,
                    onChanged: (i) => setState(() => _selectedMinute = i),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _pickerCol(
                    items: const ['AM', 'PM'],
                    initialIndex: _isAM ? 0 : 1,
                    onChanged: (i) => setState(() => _isAM = i == 0),
                  ),
                ),
              ],
            ),
          ),
          if (!_isAllDay) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                'End',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  const Expanded(flex: 5, child: SizedBox()),
                  Expanded(
                    flex: 2,
                    child: _pickerCol(
                      items: hours.map((h) => h.toString()).toList(),
                      initialIndex: hours.indexOf(_endHour),
                      onChanged: (i) => setState(() => _endHour = hours[i]),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _pickerCol(
                      items: minutes.map((m) => m.toString().padLeft(2, '0')).toList(),
                      initialIndex: _endMinute,
                      onChanged: (i) => setState(() => _endMinute = i),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _pickerCol(
                      items: const ['AM', 'PM'],
                      initialIndex: _endIsAM ? 0 : 1,
                      onChanged: (i) => setState(() => _endIsAM = i == 0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pickerCol({
    required List<String> items,
    required int initialIndex,
    required ValueChanged<int> onChanged,
  }) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: initialIndex),
      itemExtent: 36,
      onSelectedItemChanged: onChanged,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF888888).withOpacity(0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF888888), width: 1.5),
        ),
      ),
      children: items
          .map(
            (item) => Center(
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAllDayToggle() {
    return Row(
      children: [
        const Text(
          'All-Day Event',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Switch(
          value: _isAllDay,
          activeColor: kYellow,
          onChanged: (v) => setState(() => _isAllDay = v),
        ),
      ],
    );
  }

  Widget _buildBuildingDropdown() {
    return FutureBuilder<List<Map<String, String>>>(
      future: EBServices.fetchBuildings(),
      builder: (context, snap) {
        final buildings = snap.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Building Location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Autocomplete<Map<String, String>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return buildings;
                final query = textEditingValue.text.toLowerCase();
                return buildings.where((b) =>
                  b['name']!.toLowerCase().contains(query) ||
                  b['code']!.toLowerCase().contains(query),
                );
              },
              displayStringForOption: (b) => b['code']!.isEmpty
                  ? b['name']!
                  : '${b['code']} – ${b['name']}',
              onSelected: (b) {
                setState(() {
                  _selectedBuildingCode = b['code'];
                  _selectedBuildingName = b['name'];
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD8D8D8), width: 1.5),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Search building or abbreviation...',
                      hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final b = options.elementAt(index);
                          final display = b['code']!.isEmpty
                              ? b['name']!
                              : '${b['code']} – ${b['name']}';
                          return ListTile(
                            title: Text(display,
                                style: const TextStyle(fontSize: 14)),
                            onTap: () => onSelected(b),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD8D8D8), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD8D8D8), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kPurple, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _pickedFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Image (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 6,
              child: kIsWeb
                  ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                  : Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Change Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFD8D8D8), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8D8D8), width: 1.5),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: Colors.black45),
                  SizedBox(height: 8),
                  Text(
                    'Tap to add an image',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFD8D8D8), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kYellowBtn,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black54,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}