class Membre {
  final int id;
  final String nom;
  final String prenoms;
  final String? sexe;
  final String? telephone;
  final String? email;
  final String? ville;
  final String? pays;
  final String? profession;
  final String? photo;
  final String? famille;
  final String? quartier;
  final int? groupeId;

  Membre({
    required this.id,
    required this.nom,
    required this.prenoms,
    this.sexe,
    this.telephone,
    this.email,
    this.ville,
    this.pays,
    this.profession,
    this.photo,
    this.famille,
    this.quartier,
    this.groupeId,
  });

  String get nomComplet => '$nom $prenoms';

  factory Membre.fromJson(Map<String, dynamic> json) {
    return Membre(
      id: json['id'],
      nom: json['nom'],
      prenoms: json['prenoms'],
      sexe: json['sexe'],
      telephone: json['telephone'],
      email: json['email'],
      ville: json['ville'],
      pays: json['pays'],
      profession: json['profession'],
      photo: json['photo'],
      famille: json['famille'],
      quartier: json['quartier'],
      groupeId: json['groupeId'],
    );
  }
}

class MembreDetail extends Membre {
  final List<Map<String, dynamic>> paiements;

  MembreDetail({
    required super.id,
    required super.nom,
    required super.prenoms,
    super.sexe,
    super.telephone,
    super.email,
    super.ville,
    super.pays,
    super.profession,
    super.photo,
    super.famille,
    super.quartier,
    super.groupeId,
    required this.paiements,
  });

  factory MembreDetail.fromJson(Map<String, dynamic> json) {
    return MembreDetail(
      id: json['id'],
      nom: json['nom'],
      prenoms: json['prenoms'],
      sexe: json['sexe'],
      telephone: json['telephone'],
      email: json['email'],
      ville: json['ville'],
      pays: json['pays'],
      profession: json['profession'],
      photo: json['photo'],
      famille: json['famille'],
      quartier: json['quartier'],
      groupeId: json['groupeId'],
      paiements: List<Map<String, dynamic>>.from(json['paiements'] ?? []),
    );
  }
}
