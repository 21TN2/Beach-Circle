// TO DO: FIND OUT HOW TO CHANGE IMAGES FROM ADDED FORUMS
// student misc forum home page
import 'package:beach_circle_flutter/community_goods/smf/screens/create_forum_page_pg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// forum posts pages
import 'package:beach_circle_flutter/community_goods/smf/model/forum_category.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/forum_category_pg.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/forum_service.dart';

class MiscScreen extends StatefulWidget {
  const MiscScreen({super.key, this.forumService, this.onOpenCategory});

  final ForumService? forumService;
  final Null Function(ForumCategory c)? onOpenCategory;

  @override
  State<MiscScreen> createState() => _MiscScreenState();
}

class _MiscScreenState extends State<MiscScreen> {
  bool isInterested = false;
  Set<String> starredCategoryIds = {};
  late final ForumService _forumService;

  // built-in categories
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
    _forumService = widget.forumService ?? ForumService();
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

    if (mounted) {
      setState(() {
        if (savedInterested is bool) isInterested = savedInterested;

        if (savedStarIds is List) {
          starredCategoryIds = savedStarIds.map((e) => e.toString()).toSet();
        }

        if (starredCategoryIds.isEmpty && data['starredCategories'] is List) {
          final oldList =
              (data['starredCategories'] as List)
                  .map((e) => e == true)
                  .toList();

          for (int i = 0; i < builtInCategories.length; i++) {
            final isStar = i < oldList.length ? oldList[i] : false;
            if (isStar) starredCategoryIds.add(builtInCategories[i].id);
          }
        }
      });
    }
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
      imagePath: cat.imagePath,
      imageUrl: cat.imageUrl,
    );

    if (widget.onOpenCategory != null) {
      widget.onOpenCategory!(category);
    } else {
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
  }

  Widget _buildGrid(List<_CategoryItem> visible) {
    if (visible.isEmpty) {
      return const Center(
        child: Text(
          "No starred categories yet.\nStar a category first",
          textAlign: TextAlign.center,
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
          imageUrl: cat.imageUrl,
          isStarred: isStarred,
          onStarTap: () => _toggleStar(cat.id),
          onTap: () => _openCategory(cat),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // pencil icon to go to add forum
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF2C200),
        child: const Icon(Icons.edit, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CreateForumPage(
                    onClose: () => Navigator.pop(context),
                    onSubmitted: () => Navigator.pop(context),
                  ),
            ),
          );
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFFFD500),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(child: _HeaderPill()),
                  const SizedBox(width: 10),
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
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text("Interested"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Added New Forum from users to appear in home page - Giselle => for student work review 2
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection("forum_requests")
                          .where("status", isEqualTo: "approved")
                          .snapshots(),
                  builder: (context, snapshot) {
                    // built-in + approved categories shown in homepage
                    final List<_CategoryItem> all = List<_CategoryItem>.from(
                      builtInCategories,
                    );

                    if (snapshot.hasData) {
                      for (final doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString().trim();
                        if (title.isEmpty) continue;

                        all.add(
                          _CategoryItem(
                            id: doc.id,
                            title: title,
                            imagePath: "assets/forum/community_chat.jpg",
                            imageUrl: (data['imageUrl'] ?? '').toString(),
                          ),
                        );
                      }
                    }

                    final visible = _visibleCategories(all);
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

// --------  header ------
class _HeaderPill extends StatelessWidget {
  const _HeaderPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 13, right: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              "Student Miscellaneous Forum",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.5,
                color: Colors.black54,
              ),
            ),
          ),
          const Positioned(
            right: 0,
            child: Icon(Icons.chevron_right, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.imagePath,
    this.imageUrl,
    required this.isStarred,
    required this.onStarTap,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final String? imageUrl;
  final bool isStarred;
  final VoidCallback onStarTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ImageProvider imageProvider =
        (imageUrl != null && imageUrl!.isNotEmpty)
            ? NetworkImage(imageUrl!)
            : AssetImage(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image(image: imageProvider, fit: BoxFit.cover),
          ),

          // DARK OVERLAY FIXED
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String id;
  final String title;
  final String imagePath;
  final String? imageUrl;

  const _CategoryItem({
    required this.id,
    required this.title,
    required this.imagePath,
    this.imageUrl,
  });
}
