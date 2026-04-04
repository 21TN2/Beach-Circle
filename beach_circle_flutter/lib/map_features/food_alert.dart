import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//class for food alert creation 
class CreateFoodAlertSheet extends StatefulWidget {
  final Position pinPosition;
  final VoidCallback onClose;
  final VoidCallback onSubmitted;

  const CreateFoodAlertSheet({super.key, 
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
  // food tag controller here
  bool _isSubmitting = false;

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

          //food alert tag stuff here

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


//bottom sheet for food alert
class FoodAlertSheetContent extends StatelessWidget {
  const FoodAlertSheetContent({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('food_alerts')
              .where('active', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Error
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Could not load food alerts.'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
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

            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Text(
                  'No active food alerts right now.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            if (docs.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                itemCount: docs.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(color: Colors.grey.shade200, height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final title = (data['title'] ?? 'Untitled').toString();
                  final description = (data['description'] ?? '').toString();

                  // Format timestamp if available
                  String timeStr = '';
                  final ts = data['createdAt'];
                  if (ts is Timestamp) {
                    final dt = ts.toDate();
                    final diff = DateTime.now().difference(dt);
                    if (diff.inMinutes < 60) {
                      timeStr = '${diff.inMinutes}m ago';
                    } else if (diff.inHours < 24) {
                      timeStr = '${diff.inHours}h ago';
                    } else {
                      timeStr = '${diff.inDays}d ago';
                    }
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 2,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F0FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pin_drop,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      timeStr.isNotEmpty
                          ? '$description · $timeStr'
                          : description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // TODO: fly map camera to pin location
                      // final lat = data['lat'], lng = data['lng'];
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