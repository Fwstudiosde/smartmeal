import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthApiClient {
  final String baseUrl;

  AuthApiClient({required this.baseUrl});

  /// Register a new user with email and password
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  /// Authenticate with Apple ID
  Future<Map<String, dynamic>> appleAuth({
    required String appleId,
    String? email,
    String? name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'apple_id': appleId,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Apple authentication failed');
    }
  }

  /// Get current user info
  Future<UserModel> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to get user info');
    }
  }
}
