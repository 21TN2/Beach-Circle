// FORUM CATEGORY

class ForumCategory {
  final String id;
  final String title;

  const ForumCategory({required this.id, required this.title});

  // CREATES A FORUM CATEGORY FROM MAP
  factory ForumCategory.fromMap(String id, Map<String, dynamic> data) {
    return ForumCategory(id: id, title: (data['title'] ?? '') as String);
  }

  Map<String, dynamic> toMap() => {'title': title};
}
