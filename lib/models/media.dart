class Photo {
  final int id;
  final String title;
  final String? description;
  final String url;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        url: json['url'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Video {
  final int id;
  final String title;
  final String? description;
  final String youtubeUrl;
  final DateTime createdAt;

  Video({
    required this.id,
    required this.title,
    this.description,
    required this.youtubeUrl,
    required this.createdAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        youtubeUrl: json['youtubeUrl'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Musique {
  final int id;
  final String title;
  final String? description;
  final String url;
  final DateTime createdAt;
  final String? coverUrl;

  Musique({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    required this.createdAt,
    this.coverUrl,
  });

  factory Musique.fromJson(Map<String, dynamic> json) => Musique(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        url: json['url'],
        createdAt: DateTime.parse(json['createdAt']),
        coverUrl: json['coverUrl'],
      );
}
