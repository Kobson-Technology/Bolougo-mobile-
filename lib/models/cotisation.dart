class MotifCotisation {
  final int id;
  final String titre;
  final String? description;
  final String statut;
  final double totalCollecte;
  final int nombrePaiements;
  final String? password;

  MotifCotisation({
    required this.id,
    required this.titre,
    this.description,
    required this.statut,
    required this.totalCollecte,
    required this.nombrePaiements,
    this.password,
  });

  factory MotifCotisation.fromJson(Map<String, dynamic> json) {
    return MotifCotisation(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      statut: json['statut'] ?? '',
      totalCollecte: (json['totalCollecte'] ?? 0).toDouble(),
      nombrePaiements: json['nombrePaiements'] ?? 0,
      password: json['password'],
    );
  }
}

class CotisationDetail {
  final int id;
  final String titre;
  final String? description;
  final String statut;
  final double totalCollecte;
  final List<Map<String, dynamic>> paiements;
  final List<Map<String, dynamic>> montants;

  CotisationDetail({
    required this.id,
    required this.titre,
    this.description,
    required this.statut,
    required this.totalCollecte,
    required this.paiements,
    required this.montants,
  });

  factory CotisationDetail.fromJson(Map<String, dynamic> json) {
    return CotisationDetail(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      statut: json['statut'] ?? '',
      totalCollecte: (json['totalCollecte'] ?? 0).toDouble(),
      paiements: List<Map<String, dynamic>>.from(json['paiements'] ?? []),
      montants: List<Map<String, dynamic>>.from(json['montants'] ?? []),
    );
  }
}
