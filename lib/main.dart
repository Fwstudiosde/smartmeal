import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartmeal/firebase_options.dart';
import 'package:smartmeal/l10n/app_localizations.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/router/app_router.dart';
import 'package:smartmeal/core/config/supabase_config.dart';
import 'package:smartmeal/features/settings/presentation/settings_screen.dart';
import 'package:smartmeal/core/services/notification_service.dart';
import 'package:smartmeal/core/services/push_notification_service.dart';

// Locale provider backed by Hive
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('de')) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box('settings');
      final langCode = box.get('language', defaultValue: 'de') as String;
      state = Locale(langCode);
    } catch (_) {}
  }

  void setLocale(Locale locale) {
    state = locale;
    try {
      final box = Hive.box('settings');
      box.put('language', locale.languageCode);
    } catch (_) {}
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (not available on web)
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('ingredients');
  await Hive.openBox('recipes');
  await Hive.openBox('deals');
  await Hive.openBox('settings');

  // Initialize notifications (not available on web)
  if (!kIsWeb) {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();

    // Initialize push notifications (Firebase Cloud Messaging)
    final pushService = PushNotificationService();
    await pushService.initialize();
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SmartMealApp(),
    ),
  );
}

class SmartMealApp extends ConsumerWidget {
  const SmartMealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDarkMode = ref.watch(darkModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'SmartMeal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('fr'),
        Locale('es'),
      ],
      routerConfig: router,
    );
  }
}
