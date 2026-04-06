import 'package:dio/dio.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/api/deals_api_client.dart';

/// Client for Open Food Facts API
/// Documentation: https://openfoodfacts.github.io/openfoodfacts-server/api/
class OpenFoodFactsClient implements DealsDataSource {
  static const String baseUrl = 'https://world.openfoodfacts.org/api/v2';
  static const String pricesBaseUrl = 'https://prices.openfoodfacts.org/api/v1';

  final Dio _dio;
  final Dio _pricesDio;

  OpenFoodFactsClient({Dio? dio, Dio? pricesDio})
      : _dio = dio ?? Dio(),
        _pricesDio = pricesDio ?? Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'SmartMeal - Flutter App - v1.0.0',
        'Accept': 'application/json',
      },
    );

    _pricesDio.options = BaseOptions(
      baseUrl: pricesBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'SmartMeal - Flutter App - v1.0.0',
        'Accept': 'application/json',
      },
    );
  }

  @override
  String get sourceName => 'Open Food Facts';

  @override
  Future<List<Supermarket>> getSupermarkets() async {
    // Open Food Facts doesn't provide a supermarket list
    // Return common German supermarkets
    return Supermarket.all;
  }

  @override
  Future<List<Deal>> fetchDeals({List<String>? storeIds}) async {
    try {
      // Fetch recent prices from Germany
      final response = await _pricesDio.get(
        '/prices',
        queryParameters: {
          'location_osm_type': 'NODE',
          'location_osm_id': '62422', // Germany
          'page': 1,
          'size': 100,
          'order_by': '-created',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final prices = data['items'] as List<dynamic>? ?? [];

        final deals = <Deal>[];

        for (final priceData in prices) {
          final deal = await _convertPriceToDeal(priceData);
          if (deal != null) {
            // Filter by store if provided
            if (storeIds == null ||
                storeIds.isEmpty ||
                storeIds.any((id) => deal.storeName.toLowerCase().contains(id.toLowerCase()))) {
              deals.add(deal);
            }
          }
        }

        return deals;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch deals from Open Food Facts: $e');
    }
  }

  /// Search products by name
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'search_terms': query,
          'page_size': 20,
          'fields': 'product_name,brands,image_url,code,stores',
          'countries_tags_en': 'germany',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['products'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get product by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get('/product/$barcode');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 1) {
          return data['product'] as Map<String, dynamic>;
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Get prices for a specific product
  Future<List<Map<String, dynamic>>> getPricesForProduct(int productId) async {
    try {
      final response = await _pricesDio.get(
        '/prices',
        queryParameters: {
          'product_id': productId,
          'page': 1,
          'size': 50,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch prices: $e');
    }
  }

  /// Get recent prices by location
  Future<List<Map<String, dynamic>>> getPricesByLocation({
    String? locationOsmType,
    String? locationOsmId,
    int page = 1,
    int size = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'order_by': '-created',
      };

      if (locationOsmType != null) {
        queryParams['location_osm_type'] = locationOsmType;
      }
      if (locationOsmId != null) {
        queryParams['location_osm_id'] = locationOsmId;
      }

      final response = await _pricesDio.get('/prices', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch prices by location: $e');
    }
  }

  Future<Deal?> _convertPriceToDeal(Map<String, dynamic> priceData) async {
    try {
      final productId = priceData['product_id'];
      final price = priceData['price'];
      final currency = priceData['currency'];
      final locationId = priceData['location_id'];
      final date = priceData['date'];

      if (productId == null || price == null) return null;

      // Get product details
      final productCode = priceData['product_code'] as String?;
      if (productCode == null) return null;

      final product = await getProductByBarcode(productCode);
      if (product == null) return null;

      final productName = product['product_name'] as String? ?? 'Unknown Product';
      final imageUrl = product['image_url'] as String?;
      final brands = product['brands'] as String? ?? '';

      // Extract store name from location or use default
      final storeName = _extractStoreName(priceData) ?? 'Supermarkt';

      // Create a deal (we don't have discount info, so we'll use current price)
      final currentPrice = (price as num).toDouble();

      return Deal(
        id: priceData['id'].toString(),
        productName: productName,
        storeName: storeName,
        storeLogoUrl: _getStoreLogoUrl(storeName),
        originalPrice: currentPrice * 1.2, // Simulate 20% discount
        discountPrice: currentPrice,
        discountPercentage: 17,
        imageUrl: imageUrl,
        validFrom: DateTime.parse(date),
        validUntil: DateTime.parse(date).add(const Duration(days: 7)),
        category: _categorizeProduct(product),
      );
    } catch (e) {
      return null;
    }
  }

  String? _extractStoreName(Map<String, dynamic> priceData) {
    // Try to extract store name from location data
    if (priceData['location'] != null) {
      final location = priceData['location'] as Map<String, dynamic>;
      final name = location['display_name'] as String?;

      if (name != null) {
        // Check if it contains known store names
        final lowerName = name.toLowerCase();
        if (lowerName.contains('aldi')) return 'ALDI';
        if (lowerName.contains('lidl')) return 'Lidl';
        if (lowerName.contains('rewe')) return 'REWE';
        if (lowerName.contains('edeka')) return 'EDEKA';
        if (lowerName.contains('kaufland')) return 'Kaufland';
        if (lowerName.contains('penny')) return 'Penny';
        if (lowerName.contains('netto')) return 'Netto';
      }
    }

    return null;
  }

  String _getStoreLogoUrl(String storeName) {
    final store = Supermarket.all.firstWhere(
      (s) => s.name.toLowerCase() == storeName.toLowerCase(),
      orElse: () => Supermarket.all.first,
    );
    return store.logoUrl;
  }

  String? _categorizeProduct(Map<String, dynamic> product) {
    final categories = product['categories_tags'] as List<dynamic>?;
    if (categories == null || categories.isEmpty) return 'Sonstiges';

    final category = categories.first.toString();

    // Map Open Food Facts categories to our categories
    if (category.contains('meat')) return 'Fleisch';
    if (category.contains('vegetable')) return 'Gemüse';
    if (category.contains('fruit')) return 'Obst';
    if (category.contains('dairy')) return 'Milchprodukte';
    if (category.contains('fish')) return 'Fisch';
    if (category.contains('beverage')) return 'Getränke';
    if (category.contains('snack')) return 'Snacks';

    return 'Sonstiges';
  }

  void dispose() {
    _dio.close();
    _pricesDio.close();
  }
}
