import 'package:flutter/material.dart';
import 'study_hall_service.dart';

class AddStudyHallScreen extends StatefulWidget {
  const AddStudyHallScreen({super.key});

  @override
  State<AddStudyHallScreen> createState() => _AddStudyHallScreenState();
}

class _AddStudyHallScreenState extends State<AddStudyHallScreen> {
  final StudyHallService _studyHallService = StudyHallService();
  final TextEditingController _roomController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _buildingsFuture;

  final List<String> _allAmenities = [
    'Outlets',
    'Open Lab',
    'Projector',
    'Printer',
    'Quiet Zone',
  ];

  Map<String, dynamic>? _selectedBuilding;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _seatCapacity = 15;
  final List<String> _selectedAmenities = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _buildingsFuture = _studyHallService.fetchBuildings();
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          isStart
              ? (_startTime ?? const TimeOfDay(hour: 10, minute: 30))
              : (_endTime ?? const TimeOfDay(hour: 14, minute: 0)),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  Future<void> _submit() async {
    final roomNumber = _roomController.text.trim();

    if (_selectedBuilding == null ||
        roomNumber.isEmpty ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out the required fields.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _studyHallService.addStudyHall(
        buildingId: _selectedBuilding!['id'],
        buildingAbbrev: _selectedBuilding!['abbrev'],
        roomNumber: roomNumber,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        seatCapacity: _seatCapacity,
        amenities: _selectedAmenities,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study hall added successfully.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value == null ? label : _formatTime(value),
                style: TextStyle(
                  fontSize: 16,
                  color: value == null ? Colors.grey.shade600 : Colors.black,
                ),
              ),
              const Icon(Icons.access_time, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Study Hall'),
        backgroundColor: const Color(0xFFF2D21B),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _buildingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load buildings.'));
          }

          final buildings = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Add Study Hall',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Building Location'),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedBuilding,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: InputDecoration(
                    hintText: 'Select Building',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                      buildings.map((building) {
                        final abbrev = building['abbrev'] ?? '';
                        final name = building['name'] ?? '';
                        final label =
                            name.toString().isNotEmpty
                                ? '$abbrev - $name'
                                : abbrev.toString();

                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: building,
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                  selectedItemBuilder: (context) {
                    return buildings.map((building) {
                      final abbrev = building['abbrev'] ?? '';
                      final name = building['name'] ?? '';
                      final label =
                          name.toString().isNotEmpty
                              ? '$abbrev - $name'
                              : abbrev.toString();

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList();
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedBuilding = value;
                    });
                  },
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Room Number'),
                TextField(
                  controller: _roomController,
                  decoration: InputDecoration(
                    hintText: 'Enter Room Number',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Availability Hours'),
                Row(
                  children: [
                    _buildTimeButton(
                      label: 'Start Time',
                      value: _startTime,
                      onTap: () => _pickTime(isStart: true),
                    ),
                    const SizedBox(width: 12),
                    const Text('to', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    _buildTimeButton(
                      label: 'End Time',
                      value: _endTime,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Seat Capacity'),
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _seatCapacity > 1
                              ? () {
                                setState(() {
                                  _seatCapacity--;
                                });
                              }
                              : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_seatCapacity',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _seatCapacity++;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Amenities'),
                if (_selectedAmenities.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedAmenities.map((amenity) {
                          return Chip(
                            label: Text(amenity),
                            onDeleted: () => _toggleAmenity(amenity),
                          );
                        }).toList(),
                  ),
                if (_selectedAmenities.isNotEmpty) const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children:
                        _allAmenities.map((amenity) {
                          return CheckboxListTile(
                            value: _selectedAmenities.contains(amenity),
                            onChanged: (_) => _toggleAmenity(amenity),
                            title: Text(amenity),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4C400),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
