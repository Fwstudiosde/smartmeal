import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Android notification channel for deal alerts
  static const AndroidNotificationChannel _dealChannel = AndroidNotificationChannel(
    'deal_alerts',
    'Angebots-Benachrichtigungen',
    description: 'Benachrichtigungen über neue Supermarkt-Angebote',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized) return;

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_dealChannel);

    // Initialize local notifications for foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

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

      // Handle foreground messages — show as local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Show notification on iOS even when app is in foreground
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

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
    final notification = message.notification;
    if (notification == null) return;

    // Show as local notification on Android (iOS handles it via setForegroundNotificationPresentationOptions)
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dealChannel.id,
          _dealChannel.name,
          channelDescription: _dealChannel.description,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
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
