import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://mededsdvznbtunrxyqnn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1lZGVkc2R2em5idHVucnh5cW5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMTU4MjYsImV4cCI6MjA4MjU5MTgyNn0.QOS6NJLZOke7HdOIidH3vCZGDNOVa8OdgTrWEk9gjs8';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

class BackendConfig {
  // Backend API URL - change this for production deployment
  static const String _devUrl = 'http://localhost:8000';
  static const String _prodUrl = 'https://smartmeal-backend-production.up.railway.app';

  // Set to true when deploying to production / App Store
  static const bool isProduction = true;

  static String get baseUrl => isProduction ? _prodUrl : _devUrl;
}
