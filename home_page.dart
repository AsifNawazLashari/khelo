// lib/presentation/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final liveMatches = ref.watch(liveMatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(userProfile),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  _DashboardTab(),
                  TournamentListPage(),
                  MatchListPage(),
                  StatsPageContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showQuickActions(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHeader(AsyncValue userProfile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('A7',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'Rajdhani',
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cricket A7',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                userProfile.when(
                  data: (u) => Text(
                    u != null ? '${_greeting()}, ${u.displayName.split(' ').first}' : '',
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          userProfile.when(
            data: (u) => GestureDetector(
              onTap: () => _showProfileMenu(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.bgElevated,
                child: Text(
                  u?.displayName.isNotEmpty == true
                      ? u!.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800,
                    fontSize: 16, fontFamily: 'Rajdhani',
                  ),
                ),
              ),
            ),
            loading: () => const CircularProgressIndicator(strokeWidth: 2),
            error: (_, __) => const Icon(Icons.person),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events_outlined),
        activeIcon: Icon(Icons.emoji_events),
        label: 'Tournaments',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.sports_cricket_outlined),
        activeIcon: Icon(Icons.sports_cricket),
        label: 'Matches',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Stats',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: items,
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showQuickActions(BuildContext context) {
    final userProfile = ref.read(currentUserProfileProvider).value;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Quick Actions',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 16),
            if (userProfile?.isOrganizer == true)
              _QuickActionTile(
                icon: Icons.emoji_events_outlined,
                label: 'Create Tournament',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.tournamentCreate);
                },
              ),
            if (userProfile?.isCaptain == true ||
                userProfile?.isOrganizer == true)
              _QuickActionTile(
                icon: Icons.group_add_outlined,
                label: 'Create Team',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.teamCreate);
                },
              ),
            if (userProfile?.isScorer == true)
              _QuickActionTile(
                icon: Icons.qr_code_scanner_outlined,
                label: 'Claim Scorer Token',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.scorerToken());
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final profile = ref.read(currentUserProfileProvider).value;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  profile?.displayName.isNotEmpty == true
                      ? profile!.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800,
                    fontSize: 28, fontFamily: 'Rajdhani',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(profile?.displayName ?? '',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text(profile?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted,
                  )),
              const SizedBox(height: 8),
              if (profile != null) RoleBadge(role: profile.role),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Sign Out',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
              const SizedBox(height: 8),
              const Text('Cricket A7 by A7 Studio • asifnawazlashari',
                  style: TextStyle(
                    color: AppColors.textMuted, fontSize: 11,
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          )),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}

// Dashboard Tab
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveMatches = ref.watch(liveMatchesProvider);
    final allTournaments = ref.watch(allTournamentsProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats summary
          Row(
            children: [
              Expanded(
                child: allTournaments.when(
                  data: (t) => StatCard(
                    label: 'Tournaments',
                    value: '${t.length}',
                    icon: Icons.emoji_events_outlined,
                  ),
                  loading: () => const _ShimmerCard(),
                  error: (_, __) => const StatCard(label: 'Tournaments', value: '-'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: liveMatches.when(
                  data: (m) => StatCard(
                    label: 'Live Matches',
                    value: '${m.length}',
                    icon: Icons.sports_cricket,
                    valueColor: m.isNotEmpty ? AppColors.live : null,
                  ),
                  loading: () => const _ShimmerCard(),
                  error: (_, __) => const StatCard(label: 'Live Matches', value: '-'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Live Matches Section
          liveMatches.when(
            data: (matches) {
              if (matches.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SectionHeader(title: 'Live Now'),
                      const SizedBox(width: 8),
                      const LiveBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...matches.take(3).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LiveMatchCard(match: m),
                  )),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Recent Tournaments
          const SectionHeader(title: 'Tournaments'),
          const SizedBox(height: 12),
          allTournaments.when(
            data: (tournaments) {
              if (tournaments.isEmpty) {
                return EmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'No Tournaments',
                  subtitle: 'Create your first cricket tournament to get started.',
                  action: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.tournamentCreate),
                    child: const Text('Create Tournament'),
                  ),
                );
              }
              return Column(
                children: tournaments.take(3).map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TournamentCard(tournament: t),
                )).toList(),
              );
            },
            loading: () => const _ShimmerCard(),
            error: (_, __) => const Text('Failed to load tournaments'),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  final MatchModel match;
  const _LiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final entity = match.toEntity();
    final firstInnings = entity.firstInnings;
    final secondInnings = entity.secondInnings;

    return A7Card(
      onTap: () => context.push(AppRoutes.matchDetail(match.id)),
      child: Column(
        children: [
          Row(
            children: [
              const LiveBadge(),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(match.format,
                    style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted,
                      fontWeight: FontWeight.w700, letterSpacing: 0.5,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.homeTeamName,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    if (firstInnings != null &&
                        firstInnings.battingTeamId == match.homeTeamId)
                      Text(firstInnings.score,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('vs',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(match.awayTeamName,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    if (firstInnings != null &&
                        firstInnings.battingTeamId == match.awayTeamId)
                      Text(firstInnings.score,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return A7Card(
      onTap: () => context.push(AppRoutes.tournamentDetail(tournament.id)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tournament.name,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                Row(
                  children: [
                    Text(tournament.format,
                        style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted,
                        )),
                    const Text(' • '),
                    Text('${tournament.teamIds.length} teams',
                        style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted,
                        )),
                  ],
                ),
              ],
            ),
          ),
          _StatusChip(status: tournament.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active' => (AppColors.success, 'ACTIVE'),
      'completed' => (AppColors.textMuted, 'DONE'),
      'upcoming' => (AppColors.info, 'UPCOMING'),
      _ => (AppColors.textMuted, status.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 10, color: color,
            fontWeight: FontWeight.w800, letterSpacing: 0.5,
          )),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

// These are defined in other files but needed for IndexedStack
class TournamentListPage extends StatelessWidget {
  const TournamentListPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _TournamentListContent();
}

class MatchListPage extends StatelessWidget {
  const MatchListPage({super.key});
  @override
  Widget build(BuildContext context) => const _MatchListContent();
}

class StatsPageContent extends StatelessWidget {
  const StatsPageContent({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Stats', style: TextStyle(color: AppColors.textPrimary)),
  );
}

class _TournamentListContent extends ConsumerWidget {
  const _TournamentListContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(allTournamentsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: tournaments.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No Tournaments',
                subtitle: 'No tournaments have been created yet.',
                action: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.tournamentCreate),
                  child: const Text('Create Tournament'),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TournamentCard(tournament: list[i]),
                ),
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MatchListContent extends ConsumerWidget {
  const _MatchListContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveMatches = ref.watch(liveMatchesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: liveMatches.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.sports_cricket_outlined,
                title: 'No Live Matches',
                subtitle: 'No matches are currently in progress.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LiveMatchCard(match: list[i]),
                ),
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
