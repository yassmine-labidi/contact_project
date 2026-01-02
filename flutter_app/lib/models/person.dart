//flutter_app/lib/models/person.dart
class Person {
  final int? id;
  final String nom;
  final String prenom;
  final String telephone;

  Person({
    this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      telephone: json['telephone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
    };
  }

  // Pour la modification
  Map<String, dynamic> toJsonUpdate() {
    return {
      if (nom.isNotEmpty) 'nom': nom,
      if (prenom.isNotEmpty) 'prenom': prenom,
      if (telephone.isNotEmpty) 'telephone': telephone,
    };
  }
}