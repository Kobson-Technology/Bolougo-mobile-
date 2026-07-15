class GroupeMembre {
  final int id;
  final String nom;

  GroupeMembre({
    required this.id,
    required this.nom,
  });

  factory GroupeMembre.fromJson(Map<String, dynamic> json) => GroupeMembre(
        id: json['id'],
        nom: json['nom'] ?? '',
      );
}
