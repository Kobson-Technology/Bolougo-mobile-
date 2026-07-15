class Article {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String? imageUrl;
  final String? author;
  final DateTime createdAt;

  Article({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.imageUrl,
    this.author,
    required this.createdAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'],
        title: json['title'],
        slug: json['slug'] ?? '',
        content: json['content'] ?? '',
        imageUrl: json['imageUrl'],
        author: json['author'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
