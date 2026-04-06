import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' show UserModel;
import '../models/user_model.dart' as models;

// Get Supabase instance
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Auth State Notifier using Supabase
class AuthNotifier extends StateNotifier<models.AuthState> {
  final SupabaseClient supabase;

  AuthNotifier({required this.supabase}) : super(models.AuthState()) {
    _checkAuthStatus();
    _setupAuthListener();
  }

  /// Setup listener for auth state changes
  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        final user = _mapSupabaseUserToUserModel(session.user);
        state = state.authenticated(user, session.accessToken);
      } else {
        state = state.unauthenticated();
      }
    });
  }

  /// Check if user is already authenticated on app start
  Future<void> _checkAuthStatus() async {
    try {
      final session = supabase.auth.currentSession;
      if (session != null) {
        final user = _mapSupabaseUserToUserModel(session.user);
        state = state.authenticated(user, session.accessToken);
      } else {
        state = state.unauthenticated();
      }
    } catch (e) {
      state = state.unauthenticated();
    }
  }

  /// Map Supabase User to UserModel
  UserModel _mapSupabaseUserToUserModel(User supabaseUser) {
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      name: supabaseUser.userMetadata?['name'] as String? ??
            supabaseUser.userMetadata?['full_name'] as String?,
      createdAt: supabaseUser.createdAt,
    );
  }

  /// Register with email and password
  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.loading();
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      if (response.user != null && response.session != null) {
        final user = _mapSupabaseUserToUserModel(response.user!);
        state = state.authenticated(user, response.session!.accessToken);
      } else {
        state = state.withError('Registrierung fehlgeschlagen');
      }
    } on AuthException catch (e) {
      state = state.withError(e.message);
    } catch (e) {
      state = state.withError('Ein unerwarteter Fehler ist aufgetreten');
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.loading();
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        final user = _mapSupabaseUserToUserModel(response.user!);
        state = state.authenticated(user, response.session!.accessToken);
      } else {
        state = state.withError('Anmeldung fehlgeschlagen');
      }
    } on AuthException catch (e) {
      state = state.withError(e.message);
    } catch (e) {
      state = state.withError('Ein unerwarteter Fehler ist aufgetreten');
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.loading();
    try {
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'de.sparkoch.app://login-callback',
      );

      // The actual authentication happens through the redirect
      // The auth state listener will handle the session update
      if (!response) {
        state = state.withError('Apple Anmeldung abgebrochen');
      }
    } on AuthException catch (e) {
      state = state.withError(e.message);
    } catch (e) {
      state = state.withError('Apple Anmeldung fehlgeschlagen');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      state = state.unauthenticated();
    } catch (e) {
      // Still set to unauthenticated even if signOut fails
      state = state.unauthenticated();
    }
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, models.AuthState>((ref) {
  return AuthNotifier(
    supabase: ref.read(supabaseProvider),
  );
});

// Helper provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
