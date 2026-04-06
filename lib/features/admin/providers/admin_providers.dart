import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartmeal/core/services/api/admin_api_client.dart';

// Admin API Client Provider
final adminApiClientProvider = Provider<AdminApiClient>((ref) {
  return AdminApiClient();
});

// Secure storage for token
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Admin Auth State
class AdminAuthState {
  final bool isLoggedIn;
  final String? username;
  final String? error;

  AdminAuthState({
    required this.isLoggedIn,
    this.username,
    this.error,
  });

  AdminAuthState copyWith({
    bool? isLoggedIn,
    String? username,
    String? error,
  }) {
    return AdminAuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      username: username ?? this.username,
      error: error ?? this.error,
    );
  }
}

// Admin Auth Notifier
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  AdminAuthNotifier({
    required this.apiClient,
    required this.secureStorage,
  }) : super(AdminAuthState(isLoggedIn: false)) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final token = await secureStorage.read(key: 'admin_token');
      final username = await secureStorage.read(key: 'admin_username');

      if (token != null && username != null) {
        apiClient.setAccessToken(token);
        state = AdminAuthState(
          isLoggedIn: true,
          username: username,
        );
      }
    } catch (e) {
      // Ignore errors on initial load
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final success = await apiClient.login(username, password);

      if (success) {
        // Save token to secure storage
        final token = apiClient.accessToken!;
        await secureStorage.write(key: 'admin_token', value: token);
        await secureStorage.write(key: 'admin_username', value: username);

        state = AdminAuthState(
          isLoggedIn: true,
          username: username,
        );

        return true;
      } else {
        state = state.copyWith(
          isLoggedIn: false,
          error: 'Invalid credentials',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoggedIn: false,
        error: 'Login failed: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    apiClient.logout();
    await secureStorage.delete(key: 'admin_token');
    await secureStorage.delete(key: 'admin_username');

    state = AdminAuthState(isLoggedIn: false);
  }
}

// Admin Auth Provider
final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final apiClient = ref.watch(adminApiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return AdminAuthNotifier(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
});
