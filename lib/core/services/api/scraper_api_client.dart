import 'package:dio/dio.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/api/deals_api_client.dart';

/// Client for the SmartMeal Scraper API
/// This connects to your local Python backend that scrapes supermarket deals
class ScraperApiClient implements DealsDataSource {
  final Dio _dio;
  final String baseUrl;

  ScraperApiClient({
    this.baseUrl = 'http://localhost:8000',
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  @override
  String get sourceName => 'Scraper Backend';

  @override
  Future<List<Supermarket>> getSupermarkets() async {
    try {
      final response = await _dio.get('/api/stores');

      if (response.statusCode == 200) {
        final stores = response.data as List<dynamic>;

        // Map scraped stores to Supermarket objects
        final supermarkets = <Supermarket>[];

        for (final store in stores) {
          final storeName = store['name'] as String;

          // Find matching supermarket from our list
          final matchingSupermarket = Supermarket.all.firstWhere(
            (s) => s.name.toLowerCase() == storeName.toLowerCase(),
            orElse: () => Supermarket.all.first,
          );

          if (!supermarkets.contains(matchingSupermarket)) {
            supermarkets.add(matchingSupermarket);
          }
        }

        return supermarkets.isNotEmpty ? supermarkets : Supermarket.all;
      }

      return Supermarket.all;
    } catch (e) {
      // Return default list if API fails
      return Supermarket.all;
    }
  }

  @override
  Future<List<Deal>> fetchDeals({List<String>? storeIds}) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};

      if (storeIds != null && storeIds.isNotEmpty) {
        // If single store, use it as filter
        if (storeIds.length == 1) {
          queryParams['store'] = storeIds.first;
        }
      }

      final response = await _dio.get(
        '/api/deals',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final dealsData = response.data as List<dynamic>;
        final deals = <Deal>[];

        for (final dealData in dealsData) {
          final deal = _convertToDeal(dealData as Map<String, dynamic>);
          if (deal != null) {
            // Filter by store IDs if provided and multiple stores
            if (storeIds == null ||
                storeIds.isEmpty ||
                storeIds.length == 1 ||
                storeIds.any((id) =>
                    deal.storeName.toLowerCase().contains(id.toLowerCase()))) {
              deals.add(deal);
            }
          }
        }

        return deals;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch deals from scraper API: $e');
    }
  }

  /// Get deals for a specific store
  Future<List<Deal>> fetchDealsByStore(String storeName) async {
    try {
      final response = await _dio.get('/api/deals/$storeName');

      if (response.statusCode == 200) {
        final dealsData = response.data as List<dynamic>;
        final deals = <Deal>[];

        for (final dealData in dealsData) {
          final deal = _convertToDeal(dealData as Map<String, dynamic>);
          if (deal != null) {
            deals.add(deal);
          }
        }

        return deals;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch deals for $storeName: $e');
    }
  }

  /// Get statistics about available deals
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/api/stats');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      throw Exception('Failed to fetch stats: $e');
    }
  }

  /// Trigger manual scraping
  Future<void> triggerScrape() async {
    try {
      await _dio.post('/api/scrape');
    } catch (e) {
      throw Exception('Failed to trigger scraping: $e');
    }
  }

  /// Get scraping status
  Future<Map<String, dynamic>> getScrapingStatus() async {
    try {
      final response = await _dio.get('/api/scrape/status');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get scraping status: $e');
    }
  }

  Deal? _convertToDeal(Map<String, dynamic> data) {
    try {
      return Deal(
        id: data['product_name'].hashCode.toString(),
        productName: data['product_name'] as String,
        storeName: data['store_name'] as String,
        storeLogoUrl: _getStoreLogoUrl(data['store_name'] as String),
        originalPrice: (data['original_price'] as num).toDouble(),
        discountPrice: (data['discount_price'] as num).toDouble(),
        discountPercentage: (data['discount_percentage'] as num).toInt(),
        imageUrl: data['image_url'] as String?,
        validFrom: DateTime.parse(data['valid_from'] as String),
        validUntil: DateTime.parse(data['valid_until'] as String),
        category: data['category'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  String _getStoreLogoUrl(String storeName) {
    final store = Supermarket.all.firstWhere(
      (s) => s.name.toLowerCase() == storeName.toLowerCase(),
      orElse: () => Supermarket.all.first,
    );
    return store.logoUrl;
  }

  void dispose() {
    _dio.close();
  }
}
