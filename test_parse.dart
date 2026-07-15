import 'dart:convert';

void main() {
  Map<String, dynamic> jsonResponse = {
    "id": 1,
    "titre": "Cotisation test",
    "description": null,
    "statut": "EN_COURS",
    "totalCollecte": 40000.0,
    "paiements": [
      {
        "id": 1,
        "montant": 40000.0,
        "modePaiement": "Espèces",
        "datePaiement": "2026-07-01T00:00:00",
        "membre": "Kobson Jean"
      }
    ]
  };

  try {
    var paiements = List<Map<String, dynamic>>.from(jsonResponse['paiements'] ?? []);
    print("Paiements OK: $paiements");
    var montants = List<Map<String, dynamic>>.from(jsonResponse['montants'] ?? []);
    print("Montants OK: $montants");
  } catch (e, stack) {
    print("Error: $e\n$stack");
  }
}
