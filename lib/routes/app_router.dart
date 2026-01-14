import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quotevault/features/auth/presentation/home_screen.dart';
import 'package:quotevault/features/auth/presentation/settings.dart';
import 'package:quotevault/features/auth/presentation/signup_screen.dart';
import 'package:quotevault/features/quotes/presentation/favorite_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/quotes/presentation/quote_list_screen.dart';
import '../core/providers/supabase_provider.dart';

final routerProvider = Provider((ref) {
  final supabase = ref.read(supabaseProvider);

  return GoRouter(
    observers: [routeObserver],

    redirect: (context, state) {
      final user = supabase.auth.currentUser;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' || location == '/signup';

      if (user == null && !isAuthRoute) {
        return '/login';
      }

      if (user != null && isAuthRoute) {
        return '/';
      }

      return null;
    },

    /*     redirect: (_, __) {
      final user = supabase.auth.currentUser;
      return user == null ? '/login' : '/';
    },
 */
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/quotes',
        builder: (context, state) => const QuoteListScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
    ],
  );
});

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
