import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  AuthService(this._apiService) {
    _setupAuthInterceptor();
    checkLoginStatus();
  }

  // Intercept 401 globally → auto logout
  void _setupAuthInterceptor() {
    _apiService.client.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && _isAuthenticated) {
          await logout();
        }
        return handler.next(e);
      },
    ));
  }

  /// Décoder le payload JWT localement (sans appel réseau)
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      var payload = parts[1];
      // Normalise le base64url en base64 standard
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> checkLoginStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final claims = _decodeJwt(token);
      if (claims.isNotEmpty) {
        // Lire le rôle directement depuis le JWT (pas d'appel réseau)
        _currentUser = {
          'id': claims['nameid'] ?? claims['sub'],
          'email': claims['email'],
          'role': claims['role'],
          'name': claims['unique_name'] ?? claims['name'],
        };
        _isAuthenticated = true;
      } else {
        // Token invalide → déconnexion
        await logout();
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        _currentUser = response.data['user'] is Map
            ? Map<String, dynamic>.from(response.data['user'])
            : response.data['user'];
        await _storage.write(key: 'jwt_token', value: token);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _errorMessage = e.response?.data['message'] ?? 'Email ou mot de passe incorrect.';
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        _errorMessage = 'Timeout (${e.type.name}). Vérifiez votre réseau.';
      } else if (e.type == DioExceptionType.connectionError) {
        _errorMessage = 'Erreur connexion: ${e.error?.toString() ?? e.message}';
      } else {
        _errorMessage = '[${e.type.name}] ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
