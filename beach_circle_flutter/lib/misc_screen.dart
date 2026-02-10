// student misc forum home page
// TO DO: create a main page for each category ?
// imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MiscScreen extends StatefulWidget {
  const MiscScreen({super.key});

  @override
  State<MiscScreen> createState() => _MiscScreenState();
}

class _MiscScreenState extends State<MiscScreen> {
  bool isInterested = false;

  // starred category set up
  Set<String> starredCategoryIds = {};

  // default built-in forum categories
  final List<_CategoryItem> builtInCategories = const [
    _CategoryItem(
      id: "builtin:Lost & Found",
      title: "Lost & Found",
      imagePath: "assets/forum/lost_found.jpg",
    ),
    _CategoryItem(
      id: "builtin:Clubs",
      title: "Clubs",
      imagePath: "assets/forum/clubs.jpg",
    ),
    _CategoryItem(
      id: "builtin:Concerns",
      title: "Concerns",
      imagePath: "assets/forum/concerns.jpg",
    ),
    _CategoryItem(
      id: "builtin:Community Chat",
      title: "Community\nChat",
      imagePath: "assets/forum/community_chat.jpg",
    ),
    _CategoryItem(
      id: "builtin:Major Q&A",
      title: "Major\nQ&A",
      imagePath: "assets/forum/major_qa.jpg",
    ),
    _CategoryItem(
      id: "builtin:Help",
      title: "Help",
      imagePath: "assets/forum/help.jpg",
    ),
    _CategoryItem(
      id: "builtin:Campus Resources",
      title: "Campus\nResources",
      imagePath: "assets/forum/campus_resources.jpg",
    ),
    _CategoryItem(
      id: "builtin:Off-Campus Activities",
      title: "Off-Campus\nActivities",
      imagePath: "assets/forum/longbeach.jpg",
    ),
  ];

  // firebase storage
  DocumentReference<Map<String, dynamic>> _prefsRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('forum')
        .doc('misc');
  }

  // loading user categories pref
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // firebase saved starred state
  Future<void> _loadPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await _prefsRef().get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final savedInterested = data['interested'];
    final savedStarIds = data['starredCategoryIds'];

    //  setting state for starred categories
    setState(() {
      if (savedInterested is bool) isInterested = savedInterested;

      if (savedStarIds is List) {
        starredCategoryIds = savedStarIds.map((e) => e.toString()).toSet();
      }

      //
      if (starredCategoryIds.isEmpty && data['starredCategories'] is List) {
        final oldList =
            (data['starredCategories'] as List).map((e) => e == true).toList();

        for (int i = 0; i < builtInCategories.length; i++) {
          final isStar = i < oldList.length ? oldList[i] : false;
          if (isStar) starredCategoryIds.add(builtInCategories[i].id);
        }
      }
    });
  }

  // firebase stroage for interested categories
  Future<void> _savePrefs() async {
    await _prefsRef().set({
      'interested': isInterested,
      'starredCategoryIds': starredCategoryIds.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // what to do now user clicks on interested
  void _toggleStar(String categoryId) async {
    setState(() {
      if (starredCategoryIds.contains(categoryId)) {
        starredCategoryIds.remove(categoryId);
      } else {
        starredCategoryIds.add(categoryId);
      }
    });
    await _savePrefs();
  }

  // interested filter
  List<_CategoryItem> _visibleCategories(List<_CategoryItem> all) {
    if (!isInterested) return all;
    return all.where((c) => starredCategoryIds.contains(c.id)).toList();
  }

  // empty grid
  Widget _buildGrid(List<_CategoryItem> visible) {
    if (visible.isEmpty) {
      return const Center(
        child: Text(
          "No starred categories yet.\nStar a category first",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // building category grid
    return GridView.builder(
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final cat = visible[index];
        final isStarred = starredCategoryIds.contains(cat.id);

        return _CategoryCard(
          title: cat.title,
          imagePath: cat.imagePath,
          isStarred: isStarred,
          onStarTap: () => _toggleStar(cat.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      setState(() => isInterested = !isInterested);
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

            // category grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection("forum_requests")
                          .where("status", isEqualTo: "approved")
                          .orderBy("createdAt", descending: false)
                          .snapshots(),
                  builder: (context, snapshot) {
                    // to still show default categories
                    if (snapshot.hasError || !snapshot.hasData) {
                      final all = builtInCategories;
                      final visible = _visibleCategories(all);
                      return _buildGrid(visible);
                    }

                    // approved categories set up
                    final approvedDocs = snapshot.data!.docs;

                    final approvedCategories =
                        approvedDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          final title = (data["title"] ?? "").toString();

                          // TO DO: WE CAN EDIT THE IMAGE PATH BUT FOR RN, ITS ON THIS IMAFE PATH
                          final imagePath =
                              (data["imagePath"] ??
                                      "assets/forum/campus_resources.jpg")
                                  .toString();

                          return _CategoryItem(
                            id: "request:${doc.id}",
                            title: title,
                            imagePath: imagePath,
                          );
                        }).toList();

                    final allCategories = [
                      ...builtInCategories,
                      ...approvedCategories,
                    ];
                    final visible = _visibleCategories(allCategories);

                    return _buildGrid(visible);
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
                color: Colors.yellow,
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

// Category model w/ IDs
class _CategoryItem {
  final String id;
  final String title;
  final String imagePath;
  const _CategoryItem({
    required this.id,
    required this.title,
    required this.imagePath,
  });
}
