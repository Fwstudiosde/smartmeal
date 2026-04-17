import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartmeal/features/admin/presentation/admin_login_screen.dart';
import 'package:smartmeal/features/admin/presentation/admin_home_screen.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';

class _AdminAuthRefreshNotifier extends ChangeNotifier {
  _AdminAuthRefreshNotifier(Ref ref) {
    ref.listen(adminAuthProvider, (_, __) => notifyListeners());
  }
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AdminAuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(adminAuthProvider).isLoggedIn;
      final goingToLogin = state.matchedLocation == '/';

      if (!isLoggedIn && !goingToLogin) return '/';
      if (isLoggedIn && goingToLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
    ],
  );
});
