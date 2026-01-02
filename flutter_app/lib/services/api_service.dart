//flutter_app/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/person.dart';
import 'auth_service.dart';

class ApiService {
  // Pour émulateur Android : 10.0.2.2
  // Pour appareil physique : utilise l'IP de ton PC (ex: 192.168.1.10)
  // Pour Chrome/Web : localhost
  static const String baseUrl = 'http://localhost:8000';

  // Headers avec authentification
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Non authentifié. Veuillez vous reconnecter.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Récupérer tous les contacts
  static Future<List<Person>> getPersons() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/personnes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Person.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors du chargement des contacts');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Ajouter un contact
  static Future<String> addPerson(Person person) async {
    try {
      final headers = await _getHeaders();
      print('Headers: $headers'); // Debug
      print('Adding person: ${person.toJson()}'); // Debug
      
      final response = await http.post(
        Uri.parse('$baseUrl/personnes'),
        headers: headers,
        body: json.encode(person.toJson()),
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 201) {
        return 'Contact ajouté avec succès';
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de l\'ajout');
      }
    } catch (e) {
      print('Erreur addPerson: $e'); // Debug
      throw Exception('$e');
    }
  }

  // Modifier un contact
  static Future<String> updatePerson(int id, Person person) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/personnes/$id'),
        headers: headers,
        body: json.encode(person.toJsonUpdate()),
      );

      if (response.statusCode == 200) {
        return 'Contact modifié avec succès';
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Supprimer un contact
  static Future<String> deletePerson(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/personnes/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return 'Contact supprimé avec succès';
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}