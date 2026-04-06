import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/home/presentation/home_screen.dart';
import 'package:smartmeal/features/fridge_scanner/presentation/fridge_scanner_screen.dart';
import 'package:smartmeal/features/fridge_scanner/presentation/ingredients_screen.dart';
import 'package:smartmeal/features/fridge_scanner/presentation/recipe_results_screen.dart';
import 'package:smartmeal/features/deals_scanner/presentation/deals_scanner_screen.dart';
import 'package:smartmeal/features/deals_scanner/presentation/deal_recipes_screen.dart';
import 'package:smartmeal/features/deals_scanner/presentation/create_custom_recipe_screen.dart';
import 'package:smartmeal/features/recipe_detail/presentation/recipe_detail_screen.dart';
import 'package:smartmeal/features/settings/presentation/settings_screen.dart';
import 'package:smartmeal/features/admin/presentation/admin_login_screen.dart';
import 'package:smartmeal/features/admin/presentation/admin_verification_screen.dart';
import 'package:smartmeal/features/admin/presentation/admin_home_screen.dart';
import 'package:smartmeal/features/cart/presentation/cart_screen.dart';
import 'package:smartmeal/features/fridge_scanner/presentation/pantry_screen.dart';
import 'package:smartmeal/features/fridge_scanner/presentation/fridge_scan_screen.dart';
import 'package:smartmeal/core/navigation/main_navigation.dart';
import 'package:smartmeal/core/auth/providers/auth_provider.dart';
import 'package:smartmeal/features/auth/screens/welcome_screen.dart';

// Auth state change notifier for GoRouter
class AuthStateNotifier extends ChangeNotifier {
  final Ref ref;

  AuthStateNotifier(this.ref) {
    ref.listen(isAuthenticatedProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ref.watch(authStateNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final isAuth = ref.read(isAuthenticatedProvider);
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;
      final isGoingToWelcome = state.matchedLocation == '/welcome';
      final isGoingToAdmin = state.matchedLocation.startsWith('/admin');

      // If not authenticated and not going to welcome or admin, redirect to welcome
      if (!isAuth && !isGoingToWelcome && !isGoingToAdmin) {
        return '/welcome';
      }

      // If authenticated and going to welcome, redirect based on user
      if (isAuth && isGoingToWelcome) {
        // Check if user is admin account - redirect to admin verification
        if (userEmail == 'finn-weinnoldt@outlook.de') {
          return '/admin/verify';
        }
        // Regular user - redirect to home
        return '/';
      }

      // If authenticated as admin user and going to home, redirect to admin verify
      if (isAuth && userEmail == 'finn-weinnoldt@outlook.de' && state.matchedLocation == '/') {
        return '/admin/verify';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/fridge',
            name: 'fridge',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const FridgeScannerScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/deals',
            name: 'deals',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DealsScannerScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CartScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/deal-recipes',
            name: 'deal-recipes',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DealRecipesScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/fridge-scan',
        name: 'fridge-scan',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FridgeScanScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/pantry',
        name: 'pantry',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PantryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/ingredients',
        name: 'ingredients',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const IngredientsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/recipe-results',
        name: 'recipe-results',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RecipeResultsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/create-custom-recipe',
        name: 'create-custom-recipe',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateCustomRecipeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/recipe/:id',
        name: 'recipe-detail',
        pageBuilder: (context, state) {
          final extra = state.extra as dynamic;
          // Handle both Recipe and DealRecipe types
          final recipe = extra is DealRecipe ? extra.recipe : extra as Recipe;
          final dealRecipe = extra is DealRecipe ? extra : null;

          return CustomTransitionPage(
            key: state.pageKey,
            child: RecipeDetailScreen(
              recipe: recipe,
              dealRecipe: dealRecipe,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/admin/verify',
        name: 'admin-verify',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminVerificationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/admin/home',
        name: 'admin-home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
  );
});
