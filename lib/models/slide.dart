class Slide {
  final int id;
  final String? title;
  final String imageUrl;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  Slide({
    required this.id,
    this.title,
    required this.imageUrl,
    required this.order,
    required this.isActive,
    required this.createdAt,
  });

  factory Slide.fromJson(Map<String, dynamic> json) => Slide(
        id: json['id'],
        title: json['title'],
        imageUrl: json['imageUrl'] ?? '',
        order: json['order'] ?? 0,
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
