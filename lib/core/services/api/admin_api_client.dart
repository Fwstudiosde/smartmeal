import 'dart:io';
import 'package:dio/dio.dart';

class AdminApiClient {
  final Dio _dio;
  final String baseUrl;
  String? _accessToken;

  AdminApiClient({
    this.baseUrl = 'http://localhost:8000',
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 20), // Long timeout for AI processing of large PDFs
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Login as admin
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/admin/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        return true;
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Logout
  void logout() {
    _accessToken = null;
  }

  /// Check if logged in
  bool get isLoggedIn => _accessToken != null;

  /// Set access token (from secure storage)
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Get access token
  String? get accessToken => _accessToken;

  /// Upload prospekt (PDF or image)
  Future<Map<String, dynamic>> uploadProspekt({
    required File file,
    required String storeName,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'store_name': storeName,
      });

      final response = await _dio.post(
        '/api/admin/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /// Get all deals (admin view)
  Future<Map<String, dynamic>> getAllDeals() async {
    try {
      final response = await _dio.get('/api/admin/deals');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to fetch deals');
    } catch (e) {
      throw Exception('Error fetching deals: $e');
    }
  }

  /// Update a deal
  Future<Map<String, dynamic>> updateDeal(
    int dealIndex,
    Map<String, dynamic> dealData,
  ) async {
    try {
      final response = await _dio.put(
        '/api/admin/deals/$dealIndex',
        data: dealData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to update deal');
    } catch (e) {
      throw Exception('Error updating deal: $e');
    }
  }

  /// Delete a deal
  Future<Map<String, dynamic>> deleteDeal(int dealIndex) async {
    try {
      final response = await _dio.delete('/api/admin/deals/$dealIndex');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to delete deal');
    } catch (e) {
      throw Exception('Error deleting deal: $e');
    }
  }

  /// Create a new deal manually
  Future<Map<String, dynamic>> createDeal(
    Map<String, dynamic> dealData,
  ) async {
    try {
      final response = await _dio.post(
        '/api/admin/deals',
        data: dealData,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to create deal');
    } catch (e) {
      throw Exception('Error creating deal: $e');
    }
  }

  /// Clear all deals
  Future<Map<String, dynamic>> clearAllDeals() async {
    try {
      final response = await _dio.delete('/api/admin/deals');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to clear deals');
    } catch (e) {
      throw Exception('Error clearing deals: $e');
    }
  }

  void dispose() {
    _dio.close();
  }
}
