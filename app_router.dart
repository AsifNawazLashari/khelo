// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/tournament/tournament_list_page.dart';
import '../../presentation/pages/tournament/tournament_create_page.dart';
import '../../presentation/pages/tournament/tournament_detail_page.dart';
import '../../presentation/pages/tournament/fixture_generator_page.dart';
import '../../presentation/pages/team/team_list_page.dart';
import '../../presentation/pages/team/team_create_page.dart';
import '../../presentation/pages/team/team_detail_page.dart';
import '../../presentation/pages/player/player_create_page.dart';
import '../../presentation/pages/player/player_profile_page.dart';
import '../../presentation/pages/match/match_list_page.dart';
import '../../presentation/pages/match/match_detail_page.dart';
import '../../presentation/pages/match/scoring_page.dart';
import '../../presentation/pages/match/scorecard_page.dart';
import '../../presentation/pages/match/toss_page.dart';
import '../../presentation/pages/stats/stats_page.dart';
import '../../presentation/pages/scorer/scorer_token_page.dart';
import '../../presentation/pages/splash/splash_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.when(
        data: (user) => user != null,
        loading: () => null,
        error: (_, __) => false,
      );

      if (isAuthenticated == null) return '/splash';

      final location = state.matchedLocation;
      final onAuthPage = location == '/login' || location == '/register';

      if (!isAuthenticated && !onAuthPage && location != '/splash') {
        return '/login';
      }
      if (isAuthenticated && onAuthPage) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomePage(),
      ),

      // ─── Tournaments ─────────────────────────────────────────
      GoRoute(
        path: '/tournaments',
        builder: (_, __) => const TournamentListPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const TournamentCreatePage(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                TournamentDetailPage(tournamentId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'fixtures',
                builder: (_, state) => FixtureGeneratorPage(
                  tournamentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // ─── Teams ───────────────────────────────────────────────
      GoRoute(
        path: '/teams',
        builder: (_, __) => const TeamListPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const TeamCreatePage(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                TeamDetailPage(teamId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'players/add',
                builder: (_, state) => PlayerCreatePage(
                  teamId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'players/:playerId',
                builder: (_, state) => PlayerProfilePage(
                  playerId: state.pathParameters['playerId']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // ─── Matches ─────────────────────────────────────────────
      GoRoute(
        path: '/matches',
        builder: (_, __) => const MatchListPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                MatchDetailPage(matchId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'toss',
                builder: (_, state) =>
                    TossPage(matchId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'score',
                builder: (_, state) =>
                    ScoringPage(matchId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'scorecard',
                builder: (_, state) =>
                    ScorecardPage(matchId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),

      // ─── Stats ───────────────────────────────────────────────
      GoRoute(
        path: '/stats',
        builder: (_, __) => const StatsPage(),
      ),

      // ─── Scorer Token ─────────────────────────────────────────
      GoRoute(
        path: '/scorer-token',
        builder: (_, state) => ScorerTokenPage(
          tokenId: state.uri.queryParameters['token'],
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Route paths constants
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const tournaments = '/tournaments';
  static const tournamentCreate = '/tournaments/create';
  static String tournamentDetail(String id) => '/tournaments/$id';
  static String tournamentFixtures(String id) => '/tournaments/$id/fixtures';
  static const teams = '/teams';
  static const teamCreate = '/teams/create';
  static String teamDetail(String id) => '/teams/$id';
  static String addPlayer(String teamId) => '/teams/$teamId/players/add';
  static String playerProfile(String teamId, String playerId) =>
      '/teams/$teamId/players/$playerId';
  static const matches = '/matches';
  static String matchDetail(String id) => '/matches/$id';
  static String matchToss(String id) => '/matches/$id/toss';
  static String matchScore(String id) => '/matches/$id/score';
  static String matchScorecard(String id) => '/matches/$id/scorecard';
  static const stats = '/stats';
  static String scorerToken({String? token}) =>
      '/scorer-token${token != null ? '?token=$token' : ''}';
}
