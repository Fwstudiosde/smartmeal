import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/api/scraper_api_client.dart';

/// Provider for the new Deals Service with real API
final dealsServiceV2Provider = Provider<DealsServiceV2>((ref) {
  return DealsServiceV2(
    scraperClient: ScraperApiClient(),
  );
});

/// Enhanced Deals Service that uses real scraper API
class DealsServiceV2 {
  final ScraperApiClient scraperClient;

  DealsServiceV2({
    required this.scraperClient,
  });

  /// Gets list of available supermarkets
  Future<List<Supermarket>> getSupermarkets() async {
    try {
      return await scraperClient.getSupermarkets();
    } catch (e) {
      // Fallback to static list if API fails
      return Supermarket.all;
    }
  }

  /// Fetches current deals from scraper backend
  Future<List<Deal>> fetchDeals({List<String>? storeIds}) async {
    try {
      return await scraperClient.fetchDeals(storeIds: storeIds);
    } catch (e) {
      print('Error fetching deals from scraper: $e');
      // Return empty list on error - you could also return mock data as fallback
      return [];
    }
  }

  /// Fetches deals by category
  Future<List<Deal>> fetchDealsByCategory(String category) async {
    try {
      final allDeals = await scraperClient.fetchDeals();
      return allDeals
          .where((deal) =>
              deal.category?.toLowerCase() == category.toLowerCase())
          .toList();
    } catch (e) {
      print('Error fetching deals by category: $e');
      return [];
    }
  }

  /// Searches deals by product name
  Future<List<Deal>> searchDeals(String query) async {
    try {
      final allDeals = await scraperClient.fetchDeals();
      final lowerQuery = query.toLowerCase();

      return allDeals
          .where((deal) =>
              deal.productName.toLowerCase().contains(lowerQuery) ||
              (deal.category?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    } catch (e) {
      print('Error searching deals: $e');
      return [];
    }
  }

  /// Get statistics about available deals
  Future<Map<String, dynamic>> getStats() async {
    try {
      return await scraperClient.getStats();
    } catch (e) {
      print('Error fetching stats: $e');
      return {};
    }
  }

  /// Manually trigger scraping
  Future<void> triggerScrape() async {
    try {
      await scraperClient.triggerScrape();
    } catch (e) {
      print('Error triggering scrape: $e');
      rethrow;
    }
  }

  /// Get scraping status
  Future<Map<String, dynamic>> getScrapingStatus() async {
    try {
      return await scraperClient.getScrapingStatus();
    } catch (e) {
      print('Error getting scraping status: $e');
      return {};
    }
  }

  void dispose() {
    scraperClient.dispose();
  }
}
