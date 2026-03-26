// lib/presentation/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/datasources/firebase_auth_service.dart';
import '../../data/datasources/firestore_match_service.dart';
import '../../data/datasources/firestore_services.dart';
import '../../data/models/models.dart';
import '../../domain/entities/entities.dart';

// ─── Firebase Providers ──────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

// ─── Service Providers ───────────────────────────────────────────────────────

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final matchServiceProvider = Provider<FirestoreMatchService>((ref) {
  return FirestoreMatchService(
    firestore: ref.watch(firestoreProvider),
  );
});

final tournamentServiceProvider = Provider<FirestoreTournamentService>((ref) {
  return FirestoreTournamentService(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(storageProvider),
  );
});

final teamServiceProvider = Provider<FirestoreTeamService>((ref) {
  return FirestoreTeamService(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(storageProvider),
  );
});

final playerServiceProvider = Provider<FirestorePlayerService>((ref) {
  return FirestorePlayerService(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(storageProvider),
  );
});

// ─── Auth Providers ──────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authServiceProvider).watchCurrentUserProfile();
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  return user.when(
    data: (u) => u != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

final userRoleProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  return profile.when(
    data: (u) => u?.role,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ─── Auth State Notifier ─────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FirebaseAuthService _service;

  AuthNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _service.authStateChanges.listen((user) async {
      if (user == null) {
        state = const AsyncValue.data(null);
      } else {
        final profile = await _service.getCurrentUserProfile();
        state = AsyncValue.data(profile);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.signInWithEmailPassword(
        email: email, password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.signUpWithEmailPassword(
        email: email, password: password,
        displayName: displayName, role: role,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> sendPasswordReset(String email) async {
    await _service.sendPasswordResetEmail(email);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// ─── Tournament Providers ─────────────────────────────────────────────────────

final allTournamentsProvider = StreamProvider<List<TournamentModel>>((ref) {
  return ref.watch(tournamentServiceProvider).watchAllTournaments();
});

final organizerTournamentsProvider =
    StreamProvider.family<List<TournamentModel>, String>((ref, uid) {
  return ref.watch(tournamentServiceProvider).watchOrganizerTournaments(uid);
});

final tournamentProvider =
    StreamProvider.family<TournamentModel?, String>((ref, id) {
  return ref.watch(tournamentServiceProvider).watchTournament(id);
});

// ─── Team Providers ───────────────────────────────────────────────────────────

final allTeamsProvider = StreamProvider<List<TeamModel>>((ref) {
  return ref.watch(teamServiceProvider).watchAllTeams();
});

final captainTeamsProvider =
    StreamProvider.family<List<TeamModel>, String>((ref, captainId) {
  return ref.watch(teamServiceProvider).watchCaptainTeams(captainId);
});

final teamPlayersProvider =
    StreamProvider.family<List<PlayerModel>, String>((ref, teamId) {
  return ref.watch(playerServiceProvider).watchTeamPlayers(teamId);
});

// ─── Match Providers ──────────────────────────────────────────────────────────

final liveMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(matchServiceProvider).watchLiveMatches();
});

final matchProvider =
    StreamProvider.family<MatchModel?, String>((ref, matchId) {
  return ref.watch(matchServiceProvider).watchMatch(matchId);
});

final matchCommentaryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, matchId) {
  return ref.watch(matchServiceProvider).watchCommentary(matchId);
});

// ─── Scoring Notifier ─────────────────────────────────────────────────────────

class ScoringState {
  final bool isLoading;
  final String? error;
  final String? selectedWicketType;
  final bool awaitingNewBatsman;
  final bool awaitingNewBowler;

  const ScoringState({
    this.isLoading = false,
    this.error,
    this.selectedWicketType,
    this.awaitingNewBatsman = false,
    this.awaitingNewBowler = false,
  });

  ScoringState copyWith({
    bool? isLoading,
    String? error,
    String? selectedWicketType,
    bool? awaitingNewBatsman,
    bool? awaitingNewBowler,
  }) => ScoringState(
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    selectedWicketType: selectedWicketType ?? this.selectedWicketType,
    awaitingNewBatsman: awaitingNewBatsman ?? this.awaitingNewBatsman,
    awaitingNewBowler: awaitingNewBowler ?? this.awaitingNewBowler,
  );
}

class ScoringNotifier extends StateNotifier<ScoringState> {
  final FirestoreMatchService _service;
  final String matchId;
  final bool isFirstInnings;

  ScoringNotifier({
    required FirestoreMatchService service,
    required this.matchId,
    required this.isFirstInnings,
  })  : _service = service,
        super(const ScoringState());

  Future<void> recordBall({
    required String bowlerId,
    required String bowlerName,
    required String batsmanId,
    required String batsmanName,
    required String ballType,
    required int runs,
    bool isWicket = false,
    String? wicketType,
    String? dismissedPlayerId,
    String? dismissedPlayerName,
    String? fielderId,
    String? fielderName,
    String? nextBatsmanId,
    String? nextBatsmanName,
    bool strikeShouldRotate = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.recordBall(
        matchId: matchId,
        isFirstInnings: isFirstInnings,
        bowlerId: bowlerId,
        bowlerName: bowlerName,
        batsmanId: batsmanId,
        batsmanName: batsmanName,
        ballType: ballType,
        runs: runs,
        isWicket: isWicket,
        wicketType: wicketType,
        dismissedPlayerId: dismissedPlayerId,
        dismissedPlayerName: dismissedPlayerName,
        fielderId: fielderId,
        fielderName: fielderName,
        nextBatsmanId: nextBatsmanId,
        nextBatsmanName: nextBatsmanName,
        strikeShouldRotate: strikeShouldRotate,
      );
      state = state.copyWith(
        isLoading: false,
        awaitingNewBatsman: isWicket && nextBatsmanId == null,
        awaitingNewBowler: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeBowler({
    required String newBowlerId,
    required String newBowlerName,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.changeBowler(
        matchId: matchId,
        isFirstInnings: isFirstInnings,
        newBowlerId: newBowlerId,
        newBowlerName: newBowlerName,
      );
      state = state.copyWith(isLoading: false, awaitingNewBowler: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateToss({
    required String tossWinnerId,
    required String tossDecision,
    required String firstBattingTeamId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateToss(
        matchId: matchId,
        tossWinnerId: tossWinnerId,
        tossDecision: tossDecision,
        firstBattingTeamId: firstBattingTeamId,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generateScorerToken({
    required String tournamentId,
    required String organizerId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.generateScorerToken(
        matchId: matchId,
        tournamentId: tournamentId,
        organizerId: organizerId,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setAwaitingNewBowler() {
    state = state.copyWith(awaitingNewBowler: true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final scoringNotifierProvider = StateNotifierProvider.family<
    ScoringNotifier, ScoringState, Map<String, dynamic>>((ref, args) {
  return ScoringNotifier(
    service: ref.watch(matchServiceProvider),
    matchId: args['matchId'] as String,
    isFirstInnings: args['isFirstInnings'] as bool,
  );
});

// ─── Tournament Notifier ──────────────────────────────────────────────────────

class TournamentNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreTournamentService _service;

  TournamentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<TournamentModel?> createTournament({
    required String name,
    required String format,
    required String type,
    required int overs,
    required int powerplayOvers,
    required String organizerId,
    required String organizerName,
    required DateTime startDate,
    DateTime? endDate,
    String? venueLocation,
    required int maxTeams,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.createTournament(
        name: name, format: format, type: type,
        overs: overs, powerplayOvers: powerplayOvers,
        organizerId: organizerId, organizerName: organizerName,
        startDate: startDate, endDate: endDate,
        venueLocation: venueLocation, maxTeams: maxTeams,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> generateFixtures({
    required String tournamentId,
    required String type,
    required List<String> teamIds,
    required DateTime startDate,
    required int overs,
    required int powerplayOvers,
    required String format,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.generateFixtures(
        tournamentId: tournamentId, type: type,
        teamIds: teamIds, startDate: startDate,
        overs: overs, powerplayOvers: powerplayOvers, format: format,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final tournamentNotifierProvider =
    StateNotifierProvider<TournamentNotifier, AsyncValue<void>>((ref) {
  return TournamentNotifier(ref.watch(tournamentServiceProvider));
});

// ─── Team Notifier ────────────────────────────────────────────────────────────

class TeamNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreTeamService _teamService;
  final FirestorePlayerService _playerService;

  TeamNotifier(this._teamService, this._playerService)
      : super(const AsyncValue.data(null));

  Future<TeamModel?> createTeam({
    required String name,
    required String shortName,
    required String captainId,
    required String captainName,
    String? homeGround,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _teamService.createTeam(
        name: name, shortName: shortName,
        captainId: captainId, captainName: captainName,
        homeGround: homeGround,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<PlayerModel?> addPlayer({
    required String name,
    required String teamId,
    required String role,
    required String battingStyle,
    required String bowlingStyle,
    required int jerseyNumber,
    bool isWicketKeeper = false,
    bool isCaptain = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _playerService.createPlayer(
        name: name, teamId: teamId, role: role,
        battingStyle: battingStyle, bowlingStyle: bowlingStyle,
        jerseyNumber: jerseyNumber, isWicketKeeper: isWicketKeeper,
        isCaptain: isCaptain,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> deletePlayer(String id, String teamId) async {
    state = const AsyncValue.loading();
    try {
      await _playerService.deletePlayer(id, teamId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setViceCaptain(String teamId, String playerId) async {
    await _teamService.setViceCaptain(teamId, playerId);
  }
}

final teamNotifierProvider =
    StateNotifierProvider<TeamNotifier, AsyncValue<void>>((ref) {
  return TeamNotifier(
    ref.watch(teamServiceProvider),
    ref.watch(playerServiceProvider),
  );
});
