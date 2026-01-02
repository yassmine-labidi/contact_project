import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // IMPORTANT: Change cette URL selon ton environnement
  static const String baseUrl = 'http://localhost:8000';

  // Inscription
  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      print('📤 Tentative d\'inscription: $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print('📥 Réponse inscription: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Sauvegarder le token
        final token = data['access_token'];
        print('🔑 Token reçu: ${token.substring(0, 30)}...');
        await _saveToken(token);
        
        print('✅ Inscription réussie');
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': 'Inscription réussie'
        };
      } else {
        final errorData = json.decode(response.body);
        print('❌ Erreur: ${errorData['detail']}');
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erreur lors de l\'inscription'
        };
      }
    } catch (e) {
      print('❌ Exception register: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // Connexion
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      print('📤 Tentative de connexion: $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('📥 Réponse connexion: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Sauvegarder le token
        final token = data['access_token'];
        print('🔑 Token reçu: ${token.substring(0, 30)}...');
        await _saveToken(token);
        
        // Vérifier que le token est bien sauvegardé
        final savedToken = await getToken();
        print('✅ Token sauvegardé: ${savedToken != null}');
        
        print('✅ Connexion réussie');
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': 'Connexion réussie'
        };
      } else {
        final errorData = json.decode(response.body);
        print('❌ Erreur: ${errorData['detail']}');
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Identifiants incorrects'
        };
      }
    } catch (e) {
      print('❌ Exception login: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur: $e'};
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    print('👋 Déconnexion...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('✅ Token supprimé');
  }

  // Sauvegarder le token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString('auth_token', token);
    print('💾 Token sauvegardé: $saved');
  }

  // Récupérer le token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      print('🔍 Token récupéré: ${token.substring(0, 30)}...');
    } else {
      print('⚠️ Aucun token trouvé');
    }
    return token;
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final loggedIn = token != null && token.isNotEmpty;
    print('🔐 Est connecté: $loggedIn');
    return loggedIn;
  }

  // Récupérer les informations de l'utilisateur
  static Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ Pas de token pour getCurrentUser');
        return null;
      }

      print('📤 Récupération utilisateur courant');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        print('✅ Utilisateur: ${user.username}');
        return user;
      } else {
        print('❌ Erreur récupération utilisateur');
        return null;
      }
    } catch (e) {
      print('❌ Exception getCurrentUser: $e');
      return null;
    }
  }
}