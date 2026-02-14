import 'package:flutter/material.dart';

class BathroomFinder extends StatefulWidget {
  const BathroomFinder({super.key});

  @override
  State<BathroomFinder> createState() => _BathroomFinderState();
}

class _BathroomFinderState extends State<BathroomFinder> {
  // --- STATE VARIABLES ---
  int _selectedRating = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  // List of features to check
  final Map<String, bool> _features = {
    'Accessible': false,
    'Baby Station': false,
    'Clean': false,
    'Crowded': false,
    'Dirty': false,
    'Gender Neutral': false,
    'Menstrual Products': false,
  };

  // Mock list for search suggestions
  final List<String> _bathroomOptions = [
    "ECS First Floor - Women's",
    "ECS First Floor - Men's",
    "HC - Gender Neutral",
    "Library 2nd Floor - Women's",
    "USU 1st Floor - Family",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Custom App Bar Area
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    child: const Icon(Icons.wc, size: 30, color: Colors.black87),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Add Bathroom Review",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // --- SEARCH BAR ---
              const Text("Search for a Bathroom", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _bathroomOptions.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                        onPressed: controller.clear,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25), // Rounded pill shape
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(25),
                         borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // --- OVERALL RATING ---
              const Text("Overall Rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
              const Text("Click to Rate", style: TextStyle(color: Colors.black54, fontSize: 12)),

              const SizedBox(height: 25),

              // --- BATHROOM DETAILS (CHECKBOXES) ---
              const Text("Bathroom Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              
              // Feature Chips Row (Optional Visual)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _features.entries.where((e) => e.value).map((e) {
                     return Padding(
                       padding: const EdgeInsets.only(right: 8.0),
                       child: Chip(
                         label: Text(e.key),
                         backgroundColor: Colors.white,
                         shape: const StadiumBorder(side: BorderSide(color: Colors.grey)),
                         deleteIcon: const Icon(Icons.close, size: 18),
                         onDeleted: () => setState(() => _features[e.key] = false),
                       ),
                     );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 5),

              // Scrollable Checkbox List Container
              Container(
                height: 200, // Fixed height for scrolling
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    children: _features.keys.map((String key) {
                      return CheckboxListTile(
                        title: Text(key),
                        value: _features[key],
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: Colors.purple, // Match your screenshot accent
                        onChanged: (bool? value) {
                          setState(() {
                            _features[key] = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // --- COMMENTS ---
              const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "Example: Private Stalls",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 30),

              // --- BUTTONS ---
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Submit Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Submit Logic Here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Review Submitted!")),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4D600), // Yellow/Green from screenshot
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Submit", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}