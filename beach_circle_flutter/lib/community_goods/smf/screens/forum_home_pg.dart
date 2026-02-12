import 'package:flutter/material.dart';
import '../model/forum_category.dart';
import 'forum_category_pg.dart';

class ForumHomePg extends StatelessWidget {
  const ForumHomePg({super.key});

  // TODO: Replace with your real fetch (Firestore/service).
  List<ForumCategory> _mockCategories() => const [
        ForumCategory(id: 'eng', title: 'Engineering Q&A'),
        ForumCategory(id: 'clubs', title: 'Clubs & Orgs'),
        ForumCategory(id: 'housing', title: 'Housing / Dorm Life'),
      ];

  @override
  Widget build(BuildContext context) {
    final cats = _mockCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Miscellaneous Forum'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final c = cats[i];
          return ListTile(
            tileColor: const Color(0xFFF2F2F2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ForumCategoryPg(category: c)),
              );
            },
          );
        },
      ),
    );
  }
}