import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:smartmeal/core/config/supabase_config.dart';

class AdminApiClient {
  final Dio _dio;
  final String baseUrl;
  String? _accessToken;

  AdminApiClient({
    String? baseUrl,
    Dio? dio,
  }) : baseUrl = baseUrl ?? BackendConfig.baseUrl,
       _dio = dio ?? Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

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
      return false;
    }
  }

  void logout() {
    _accessToken = null;
  }

  bool get isLoggedIn => _accessToken != null;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  String? get accessToken => _accessToken;

  Future<Map<String, dynamic>> uploadProspekt({
    required Uint8List bytes,
    required String filename,
    required String storeName,
    Function(double)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
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

  // ====== ADMIN DASHBOARD ======

  Future<Map<String, dynamic>> getStatsOverview() async {
    final res = await _dio.get('/api/admin/stats/overview');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStatsTimeseries({int days = 30}) async {
    final res = await _dio.get(
      '/api/admin/stats/timeseries',
      queryParameters: {'days': days},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStatsTop() async {
    final res = await _dio.get('/api/admin/stats/top');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getModerationQueue({int limit = 20}) async {
    final res = await _dio.get(
      '/api/admin/moderation/queue',
      queryParameters: {'limit': limit},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await _dio.get(
      '/api/admin/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCommunityRecipes({
    int page = 1,
    int limit = 20,
    String? search,
    String sort = 'newest',
  }) async {
    final res = await _dio.get(
      '/api/admin/recipes/community',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sort': sort,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteCommunityRecipe(String recipeId) async {
    await _dio.delete('/api/admin/recipes/$recipeId');
  }

  Future<void> deleteUser(String userId) async {
    await _dio.delete('/api/admin/users/$userId');
  }

  Future<Map<String, dynamic>> getHealth() async {
    final res = await _dio.get('/api/admin/health');
    return res.data as Map<String, dynamic>;
  }

  void dispose() {
    _dio.close();
  }
}
