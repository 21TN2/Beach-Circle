import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BathroomFinder extends StatefulWidget {
  const BathroomFinder({super.key});

  @override
  State<BathroomFinder> createState() => _BathroomFinderState();
}

class _BathroomFinderState extends State<BathroomFinder> {
  // STATE VARIABLES
  int _selectedRating = 0;
  String _selectedBathroom = "";
  bool _isLoading = false;

  List<String> _bathroomOptions = []; // Will hold the auto generated list

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

  @override
  void initState() {
    super.initState();
    _loadBathroomsFromFile();
  }

  // HELPER Converts numbers to 1st 2nd 3rd 4th
  String _getOrdinal(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) return '${number}th';
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  // READ AND AUTO GENERATE FROM TEXT FILE
  Future<void> _loadBathroomsFromFile() async {
    try {
      final String fileText = await rootBundle.loadString(
        'assets/bathrooms.txt',
      );
      final List<String> lines = fileText.split('\n');

      List<String> generatedList = [];

      for (String line in lines) {
        if (line.trim().isEmpty) continue;

        // New format Name | Abbrev | Floors
        final parts = line.split('|');

        if (parts.length >= 3) {
          String name = parts[0].trim();
          String abbrev = parts[1].trim();
          int? floors = int.tryParse(parts[2].trim());

          String buildingDisplay = abbrev != 'None' ? "$name ($abbrev)" : name;

          if (floors != null && floors > 0) {
            // Auto generate the floors AND the gender types
            for (int i = 1; i <= floors; i++) {
              String baseName = "$buildingDisplay - ${_getOrdinal(i)} Floor";
              generatedList.add("$baseName - Men's");
              generatedList.add("$baseName - Women's");
              generatedList.add("$baseName - Gender Neutral");
            }
          } else {
            // Fallback if the number is not readable
            generatedList.add("$buildingDisplay - Men's");
            generatedList.add("$buildingDisplay - Women's");
            generatedList.add("$buildingDisplay - Gender Neutral");
          }
        } else if (parts.isNotEmpty) {
          // Fallback for lines without pipes
          String buildingDisplay = parts[0].trim();
          generatedList.add("$buildingDisplay - Men's");
          generatedList.add("$buildingDisplay - Women's");
          generatedList.add("$buildingDisplay - Gender Neutral");
        }
      }

      setState(() {
        _bathroomOptions = generatedList;
      });
    } catch (e) {
      debugPrint("Error loading bathrooms file: $e");
    }
  }

  // FIREBASE SUBMIT LOGIC
  Future<void> _submitReview() async {
    if (_selectedBathroom.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or type a bathroom name.")),
      );
      return;
    }
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a star rating.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final reviewData = {
        'bathroomName': _selectedBathroom.trim(),
        'rating': _selectedRating,
        'features': _features,
        'comments': _commentController.text.trim(),
        'userId': user?.uid ?? 'anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('bathroom_reviews')
          .add(reviewData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review Submitted Successfully")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error submitting review: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    child: const Icon(
                      Icons.wc,
                      size: 30,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Add Bathroom Review",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // SEARCH BAR
              const Text(
                "Search for a Bathroom",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _bathroomOptions.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _selectedBathroom = selection;
                },
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onEditingComplete,
                ) {
                  controller.addListener(() {
                    _selectedBathroom = controller.text;
                  });
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText:
                          _bathroomOptions.isEmpty
                              ? "Loading buildings"
                              : "Example: ECS - 1st Floor - Men's",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: controller.clear,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // OVERALL RATING
              const Text(
                "Overall Rating",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
              const Text(
                "Click to Rate",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),

              const SizedBox(height: 25),

              // BATHROOM DETAILS CHECKBOXES
              const Text(
                "Bathroom Details",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _features.entries.where((e) => e.value).map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(e.key),
                            backgroundColor: Colors.white,
                            shape: const StadiumBorder(
                              side: BorderSide(color: Colors.grey),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted:
                                () => setState(() => _features[e.key] = false),
                          ),
                        );
                      }).toList(),
                ),
              ),

              const SizedBox(height: 5),

              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    children:
                        _features.keys.map((String key) {
                          return CheckboxListTile(
                            title: Text(key),
                            value: _features[key],
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            activeColor: Colors.purple,
                            onChanged: (bool? value) {
                              setState(() {
                                _features[key] = value ?? false;
                              });
                            },
                          );
                        }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // COMMENTS
              const Text(
                "Comments",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add any extra details",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 30),

              // BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4D600),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "Submit",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
