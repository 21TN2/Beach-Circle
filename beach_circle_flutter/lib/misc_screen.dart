import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// to do: change off-campus resource image

class MiscScreen extends StatefulWidget {
  const MiscScreen({super.key});

  @override
  State<MiscScreen> createState() => _MiscScreenState();
}

class _MiscScreenState extends State<MiscScreen> {
  bool isInterested = false;

  // forum categories
  final List<_Category> categories = const [
    _Category("Lost & Found", "assets/forum/lost_found.jpg"),
    _Category("Clubs", "assets/forum/clubs.jpg"),
    _Category("Concerns", "assets/forum/concerns.jpg"),
    _Category("Community\nChat", "assets/forum/community_chat.jpg"),
    _Category("Major\nQ&A", "assets/forum/major_qa.jpg"),
    _Category("Help", "assets/forum/help.jpg"),
    _Category("Campus\nResources", "assets/forum/campus_resources.jpg"),
    _Category("Off-Campus\nActivities", "assets/forum/longbeach.jpg"),
  ];

  late List<bool> starred;

  // firebase storage
  DocumentReference<Map<String, dynamic>> _prefsRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('forum')
        .doc('misc');
  }

  // loads the saved interested
  @override
  void initState() {
    super.initState();
    starred = List<bool>.filled(categories.length, false);
    _loadPrefs();
  }

  // for starred categories
  Future<void> _loadPrefs() async {
    final snap = await _prefsRef().get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final savedInterested = data['interested'];
    final savedStars = data['starredCategories'];

    setState(() {
      if (savedInterested is bool) isInterested = savedInterested;

      if (savedStars is List) {
        // converts dynamic list into bool list
        final list = savedStars.map((e) => e == true).toList();

        // checking if it matches the number of categories
        starred = List<bool>.generate(
          categories.length,
          (i) => i < list.length ? list[i] : false,
        );
      }
    });
  }

  Future<void> _savePrefs() async {
    await _prefsRef().set({
      'interested': isInterested,
      'starredCategories': starred,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // list based on users starred as interested
  List<int> _visibleCategoryIndexes() {
    if (!isInterested) {
      // show everything
      return List<int>.generate(categories.length, (i) => i);
    }

    // show only starred
    final onlyStarred = <int>[];
    for (int i = 0; i < starred.length; i++) {
      if (starred[i]) onlyStarred.add(i);
    }
    return onlyStarred;
  }

  @override
  Widget build(BuildContext context) {
    final visibleIndexes = _visibleCategoryIndexes();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFFFD500),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(child: _HeaderPill()),
                  const SizedBox(width: 10),

                  // Interested button
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isInterested = !isInterested;
                      });
                      await _savePrefs();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isInterested
                                ? const Color(0xFFFFC107)
                                : const Color(0xFFE59A00),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isInterested ? Icons.star : Icons.star_border,
                            size: 18,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Interested",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child:
                    visibleIndexes.isEmpty
                        ? const Center(
                          // case: if there's no starred categories yet
                          child: Text(
                            "No starred categories yet.\nStar a category first ",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : GridView.builder(
                          itemCount: visibleIndexes.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.05,
                              ),
                          itemBuilder: (context, gridIndex) {
                            final categoryIndex = visibleIndexes[gridIndex];

                            return _CategoryCard(
                              title: categories[categoryIndex].title,
                              imagePath: categories[categoryIndex].imagePath,
                              isStarred: starred[categoryIndex],
                              onStarTap: () async {
                                setState(() {
                                  starred[categoryIndex] =
                                      !starred[categoryIndex];
                                });
                                await _savePrefs();
                              },
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------- header -----------
class _HeaderPill extends StatelessWidget {
  const _HeaderPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              "Student Miscellaneous Forum",
              style: TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

// ---------- forum categories ----------
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.imagePath,
    required this.isStarred,
    required this.onStarTap,
  });

  final String title;
  final String imagePath;
  final bool isStarred;
  final VoidCallback onStarTap;

  // image & text cover
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(color: const Color(0xFFE0E0E0)),
            ),
          ),

          // Dark overlay so text pops
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),

          // Star icon
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onStarTap,
              child: Icon(
                isStarred ? Icons.star : Icons.star_border,
                color: Colors.black,
              ),
            ),
          ),

          // Center text
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Category {
  final String title;
  final String imagePath;
  const _Category(this.title, this.imagePath);
}
