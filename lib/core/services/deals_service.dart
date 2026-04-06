import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/api/deals_api_client.dart';
import 'package:uuid/uuid.dart';

// Provider for Backend Data Source
final backendDataSourceProvider = Provider<BackendDealsDataSource>(
  (ref) => BackendDealsDataSource(),
);

// Provider for Deals Service
final dealsServiceProvider = Provider<DealsService>((ref) {
  return DealsService(
    backendDataSource: ref.watch(backendDataSourceProvider),
  );
});

class DealsService {
  final _uuid = const Uuid();
  final BackendDealsDataSource backendDataSource;

  DealsService({required this.backendDataSource});

  /// Gets list of available supermarkets
  Future<List<Supermarket>> getSupermarkets() async {
    try {
      // Try to fetch from backend first
      final supermarkets = await backendDataSource.getSupermarkets();
      if (supermarkets.isNotEmpty) {
        return supermarkets;
      }
    } catch (e) {
      print('Error fetching supermarkets from backend, using fallback: $e');
    }

    // Fallback to predefined list
    return Supermarket.all;
  }

  /// Fetches current deals from backend API
  Future<List<Deal>> fetchDeals({List<String>? storeIds}) async {
    try {
      // Fetch real deals from backend
      final deals = await backendDataSource.fetchDeals(storeIds: storeIds);

      if (deals.isNotEmpty) {
        return deals;
      }

      // If no deals from backend, return empty list (no fallback to mock data)
      return [];
    } catch (e) {
      print('Error fetching deals from backend: $e');

      // Return empty list on error (no mock data fallback)
      return [];
    }
  }

  /// Fetches deals by category
  Future<List<Deal>> fetchDealsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final allDeals = _getMockDeals();
    return allDeals.where((deal) => 
      deal.category?.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  /// Searches deals by product name
  Future<List<Deal>> searchDeals(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final allDeals = _getMockDeals();
    final lowerQuery = query.toLowerCase();
    
    return allDeals.where((deal) => 
      deal.productName.toLowerCase().contains(lowerQuery) ||
      (deal.category?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  List<Deal> _getMockDeals() {
    final now = DateTime.now();
    final validFrom = now.subtract(const Duration(days: 1));
    final validUntil = now.add(const Duration(days: 6));
    
    return [
      // Lidl Deals
      Deal(
        id: _uuid.v4(),
        productName: 'Hähnchenbrust',
        storeName: 'Lidl',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Lidl-Logo.svg/1200px-Lidl-Logo.svg.png',
        originalPrice: 6.99,
        discountPrice: 4.99,
        discountPercentage: 29,
        imageUrl: 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Fleisch',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Bio Brokkoli',
        storeName: 'Lidl',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Lidl-Logo.svg/1200px-Lidl-Logo.svg.png',
        originalPrice: 2.49,
        discountPrice: 1.49,
        discountPercentage: 40,
        imageUrl: 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Gemüse',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Basmati Reis 1kg',
        storeName: 'Lidl',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Lidl-Logo.svg/1200px-Lidl-Logo.svg.png',
        originalPrice: 3.29,
        discountPrice: 2.29,
        discountPercentage: 30,
        imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Grundnahrungsmittel',
      ),
      
      // ALDI Deals
      Deal(
        id: _uuid.v4(),
        productName: 'Rinderhackfleisch 500g',
        storeName: 'ALDI',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/AldiSudLogo.svg/1200px-AldiSudLogo.svg.png',
        originalPrice: 5.49,
        discountPrice: 3.99,
        discountPercentage: 27,
        imageUrl: 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Fleisch',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Frische Pasta',
        storeName: 'ALDI',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/AldiSudLogo.svg/1200px-AldiSudLogo.svg.png',
        originalPrice: 2.99,
        discountPrice: 1.99,
        discountPercentage: 33,
        imageUrl: 'https://images.unsplash.com/photo-1551462147-37885acc36f1?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Grundnahrungsmittel',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Mozzarella 3er Pack',
        storeName: 'ALDI',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/AldiSudLogo.svg/1200px-AldiSudLogo.svg.png',
        originalPrice: 3.49,
        discountPrice: 2.49,
        discountPercentage: 29,
        imageUrl: 'https://images.unsplash.com/photo-1571167530149-c1105da4c2c7?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Milchprodukte',
      ),
      
      // REWE Deals
      Deal(
        id: _uuid.v4(),
        productName: 'Lachs Filet 300g',
        storeName: 'REWE',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Rewe_Markt_Logo.svg/1200px-Rewe_Markt_Logo.svg.png',
        originalPrice: 8.99,
        discountPrice: 5.99,
        discountPercentage: 33,
        imageUrl: 'https://images.unsplash.com/photo-1574781330855-d0db8cc6a79c?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Fisch',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Avocado 2er Pack',
        storeName: 'REWE',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Rewe_Markt_Logo.svg/1200px-Rewe_Markt_Logo.svg.png',
        originalPrice: 2.99,
        discountPrice: 1.99,
        discountPercentage: 33,
        imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Obst',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Bio Eier 10er',
        storeName: 'REWE',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Rewe_Markt_Logo.svg/1200px-Rewe_Markt_Logo.svg.png',
        originalPrice: 4.49,
        discountPrice: 2.99,
        discountPercentage: 33,
        imageUrl: 'https://images.unsplash.com/photo-1569288052389-dac9b01c9c05?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Milchprodukte',
      ),
      
      // EDEKA Deals
      Deal(
        id: _uuid.v4(),
        productName: 'Parmesan Stück 200g',
        storeName: 'EDEKA',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Edeka_logo.svg/1200px-Edeka_logo.svg.png',
        originalPrice: 5.99,
        discountPrice: 3.99,
        discountPercentage: 33,
        imageUrl: 'https://images.unsplash.com/photo-1552767059-ce182ead6c1b?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Milchprodukte',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Cherry Tomaten 500g',
        storeName: 'EDEKA',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Edeka_logo.svg/1200px-Edeka_logo.svg.png',
        originalPrice: 3.49,
        discountPrice: 2.29,
        discountPercentage: 34,
        imageUrl: 'https://images.unsplash.com/photo-1546470427-227c7ba5d6ac?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Gemüse',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Olivenöl Extra Vergine 500ml',
        storeName: 'EDEKA',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Edeka_logo.svg/1200px-Edeka_logo.svg.png',
        originalPrice: 7.99,
        discountPrice: 5.49,
        discountPercentage: 31,
        imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Öl & Essig',
      ),
      
      // Kaufland Deals
      Deal(
        id: _uuid.v4(),
        productName: 'Paprika Mix 500g',
        storeName: 'Kaufland',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Kaufland_201x_logo.svg/1200px-Kaufland_201x_logo.svg.png',
        originalPrice: 2.99,
        discountPrice: 1.79,
        discountPercentage: 40,
        imageUrl: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Gemüse',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Sahne 30% 500ml',
        storeName: 'Kaufland',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Kaufland_201x_logo.svg/1200px-Kaufland_201x_logo.svg.png',
        originalPrice: 2.29,
        discountPrice: 1.49,
        discountPercentage: 35,
        imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Milchprodukte',
      ),
      
      // Penny Deals
      Deal(
        id: _uuid.v4(),
        productName: 'Zwiebeln 2kg Netz',
        storeName: 'Penny',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Penny-Logo.svg/1200px-Penny-Logo.svg.png',
        originalPrice: 2.49,
        discountPrice: 1.29,
        discountPercentage: 48,
        imageUrl: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Gemüse',
      ),
      Deal(
        id: _uuid.v4(),
        productName: 'Butter 250g',
        storeName: 'Penny',
        storeLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Penny-Logo.svg/1200px-Penny-Logo.svg.png',
        originalPrice: 2.89,
        discountPrice: 1.99,
        discountPercentage: 31,
        imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400',
        validFrom: validFrom,
        validUntil: validUntil,
        category: 'Milchprodukte',
      ),
    ];
  }
}
