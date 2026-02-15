// student misc forum home page
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ✅ forum posts pages
import 'package:beach_circle_flutter/community_goods/smf/model/forum_category.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/forum_category_pg.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/forum_service.dart';

class MiscScreen extends StatefulWidget {
  const MiscScreen({super.key});

  @override
  State<MiscScreen> createState() => _MiscScreenState();
}

class _MiscScreenState extends State<MiscScreen> {
  bool isInterested = false;

  // starred category set up
  Set<String> starredCategoryIds = {};

  final ForumService _forumService = ForumService();

  // ✅ your original default built-in categories
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
      id: "builtin:Engineering Q&A",
      title: "Engineering\nQ&A",
      imagePath: "assets/forum/engineering_qa.jpg",
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

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await _prefsRef().get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final savedInterested = data['interested'];
    final savedStarIds = data['starredCategoryIds'];

    setState(() {
      if (savedInterested is bool) isInterested = savedInterested;

      if (savedStarIds is List) {
        starredCategoryIds = savedStarIds.map((e) => e.toString()).toSet();
      }

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

  Future<void> _savePrefs() async {
    await _prefsRef().set({
      'interested': isInterested,
      'starredCategoryIds': starredCategoryIds.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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

  List<_CategoryItem> _visibleCategories(List<_CategoryItem> all) {
    if (!isInterested) return all;
    return all.where((c) => starredCategoryIds.contains(c.id)).toList();
  }

  void _openCategory(_CategoryItem cat) {
    final category = ForumCategory(
      id: cat.id,
      title: cat.title.replaceAll('\n', ' '),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ForumCategoryPg(
              category: category,
              forumService: _forumService,
            ),
      ),
    );
  }

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
          onTap: () => _openCategory(cat), // ✅ NEW: open category posts
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

                  // Interested button (unchanged)
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
                    if (snapshot.hasError || !snapshot.hasData) {
                      final visible = _visibleCategories(builtInCategories);
                      return _buildGrid(visible);
                    }

                    final approvedDocs = snapshot.data!.docs;

                    final approvedCategories =
                        approvedDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = (data["title"] ?? "").toString();

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
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final bool isStarred;
  final VoidCallback onStarTap;
  final VoidCallback onTap;

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

          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),

          // ✅ Category tap (opens posts)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),

          // Star icon (favorites)
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
