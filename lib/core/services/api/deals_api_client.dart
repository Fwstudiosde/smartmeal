import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smartmeal/core/models/models.dart';

/// Abstract interface for deals data sources
abstract class DealsDataSource {
  Future<List<Deal>> fetchDeals({List<String>? storeIds});
  Future<List<Supermarket>> getSupermarkets();
  String get sourceName;
}

/// Configuration for API clients
class DealsApiConfig {
  final String baseUrl;
  final String? apiKey;
  final Duration timeout;
  final Map<String, String>? headers;

  const DealsApiConfig({
    required this.baseUrl,
    this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.headers,
  });
}

/// Main API client for fetching deals from various sources
class DealsApiClient {
  final Dio _dio;
  final DealsApiConfig config;
  final List<DealsDataSource> _dataSources = [];

  DealsApiClient({
    required this.config,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.timeout,
      receiveTimeout: config.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?config.headers,
        if (config.apiKey != null) 'Authorization': 'Bearer ${config.apiKey}',
      },
    );

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[DealsAPI] $obj'),
    ));
  }

  /// Register a data source
  void registerDataSource(DealsDataSource source) {
    _dataSources.add(source);
  }

  /// Fetch deals from all registered sources
  Future<List<Deal>> fetchDealsFromAllSources({List<String>? storeIds}) async {
    final allDeals = <Deal>[];

    for (final source in _dataSources) {
      try {
        final deals = await source.fetchDeals(storeIds: storeIds);
        allDeals.addAll(deals);
      } catch (e) {
        print('Error fetching from ${source.sourceName}: $e');
        // Continue with other sources even if one fails
      }
    }

    return allDeals;
  }

  /// Fetch deals from a specific source
  Future<List<Deal>> fetchDealsFromSource(
    String sourceName, {
    List<String>? storeIds,
  }) async {
    final source = _dataSources.firstWhere(
      (s) => s.sourceName == sourceName,
      orElse: () => throw Exception('Data source $sourceName not found'),
    );

    return source.fetchDeals(storeIds: storeIds);
  }

  /// Get all available supermarkets
  Future<List<Supermarket>> getAllSupermarkets() async {
    final supermarketsSet = <String, Supermarket>{};

    for (final source in _dataSources) {
      try {
        final markets = await source.getSupermarkets();
        for (final market in markets) {
          supermarketsSet[market.id] = market;
        }
      } catch (e) {
        print('Error fetching supermarkets from ${source.sourceName}: $e');
      }
    }

    return supermarketsSet.values.toList();
  }

  /// Generic GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return Exception('Unauthorized. Please check your API key.');
        } else if (statusCode == 404) {
          return Exception('Resource not found.');
        } else if (statusCode == 500) {
          return Exception('Server error. Please try again later.');
        }
        return Exception('Request failed with status code: $statusCode');
      case DioExceptionType.cancel:
        return Exception('Request cancelled.');
      default:
        return Exception('Network error: ${error.message}');
    }
  }

  void dispose() {
    _dio.close();
  }
}

/// Backend data source implementation
class BackendDealsDataSource implements DealsDataSource {
  final Dio _dio;
  final String baseUrl;

  BackendDealsDataSource({
    this.baseUrl = 'http://localhost:8000',
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  @override
  String get sourceName => 'Backend API';

  @override
  Future<List<Deal>> fetchDeals({List<String>? storeIds}) async {
    try {
      final queryParams = <String, dynamic>{};

      // Backend API expects 'store' parameter for filtering
      if (storeIds != null && storeIds.isNotEmpty) {
        queryParams['store'] = storeIds.first;
      }

      final response = await _dio.get(
        '/api/deals',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final dealsList = response.data as List;
        return dealsList.map((json) => Deal.fromBackendJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching deals from backend: $e');
      return [];
    }
  }

  @override
  Future<List<Supermarket>> getSupermarkets() async {
    try {
      final response = await _dio.get('/api/stores');

      if (response.statusCode == 200 && response.data is List) {
        final storesList = response.data as List;
        final uniqueStores = <String, Supermarket>{};

        // Map backend stores to Supermarket objects
        for (final storeData in storesList) {
          final storeName = storeData['name'] as String;

          // Find matching supermarket from predefined list
          final supermarket = Supermarket.all.firstWhere(
            (s) => s.name.toLowerCase() == storeName.toLowerCase(),
            orElse: () => Supermarket(
              id: storeName.toLowerCase(),
              name: storeName,
              logoUrl: '',
              brandColor: const Color(0xFF000000),
            ),
          );

          uniqueStores[supermarket.id] = supermarket;
        }

        return uniqueStores.values.toList();
      }

      // Fallback to predefined list if API fails
      return Supermarket.all;
    } catch (e) {
      print('Error fetching supermarkets from backend: $e');
      return Supermarket.all;
    }
  }
}
