import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/providers/auth_provider.dart';
import '../../../core/auth/providers/community_profile_provider.dart';
import '../../../core/services/avatar_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/fridge_scanner/providers/pantry_provider.dart';
import '../../../main.dart' show localeProvider;

// Persistent Settings Providers backed by Hive 'settings' box
final darkModeProvider = StateNotifierProvider<_BoolSettingNotifier, bool>((ref) {
  return _BoolSettingNotifier('dark_mode', false);
});
final notificationsProvider = StateNotifierProvider<_BoolSettingNotifier, bool>((ref) {
  return _BoolSettingNotifier('notifications', true);
});
final dealAlertsProvider = StateNotifierProvider<_BoolSettingNotifier, bool>((ref) {
  return _BoolSettingNotifier('deal_alerts', true);
});
final metricUnitsProvider = StateNotifierProvider<_BoolSettingNotifier, bool>((ref) {
  return _BoolSettingNotifier('metric_units', true);
});
final expiryRemindersProvider = StateNotifierProvider<_BoolSettingNotifier, bool>((ref) {
  return _BoolSettingNotifier('expiry_reminders', false);
});

class _BoolSettingNotifier extends StateNotifier<bool> {
  final String _key;
  _BoolSettingNotifier(this._key, bool defaultValue)
      : super(defaultValue) {
    _load(defaultValue);
  }

  void _load(bool defaultValue) {
    try {
      final box = Hive.box('settings');
      state = box.get(_key, defaultValue: defaultValue) as bool;
    } catch (_) {}
  }

  void toggle() {
    state = !state;
    _save();
  }

  void set(bool value) {
    state = value;
    _save();
  }

  void _save() {
    try {
      final box = Hive.box('settings');
      box.put(_key, state);
    } catch (_) {}
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Einstellungen'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(context, ref),
            const SizedBox(height: 24),
            _buildSectionTitle('Allgemein'),
            _buildGeneralSettings(context, ref),
            const SizedBox(height: 24),
            _buildSectionTitle('Benachrichtigungen'),
            _buildNotificationSettings(context, ref),
            const SizedBox(height: 24),
            _buildSectionTitle('Supermärkte'),
            _buildSupermarketSettings(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Über die App'),
            _buildAboutSection(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Konto'),
            _buildAccountSection(context, ref),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final user = authState.user;
    final currentDisplayName = ref.read(displayNameProvider);

    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final displayNameCtrl = TextEditingController(text: currentDisplayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profil bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile image with picker
            GestureDetector(
              onTap: () => _showImagePickerOptions(ctx, ref),
              child: Stack(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ref.watch(profileImageUrlProvider) != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CachedNetworkImage(
                              imageUrl: ref.watch(profileImageUrlProvider)!,
                              width: 80, height: 80, fit: BoxFit.cover,
                              placeholder: (_, __) => const Icon(Iconsax.user, size: 40, color: AppTheme.primaryColor),
                              errorWidget: (_, __, ___) => const Icon(Iconsax.user, size: 40, color: AppTheme.primaryColor),
                            ),
                          )
                        : const Icon(Iconsax.user, size: 40, color: AppTheme.primaryColor),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.camera, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Iconsax.user),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayNameCtrl,
              decoration: InputDecoration(
                labelText: 'Anzeigename (Community)',
                hintText: 'z.B. KochProfi92',
                prefixIcon: const Icon(Iconsax.people),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Wird bei deinen Community-Rezepten angezeigt',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'E-Mail',
                prefixIcon: const Icon(Iconsax.sms),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: user?.email ?? '',
              ),
              controller: TextEditingController(text: user?.email ?? ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final newDisplayName = displayNameCtrl.text.trim();
              if (newDisplayName.isNotEmpty) {
                ref.read(displayNameProvider.notifier).setName(newDisplayName);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil aktualisiert'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final communityName = ref.watch(displayNameProvider);

    final displayName = user?.name?.isNotEmpty == true ? user!.name! : user?.email ?? 'Gast-Benutzer';
    final subtitle = user != null
        ? (user.name?.isNotEmpty == true ? user.email : 'Angemeldet')
        : 'Anmelden fuer mehr Features';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ref.watch(profileImageUrlProvider) != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: ref.watch(profileImageUrlProvider)!,
                      width: 70, height: 70, fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Iconsax.user, color: Colors.white, size: 36),
                      errorWidget: (_, __, ___) => const Icon(Iconsax.user, color: Colors.white, size: 36),
                    ),
                  )
                : const Icon(Iconsax.user, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                if (communityName != null && communityName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Iconsax.people, size: 14, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        communityName,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.edit, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    final useMetric = ref.watch(metricUnitsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Iconsax.moon,
            title: 'Dunkler Modus',
            subtitle: 'Augenschonende Darstellung',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) =>
                  ref.read(darkModeProvider.notifier).set(value),
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.ruler,
            title: 'Metrische Einheiten',
            subtitle: 'Gramm, Liter, etc.',
            trailing: Switch(
              value: useMetric,
              onChanged: (value) =>
                  ref.read(metricUnitsProvider.notifier).set(value),
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.language_square,
            title: 'Sprache',
            subtitle: _getLanguageName(ref.watch(localeProvider).languageCode),
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _showLanguageDialog(context, ref),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.trash,
            title: 'Cache leeren',
            subtitle: 'Zwischengespeicherte Daten löschen',
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _showClearCacheDialog(context),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildNotificationSettings(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final dealAlerts = ref.watch(dealAlertsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Iconsax.notification,
            title: 'Benachrichtigungen',
            subtitle: 'Push-Benachrichtigungen aktivieren',
            trailing: Switch(
              value: notifications,
              onChanged: (value) =>
                  ref.read(notificationsProvider.notifier).set(value),
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.discount_shape,
            title: 'Angebots-Alerts',
            subtitle: 'Bei neuen Angeboten benachrichtigen',
            trailing: Switch(
              value: dealAlerts,
              onChanged: notifications
                  ? (value) =>
                      ref.read(dealAlertsProvider.notifier).set(value)
                  : null,
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.timer_1,
            title: 'Ablauf-Erinnerungen',
            subtitle: 'Benachrichtigung bei ablaufenden Produkten',
            trailing: Switch(
              value: ref.watch(expiryRemindersProvider),
              onChanged: (value) {
                ref.read(expiryRemindersProvider.notifier).set(value);
                if (value) {
                  final items = ref.read(pantryProvider);
                  ExpiryCheckerService.checkExpiringItems(items);
                } else {
                  NotificationService().cancelAll();
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSupermarketSettings(BuildContext context) {
    final supermarkets = [
      {'name': 'Lidl', 'color': const Color(0xFF0050AA)},
      {'name': 'ALDI', 'color': const Color(0xFF00005F)},
      {'name': 'REWE', 'color': const Color(0xFFCC071E)},
      {'name': 'EDEKA', 'color': const Color(0xFFFFE500)},
      {'name': 'Kaufland', 'color': const Color(0xFFE10019)},
      {'name': 'Penny', 'color': const Color(0xFFCD1719)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Iconsax.shop,
            title: 'Bevorzugte Supermärkte',
            subtitle: 'Alle Supermärkte aktiv',
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: supermarkets.map((market) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (market['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (market['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: market['color'] as Color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        market['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: (market['color'] as Color) == const Color(0xFFFFE500)
                              ? Colors.black87
                              : market['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Iconsax.info_circle,
            title: 'Über SmartMeal',
            subtitle: 'Version 1.0.0',
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.document,
            title: 'Datenschutz',
            subtitle: 'Datenschutzerklärung lesen',
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _openUrl('https://sparkoch.de/datenschutz'),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.document_text,
            title: 'Nutzungsbedingungen',
            subtitle: 'AGB lesen',
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _openUrl('https://sparkoch.de/agb'),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.message_question,
            title: 'Hilfe & Support',
            subtitle: 'FAQ und Kontakt',
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _openUrl('mailto:support@fwstudios.de'),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Iconsax.star,
            title: 'App bewerten',
            subtitle: 'Im App Store bewerten',
            trailing: const Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary,
            ),
            onTap: () => _openUrl('https://apps.apple.com/app/sparkoch/id0000000000'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'de': return 'Deutsch';
      case 'en': return 'English';
      case 'fr': return 'Français';
      case 'es': return 'Español';
      default: return 'Deutsch';
    }
  }

  void _showImagePickerOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.camera, color: AppTheme.primaryColor),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: AppTheme.primaryColor),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ref, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(WidgetRef ref, ImageSource source) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    final url = await AvatarService.pickAndUploadAvatar(
      userId: userId,
      source: source,
    );

    if (url != null) {
      ref.read(profileImageUrlProvider.notifier).state = url;
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sprache wählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, ref, 'Deutsch', const Locale('de'), currentLocale.languageCode == 'de'),
            _buildLanguageOption(context, ref, 'English', const Locale('en'), currentLocale.languageCode == 'en'),
            _buildLanguageOption(context, ref, 'Français', const Locale('fr'), currentLocale.languageCode == 'fr'),
            _buildLanguageOption(context, ref, 'Español', const Locale('es'), currentLocale.languageCode == 'es'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, String language, Locale locale, bool isSelected) {
    return ListTile(
      title: Text(language),
      trailing: isSelected
          ? const Icon(Iconsax.tick_circle, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(context);
      },
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Cache leeren'),
        content: const Text(
          'Möchtest du alle zwischengespeicherten Daten löschen? Dies kann die App-Leistung vorübergehend beeinträchtigen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Clear all Hive boxes
                await Hive.box('ingredients').clear();
                await Hive.box('recipes').clear();
                await Hive.box('deals').clear();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cache wurde geleert'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Iconsax.cpu,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SmartMeal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dein intelligenter Küchenassistent.\nScanne deinen Kühlschrank, finde Rezepte und spare mit Angeboten.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 SmartMeal',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.red,
          ),
        ),
        title: const Text(
          'Abmelden',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        subtitle: const Text(
          'Von diesem Gerät abmelden',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Iconsax.arrow_right_3, size: 20, color: Colors.red),
        onTap: () async {
          await ref.read(authProvider.notifier).logout();
        },
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
}
