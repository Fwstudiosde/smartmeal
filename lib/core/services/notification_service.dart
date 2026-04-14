import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartmeal/core/models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    // Android 13+ requires explicit permission
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showExpiryNotification({
    required int id,
    required String itemName,
    required int daysUntilExpiry,
  }) async {
    final String title;
    final String body;

    if (daysUntilExpiry <= 0) {
      title = 'Abgelaufen!';
      body = '$itemName ist abgelaufen. Bitte pruefen!';
    } else if (daysUntilExpiry == 1) {
      title = 'Laeuft morgen ab!';
      body = '$itemName laeuft morgen ab.';
    } else {
      title = 'Bald ablaufend';
      body = '$itemName laeuft in $daysUntilExpiry Tagen ab.';
    }

    final androidDetails = AndroidNotificationDetails(
      'expiry_reminders',
      'Ablauf-Erinnerungen',
      channelDescription: 'Erinnerungen fuer ablaufende Lebensmittel',
      importance: Importance.high,
      priority: daysUntilExpiry <= 1 ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}

class ExpiryCheckerService {
  static final NotificationService _notificationService = NotificationService();

  /// Check all pantry items and send notifications for expiring ones
  static Future<void> checkExpiringItems(List<PantryItem> items) async {
    final settingsBox = Hive.box('settings');
    final enabled = settingsBox.get('expiry_reminders', defaultValue: false) as bool;
    if (!enabled) return;

    // Cancel previous notifications before scheduling new ones
    await _notificationService.cancelAll();

    int notificationId = 1000;

    for (final item in items) {
      if (item.expiryDate == null) continue;

      final daysUntilExpiry = item.expiryDate!.difference(DateTime.now()).inDays;

      // Notify for items expiring within 3 days or already expired
      if (daysUntilExpiry <= 3) {
        try {
          await _notificationService.showExpiryNotification(
            id: notificationId++,
            itemName: item.name,
            daysUntilExpiry: daysUntilExpiry,
          );
        } catch (e) {
          debugPrint('Error showing expiry notification: $e');
        }
      }
    }
  }
}
