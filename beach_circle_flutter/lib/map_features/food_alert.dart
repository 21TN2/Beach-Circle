import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//in production restrict amount of food alerts made per user

// Constants
const Duration _kFoodAlertActiveDuration = Duration(hours: 5);
const Duration _kFoodAlertDeleteDuration = Duration(hours: 24);

// Helper: compute whether a food alert is still active based on age + flag
bool isFoodAlertActive(Timestamp? createdAt, bool storedActive) {
  if (!storedActive) return false;
  if (createdAt == null) return storedActive;
  final age = DateTime.now().difference(createdAt.toDate());
  return age < _kFoodAlertActiveDuration;
}

//class for food alert creation
class CreateFoodAlertSheet extends StatefulWidget {
  final Position pinPosition;
  final VoidCallback onClose;
  final VoidCallback onSubmitted;

  const CreateFoodAlertSheet({
    super.key,
    required this.pinPosition,
    required this.onClose,
    required this.onSubmitted,
  });

  @override
  State<CreateFoodAlertSheet> createState() => CreateFoodAlertSheetState();
}

//class to the actual food alert creation
class CreateFoodAlertSheetState extends State<CreateFoodAlertSheet> {
  //controlers and states for the stuff on the screen
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _foodTagOptions = [
    'Vegan',
    'Vegetarian',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Halal',
    'Kosher',
    'Healthy',
    'Sweets',
    'Savory',
    'Drinks',
    'Snacks',
  ];
  final List<String> _selectedFoodTags = [];
  bool _isSubmitting = false;

  // NEW FROM GISELLE: to toggle food tag options
  void _toggleFoodTag(String tag) {
    setState(() {
      if (_selectedFoodTags.contains(tag)) {
        _selectedFoodTags.remove(tag);
      } else {
        _selectedFoodTags.add(tag);
      }
    });
  }

  // NEW FROM GISELLE: to pick differnt food options
  Future<void> _openFoodTagPicker() async {
    final tempSelected = List<String>.from(_selectedFoodTags);
    // check box for amentities
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Food Tags'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView(
                  shrinkWrap: true,
                  children:
                      _foodTagOptions.map((tag) {
                        return CheckboxListTile(
                          value: tempSelected.contains(tag),
                          onChanged: (_) {
                            setDialogState(() {
                              if (tempSelected.contains(tag)) {
                                tempSelected.remove(tag);
                              } else {
                                tempSelected.add(tag);
                              }
                            });
                          },
                          title: Text(tag),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                ),
              ),
              actions: [
                // if user wants to close box
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFoodTags
                        ..clear()
                        ..addAll(tempSelected);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  //submitting the food alert form details
  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      await FirebaseFirestore.instance.collection('food_alerts').add({
        'userId': user.uid,
        'title': title,
        'description': desc,
        'foodTags': _selectedFoodTags,
        'lat': widget.pinPosition.lat,
        'lng': widget.pinPosition.lng,
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      });
      debugPrint("User UID: ${user.uid}");

      widget.onSubmitted();
    } catch (e) {
      debugPrint('Error submitting food alert: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Create Food Alert",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Title field
          const Text(
            "Title (<50 characters)*",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: "Ex: Free sandwiches and cookies",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade100,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Description field
          const Text(
            "Description (<200 characters)*",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLength: 200,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  "Ex: Free food and snacks at the entrance of COB near Wall StreEat Cafe.",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade100,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),

          //food alert tag stuff here by GISELLE
          const Text(
            "Food Tags (Optional)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            // adds food tag option to page
            children: [
              OutlinedButton.icon(
                onPressed: _openFoodTagPicker,
                icon: const Icon(Icons.add),
                label: const Text('Add Food Tags'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedFoodTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _selectedFoodTags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _toggleFoodTag(tag),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.red.shade200,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        "Submit Alert",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// Detail page – full view of a food alert
// ---------------------------------------------------------------------------
class FoodAlertDetailPage extends StatelessWidget {
  final String docId;
  final String title;
  final String description;
  final bool isActive;
  final String timeStr;
  final String? currentUserId;
  final String alertUserId;
  final List<String> foodTags;

  const FoodAlertDetailPage({
    super.key,
    required this.docId,
    required this.title,
    required this.description,
    required this.isActive,
    required this.timeStr,
    required this.currentUserId,
    required this.alertUserId,
    this.foodTags = const [],
  });

  Future<void> _deactivate(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('food_alerts')
          .doc(docId)
          .update({'active': false});
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error deactivating food alert: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && currentUserId == alertUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Food Alert',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge + timestamp
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isActive
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),

            // Description label
            Text(
              'Description',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Full description text (no truncation)
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (foodTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        foodTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4EA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),

            const Spacer(),

            // Deactivate button – only for the alert's owner while active
            if (isOwner && isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deactivate(context),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text(
                    'Mark as Inactive',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

//select a food alert to view pin
typedef OnFoodAlertSelected = void Function(double lat, double lng);

//bottom sheet for food alert
class FoodAlertSheetContent extends StatefulWidget {
  final OnFoodAlertSelected? onAlertSelected;

  const FoodAlertSheetContent({super.key, this.onAlertSelected});

  @override
  State<FoodAlertSheetContent> createState() => _FoodAlertSheetContentState();
}

class _FoodAlertSheetContentState extends State<FoodAlertSheetContent> {
  // Track docs already scheduled for deletion to avoid duplicate calls.
  final Set<String> _scheduledForDelete = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Fetch all alerts ordered newest-first; we sort active/inactive in-app.
      stream:
          FirebaseFirestore.instance
              .collection('food_alerts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Could not load food alerts.'),
          );
        }

        final now = DateTime.now();
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final allDocs = snapshot.data?.docs ?? [];

        // ── auto-expire: mark active alerts older than 5 h as inactive ────
        for (final doc in allDocs) {
          final data = doc.data();
          final ts = data['createdAt'];
          if (data['active'] == true && ts is Timestamp) {
            final age = now.difference(ts.toDate());
            if (age >= _kFoodAlertActiveDuration) {
              FirebaseFirestore.instance
                  .collection('food_alerts')
                  .doc(doc.id)
                  .update({'active': false});
            }
          }
        }

        // ── auto-delete: remove inactive alerts older than 24 h ──────────
        for (final doc in allDocs) {
          if (_scheduledForDelete.contains(doc.id)) continue;

          final data = doc.data();
          final ts = data['createdAt'];
          final storedActive = data['active'] == true;

          if (!storedActive && ts is Timestamp) {
            final createdAt = ts.toDate();
            final age = now.difference(createdAt);

            if (age >= _kFoodAlertDeleteDuration) {
              _scheduledForDelete.add(doc.id);
              FirebaseFirestore.instance
                  .collection('food_alerts')
                  .doc(doc.id)
                  .delete();
            } else {
              final remaining = _kFoodAlertDeleteDuration - age;
              _scheduledForDelete.add(doc.id);

              Future.delayed(remaining, () {
                if (!mounted) return;

                FirebaseFirestore.instance
                    .collection('food_alerts')
                    .doc(doc.id)
                    .delete();
              });
            }
          }
        }
        // for (final doc in allDocs) {
        //   if (_scheduledForDelete.contains(doc.id)) continue;
        //   final data = doc.data();
        //   final ts = data['createdAt'];
        //   final storedActive = data['active'] == true;
        //   if (!storedActive && ts is Timestamp) {
        //     final age = now.difference(ts.toDate());
        //     if (age >= _kFoodAlertDeleteDuration) {
        //       // Already past threshold – delete immediately
        //       _scheduledForDelete.add(doc.id);
        //       FirebaseFirestore.instance
        //           .collection('food_alerts')
        //           .doc(doc.id)
        //           .delete();
        //     } else {
        //       // Schedule deletion for when it crosses 24 h
        //       final remaining = _kFoodAlertDeleteDuration - age;
        //       _scheduledForDelete.add(doc.id);
        //       Future.delayed(remaining, () {
        //         if (!mounted) return;
        //         FirebaseFirestore.instance
        //             .collection('food_alerts')
        //             .doc(doc.id)
        //             .delete();
        //       });
        //     }
        //   }
        // }

        // ── sort: active alerts first, then inactive ──────────────────────
        final activeDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final inactiveDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        for (final doc in allDocs) {
          final data = doc.data();
          final ts = data['createdAt'] as Timestamp?;
          final storedActive = data['active'] == true;
          if (isFoodAlertActive(ts, storedActive)) {
            activeDocs.add(doc);
          } else {
            inactiveDocs.add(doc);
          }
        }

        final displayDocs = [...activeDocs, ...inactiveDocs];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 0, bottom: 5),
              child: Text(
                "Food Alerts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            if (displayDocs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Text(
                  'No food alerts right now.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            if (displayDocs.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                itemCount: displayDocs.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(color: Colors.grey.shade200, height: 1),
                itemBuilder: (context, index) {
                  final doc = displayDocs[index];
                  final data = doc.data();
                  final title = (data['title'] ?? 'Untitled').toString();
                  final description = (data['description'] ?? '').toString();
                  final alertUserId = (data['userId'] ?? '').toString();
                  final foodTags = List<String>.from(data['foodTags'] ?? []);
                  final lat = (data['lat'] as num?)?.toDouble();
                  final lng = (data['lng'] as num?)?.toDouble();

                  // Live active status
                  final ts = data['createdAt'] as Timestamp?;
                  final storedActive = data['active'] == true;
                  final active = isFoodAlertActive(ts, storedActive);

                  // Format relative timestamp
                  String timeStr = '';
                  // if (ts != null) {
                  //   final dt = ts.toDate();
                  //   final diff = now.difference(dt);
                  //   if (diff.inMinutes < 60) {
                  //     timeStr = '${diff.inMinutes*-1}m ago';
                  //   } else if (diff.inHours < 24) {
                  //     timeStr = '${diff.inHours}h ago';
                  //   } else {
                  //     timeStr = '${diff.inDays}d ago';
                  //   }
                  // }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 2,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? const Color(0xFFFFEBEB)
                                : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pin_drop,
                        color: active ? Colors.red : Colors.grey,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color:
                                  active
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr.isNotEmpty
                                ? '$description · $timeStr'
                                : description,
                            style: TextStyle(
                              color:
                                  active
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (foodTags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  foodTags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF4EA),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.grey),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => FoodAlertDetailPage(
                                  docId: doc.id,
                                  title: title,
                                  description: description,
                                  isActive: active,
                                  timeStr: timeStr,
                                  currentUserId: currentUserId,
                                  alertUserId: alertUserId,
                                  foodTags: foodTags,
                                ),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // Fly map to active alert's pin
                      if (active &&
                          lat != null &&
                          lng != null &&
                          widget.onAlertSelected != null) {
                        widget.onAlertSelected!(lat, lng);
                      }
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
