import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartmeal/core/config/supabase_config.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _initialized = true;
      debugPrint('Push notifications initialized with token: ${token?.substring(0, 20)}...');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session == null) return;

      final userId = session.user.id;

      // Save token to user_profiles in Supabase
      await SupabaseConfig.client.from('user_profiles').upsert({
        'id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('FCM token saved to Supabase');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // The notification will be shown automatically by the system
    // on iOS. On Android, we might need to show it via local notifications.
  }

  /// Subscribe to deal alerts for specific supermarkets
  Future<void> subscribeToSupermarket(String storeName) async {
    final topic = 'deals_${storeName.toLowerCase().replaceAll(' ', '_')}';
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from deal alerts for a supermarket
  Future<void> unsubscribeFromSupermarket(String storeName) async {
    final topic = 'deals_${storeName.toLowerCase().replaceAll(' ', '_')}';
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Subscribe/unsubscribe based on user's preferred supermarkets
  Future<void> updateSubscriptions(List<String> preferredStores) async {
    final allStores = ['Lidl', 'ALDI', 'REWE', 'EDEKA', 'Kaufland', 'Penny', 'Netto'];

    for (final store in allStores) {
      if (preferredStores.contains(store)) {
        await subscribeToSupermarket(store);
      } else {
        await unsubscribeFromSupermarket(store);
      }
    }
  }

  /// Disable all push notifications
  Future<void> disableAll() async {
    final allStores = ['Lidl', 'ALDI', 'REWE', 'EDEKA', 'Kaufland', 'Penny', 'Netto'];
    for (final store in allStores) {
      await unsubscribeFromSupermarket(store);
    }
  }
}
