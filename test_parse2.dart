import 'dart:convert';

void main() {
  var jsonResponse = [
    { "id": 1, "nom": "A", "groupeId": 1 }
  ];

  try {
    var tousLesMembres = List<Map<String, dynamic>>.from(jsonResponse);
    print("Membres OK: $tousLesMembres");
  } catch (e, stack) {
    print("Error: $e\n$stack");
  }
}
