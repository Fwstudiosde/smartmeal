import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInService {
  /// Sign in with Apple
  /// Returns a map with apple_id, email, and name
  Future<Map<String, String?>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Combine first and last name if available
      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName = [credential.givenName, credential.familyName]
            .where((name) => name != null && name.isNotEmpty)
            .join(' ');
      }

      return {
        'apple_id': credential.userIdentifier,
        'email': credential.email,
        'name': fullName,
      };
    } catch (e) {
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  /// Check if Apple Sign-In is available on this platform
  Future<bool> isAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      return false;
    }
  }
}
