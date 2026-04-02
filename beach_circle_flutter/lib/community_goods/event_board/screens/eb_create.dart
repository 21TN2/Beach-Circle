// eb_create.dart
// Create event screen for Event Board

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:beach_circle_flutter/community_goods/event_board/models/eb_event.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/eb_services.dart';
import 'package:beach_circle_flutter/community_goods/event_board/widgets/eb_category_dot.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/eb_cloudinary.dart';

class EBCreatePage extends StatefulWidget {
  const EBCreatePage({super.key});

  @override
  State<EBCreatePage> createState() => _EBCreatePageState();
}

class _EBCreatePageState extends State<EBCreatePage> {
  static const Color kYellow  = Color(0xFFFFCC00);
  static const Color kPurple  = Color(0xFF3B3599);
  static const Color kGold    = Color(0xFFD1A000);

  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _linksCtrl      = TextEditingController();
  final _roomCtrl       = TextEditingController();

  EBCategory _category  = EBCategory.sports;
  DateTime   _date      = DateTime.now();
  TimeOfDay  _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _endTime;
  bool       _isAllDay  = false;

  String?    _selectedBuildingCode;
  String?    _selectedBuildingName;
  List<Map<String, String>> _buildings = [];
  bool       _loadingBuildings = true;

  // Image state
  File?      _imageFile;
  Uint8List? _imageBytes;
  String?    _uploadedImageUrl;
  bool       _uploadingImage = false;
  bool       _submitting     = false;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _linksCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    final list = await EBServices.fetchBuildings();
    if (mounted) setState(() { _buildings = list; _loadingBuildings = false; });
  }

  // ── Date / time pickers ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingImage = true);

    try {
      String? url;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
        url = await EBCloudinaryService.uploadImageBytes(bytes, picked.name);
      } else {
        final file = File(picked.path);
        setState(() => _imageFile = file);
        url = await EBCloudinaryService.uploadImage(file);
      }
      setState(() => _uploadedImageUrl = url);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBuildingCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a building.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final event = EBEvent(
        id: '',
        title: _nameCtrl.text.trim(),
        location: _selectedBuildingName ?? _selectedBuildingCode ?? '',
        buildingCode: _selectedBuildingCode ?? '',
        roomNumber: _roomCtrl.text.trim(),
        date: _date,
        startTime: _startTime,
        endTime: _isAllDay ? null : _endTime,
        isAllDay: _isAllDay,
        description: _descCtrl.text.trim(),
        links: _linksCtrl.text.trim(),
        category: _category,
        imageUrl: _uploadedImageUrl,
      );

      await EBServices.addEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event submitted!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: kYellow,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        titleSpacing: 12,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Event Board',
                        style: TextStyle(color: Color(0xFF555555), fontSize: 15),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: kPurple),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.home_outlined, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Add Event Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  EBCategorySelector(
                    selected: _category,
                    onChanged: (cat) => setState(() => _category = cat),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Date picker ──────────────────────────────────────────────
              _SectionLabel('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: _PickerBox(label: _fmtDate(_date)),
              ),

              const SizedBox(height: 16),

              // ── All-Day toggle ───────────────────────────────────────────
              Row(
                children: [
                  const Text('All-Day',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Switch(
                    value: _isAllDay,
                    activeColor: kYellow,
                    onChanged: (v) => setState(() => _isAllDay = v),
                  ),
                ],
              ),

              if (!_isAllDay) ...[
                const SizedBox(height: 16),
                _SectionLabel('Start Time'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickStartTime,
                  child: _PickerBox(label: _fmtTime(_startTime)),
                ),
                const SizedBox(height: 16),
                _SectionLabel('End Time (optional)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickEndTime,
                  child: _PickerBox(
                    label: _endTime == null ? 'Tap to set' : _fmtTime(_endTime!),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Building location ────────────────────────────────────────
              _SectionLabel('Building Location'),
              const SizedBox(height: 8),
              _loadingBuildings
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: _selectedBuildingCode,
                      decoration: _inputDecoration('Select Building'),
                      items: _buildings.map((b) {
                        return DropdownMenuItem(
                          value: b['code'],
                          child: Text('${b['code']} – ${b['name']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final match = _buildings.firstWhere(
                          (b) => b['code'] == val,
                          orElse: () => {'code': val ?? '', 'name': val ?? ''},
                        );
                        setState(() {
                          _selectedBuildingCode = val;
                          _selectedBuildingName = match['name'];
                        });
                      },
                    ),

              const SizedBox(height: 16),

              // ── Room number ──────────────────────────────────────────────
              _SectionLabel('Room Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _roomCtrl,
                decoration: _inputDecoration('Enter Room Number'),
              ),

              const SizedBox(height: 16),

              // ── Event name ───────────────────────────────────────────────
              _SectionLabel('Event Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration('Enter Event Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // ── Description ──────────────────────────────────────────────
              _SectionLabel('Event Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: _inputDecoration('Enter Event Description'),
                maxLines: 4,
              ),

              const SizedBox(height: 16),

              // ── Links ────────────────────────────────────────────────────
              _SectionLabel('Event Links'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _linksCtrl,
                decoration: _inputDecoration('Enter Event Links'),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),

              // ── Image upload ─────────────────────────────────────────────
              _SectionLabel('Event Image (optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _uploadingImage ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD0D0D0)),
                  ),
                  child: _uploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : (_imageBytes != null || _imageFile != null)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                  : Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 36, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to add image',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Cancel / Submit ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kYellow,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Text('Submit',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1A000), width: 1.5),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}

class _PickerBox extends StatelessWidget {
  final String label;
  const _PickerBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D0D0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const Icon(Icons.expand_more, color: Colors.black54),
        ],
      ),
    );
  }
}