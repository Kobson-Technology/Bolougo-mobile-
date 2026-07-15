class FinanceResume {
  final double totalCotisations;
  final double totalDons;
  final double totalEntrees;
  final double totalSorties;
  final double soldeNet;

  FinanceResume({
    required this.totalCotisations,
    required this.totalDons,
    required this.totalEntrees,
    required this.totalSorties,
    required this.soldeNet,
  });

  factory FinanceResume.fromJson(Map<String, dynamic> json) {
    return FinanceResume(
      totalCotisations: (json['totalCotisations'] ?? 0).toDouble(),
      totalDons: (json['totalDons'] ?? 0).toDouble(),
      totalEntrees: (json['totalEntrees'] ?? 0).toDouble(),
      totalSorties: (json['totalSorties'] ?? 0).toDouble(),
      soldeNet: (json['soldeNet'] ?? 0).toDouble(),
    );
  }
}

class Depense {
  final int id;
  final String titre;
  final String? categorie;
  final double montant;
  final String? description;
  final String date;

  Depense({
    required this.id,
    required this.titre,
    this.categorie,
    required this.montant,
    this.description,
    required this.date,
  });

  factory Depense.fromJson(Map<String, dynamic> json) {
    return Depense(
      id: json['id'],
      titre: json['titre'],
      categorie: json['categorie'],
      montant: (json['montant'] ?? 0).toDouble(),
      description: json['description'],
      date: json['date'] ?? '',
    );
  }
}

class Don {
  final int id;
  final String donateur;
  final double montant;
  final String? description;
  final String date;

  Don({
    required this.id,
    required this.donateur,
    required this.montant,
    this.description,
    required this.date,
  });

  factory Don.fromJson(Map<String, dynamic> json) {
    return Don(
      id: json['id'],
      donateur: json['donateur'],
      montant: (json['montant'] ?? 0).toDouble(),
      description: json['description'],
      date: json['date'] ?? '',
    );
  }
}
