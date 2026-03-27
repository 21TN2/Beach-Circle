// FORUM CATEGORY

class ForumCategory {
  final String id;
  final String title;
  final String? imagePath;
  final String? imageUrl;

  const ForumCategory({
    required this.id,
    required this.title,
    this.imagePath,
    this.imageUrl,
  });

  // CREATES A FORUM CATEGORY FROM MAP
  factory ForumCategory.fromMap(String id, Map<String, dynamic> data) {
    return ForumCategory(
      id: id,
      title: (data['title'] ?? '') as String,
      imagePath: data['imagePath'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'imagePath': imagePath,
    'imageUrl': imageUrl,
  };
}
