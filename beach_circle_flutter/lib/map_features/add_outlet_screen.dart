import 'package:flutter/material.dart';
import 'outlet_service.dart';

class AddOutletScreen extends StatefulWidget {
  const AddOutletScreen({super.key});

  @override
  State<AddOutletScreen> createState() => _AddOutletScreenState();
}

class _AddOutletScreenState extends State<AddOutletScreen> {
  final OutletService _outletService = OutletService();
  final TextEditingController _roomController = TextEditingController();

  late Future<List<Map<String, String>>> _buildingsFuture;

  String? _selectedBuildingId;
  String? _selectedBuildingCode;
  String? _selectedBuildingName;

  int _outletCount = 1;

  final List<String> _allOutletTypes = [
    '🧱 Wall Outlet',
    '⬇️ Floor Outlet',
    '🪛 Built-In Outlet',
    '🪑 Table Outlet',
    '🔌 Power Strip Nearby',
  ];

  final List<String> _allAccessibilityLevels = [
    '✅ Easy Access',
    '⚠️ Hard To Reach',
    '🚧 Obstruction',
  ];

  final List<String> _selectedOutletTypes = [];
  final List<String> _selectedAccessibilityLevels = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _buildingsFuture = _outletService.fetchBuildings();
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _toggleFromList(List<String> targetList, String value) {
    setState(() {
      if (targetList.contains(value)) {
        targetList.remove(value);
      } else {
        targetList.add(value);
      }
    });
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

  Widget _buildBuildingSearch(List<Map<String, String>> buildings) {
    return Autocomplete<Map<String, String>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return buildings;
        }

        final query = textEditingValue.text.toLowerCase();

        return buildings.where((b) {
          final code = (b['code'] ?? '').toLowerCase();
          final name = (b['name'] ?? '').toLowerCase();
          return code.contains(query) || name.contains(query);
        });
      },
      displayStringForOption: (b) {
        final code = b['code'] ?? '';
        final name = b['name'] ?? '';
        return code.isEmpty ? name : '$code - $name';
      },
      onSelected: (b) {
        setState(() {
          _selectedBuildingId = b['id'];
          _selectedBuildingCode = b['code'];
          _selectedBuildingName = b['name'];
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        if (_selectedBuildingCode != null && controller.text.isEmpty) {
          final code = _selectedBuildingCode ?? '';
          final name = _selectedBuildingName ?? '';
          controller.text = code.isEmpty ? name : '$code - $name';
        }

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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search, color: Colors.grey),
            ),
            onChanged: (_) {
              if (_selectedBuildingId != null) {
                setState(() {
                  _selectedBuildingId = null;
                  _selectedBuildingCode = null;
                  _selectedBuildingName = null;
                });
              }
            },
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
                  final code = b['code'] ?? '';
                  final name = b['name'] ?? '';
                  final display = code.isEmpty ? name : '$code - $name';

                  return ListTile(
                    title: Text(display, style: const TextStyle(fontSize: 14)),
                    onTap: () => onSelected(b),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final roomNumber = _roomController.text.trim();

    if (_selectedBuildingId == null ||
        _selectedBuildingCode == null ||
        _selectedBuildingName == null ||
        roomNumber.isEmpty ||
        _selectedOutletTypes.isEmpty ||
        _selectedAccessibilityLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out the required fields.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _outletService.addOutlet(
        buildingId: _selectedBuildingId!,
        buildingCode: _selectedBuildingCode!,
        buildingName: _selectedBuildingName!,
        roomNumber: roomNumber,
        outletCount: _outletCount,
        outletTypes: _selectedOutletTypes,
        accessibilityLevels: _selectedAccessibilityLevels,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outlet details added successfully.')),
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

  Widget _buildChipWrap(List<String> items, void Function(String) onDelete) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) {
            return Chip(label: Text(item), onDeleted: () => onDelete(item));
          }).toList(),
    );
  }

  Widget _buildCheckboxList(
    List<String> options,
    List<String> selected,
    void Function(String) onTap,
  ) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          children:
              options.map((option) {
                return CheckboxListTile(
                  value: selected.contains(option),
                  onChanged: (_) => onTap(option),
                  title: Text(option),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Outlet Details'),
        backgroundColor: const Color(0xFFF2D21B),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: FutureBuilder<List<Map<String, String>>>(
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
                    Icon(Icons.power_outlined, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Add Outlet Details',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Building Location'),
                _buildBuildingSearch(buildings),
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

                _buildSectionLabel('Number of Outlets'),
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _outletCount > 1
                              ? () {
                                setState(() {
                                  _outletCount--;
                                });
                              }
                              : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_outletCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _outletCount++;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Outlet Type'),
                if (_selectedOutletTypes.isNotEmpty)
                  _buildChipWrap(
                    _selectedOutletTypes,
                    (item) => _toggleFromList(_selectedOutletTypes, item),
                  ),
                if (_selectedOutletTypes.isNotEmpty) const SizedBox(height: 10),
                _buildCheckboxList(
                  _allOutletTypes,
                  _selectedOutletTypes,
                  (item) => _toggleFromList(_selectedOutletTypes, item),
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Accessibility Level'),
                if (_selectedAccessibilityLevels.isNotEmpty)
                  _buildChipWrap(
                    _selectedAccessibilityLevels,
                    (item) =>
                        _toggleFromList(_selectedAccessibilityLevels, item),
                  ),
                if (_selectedAccessibilityLevels.isNotEmpty)
                  const SizedBox(height: 10),
                _buildCheckboxList(
                  _allAccessibilityLevels,
                  _selectedAccessibilityLevels,
                  (item) => _toggleFromList(_selectedAccessibilityLevels, item),
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
