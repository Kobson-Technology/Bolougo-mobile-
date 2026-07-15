class Bureau {
  final int id;
  final int membreId;
  final String role;
  final int anneeDebut;
  final int? anneeFin;
  final String? motDuMembre;
  final String statut;

  // Additional fields from API
  final String? membreNom;
  final String? membrePrenom;
  final String? membrePhoto;

  Bureau({
    required this.id,
    required this.membreId,
    required this.role,
    required this.anneeDebut,
    this.anneeFin,
    this.motDuMembre,
    required this.statut,
    this.membreNom,
    this.membrePrenom,
    this.membrePhoto,
  });

  factory Bureau.fromJson(Map<String, dynamic> json) => Bureau(
        id: json['id'],
        membreId: json['membreId'],
        role: json['role'] ?? '',
        anneeDebut: json['anneeDebut'] ?? 0,
        anneeFin: json['anneeFin'],
        motDuMembre: json['motDuMembre'],
        statut: json['statut'] ?? '',
        membreNom: json['membreNom'],
        membrePrenom: json['membrePrenom'],
        membrePhoto: json['membrePhoto'],
      );
}
