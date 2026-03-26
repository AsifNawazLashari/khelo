// lib/data/datasources/firestore_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/models.dart';
import '../../core/constants/firebase_config.dart';
import '../../core/errors/failures.dart';

// ─── Tournament Service ─────────────────────────────────────────────────────

class FirestoreTournamentService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirestoreTournamentService({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  Future<TournamentModel> createTournament({
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
    Map<String, dynamic>? settings,
  }) async {
    try {
      final docRef = _firestore.collection(FirestorePaths.tournaments).doc();
      final tournament = TournamentModel(
        id: docRef.id,
        name: name,
        format: format,
        type: type,
        overs: overs,
        powerplayOvers: powerplayOvers,
        organizerId: organizerId,
        organizerName: organizerName,
        teamIds: [],
        status: 'upcoming',
        startDate: startDate,
        endDate: endDate,
        venueLocation: venueLocation,
        maxTeams: maxTeams,
        settings: settings ?? {},
        createdAt: DateTime.now(),
      );
      await docRef.set(tournament.toFirestore());

      await _firestore
          .collection(FirestorePaths.users)
          .doc(organizerId)
          .update({
        'managedTournaments': FieldValue.arrayUnion([docRef.id]),
      });

      return tournament;
    } catch (e) {
      throw FirestoreFailure(message: 'Failed to create tournament: $e');
    }
  }

  Future<void> updateTournament(
      String id, Map<String, dynamic> data) async {
    await _firestore
        .collection(FirestorePaths.tournaments)
        .doc(id)
        .update(data);
  }

  Future<void> deleteTournament(String id) async {
    await _firestore
        .collection(FirestorePaths.tournaments)
        .doc(id)
        .delete();
  }

  Future<void> addTeamToTournament(
      String tournamentId, String teamId) async {
    await _firestore
        .collection(FirestorePaths.tournaments)
        .doc(tournamentId)
        .update({
      'teamIds': FieldValue.arrayUnion([teamId]),
    });
  }

  Future<void> removeTeamFromTournament(
      String tournamentId, String teamId) async {
    await _firestore
        .collection(FirestorePaths.tournaments)
        .doc(tournamentId)
        .update({
      'teamIds': FieldValue.arrayRemove([teamId]),
    });
  }

  Stream<List<TournamentModel>> watchAllTournaments() {
    return _firestore
        .collection(FirestorePaths.tournaments)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(TournamentModel.fromFirestore).toList());
  }

  Stream<List<TournamentModel>> watchOrganizerTournaments(String uid) {
    return _firestore
        .collection(FirestorePaths.tournaments)
        .where('organizerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(TournamentModel.fromFirestore).toList());
  }

  Future<TournamentModel?> getTournament(String id) async {
    final doc = await _firestore
        .collection(FirestorePaths.tournaments)
        .doc(id)
        .get();
    return doc.exists ? TournamentModel.fromFirestore(doc) : null;
  }

  Stream<TournamentModel?> watchTournament(String id) {
    return _firestore
        .collection(FirestorePaths.tournaments)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? TournamentModel.fromFirestore(doc) : null);
  }

  Future<String?> uploadTournamentLogo(String tournamentId, File file) async {
    final ref = _storage
        .ref()
        .child('tournaments/$tournamentId/logo.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _firestore
        .collection(FirestorePaths.tournaments)
        .doc(tournamentId)
        .update({'logoUrl': url});
    return url;
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
    final batch = _firestore.batch();
    final matchesRef = _firestore.collection(FirestorePaths.matches);

    if (type == 'round_robin') {
      int matchDay = 0;
      for (int i = 0; i < teamIds.length; i++) {
        for (int j = i + 1; j < teamIds.length; j++) {
          final docRef = matchesRef.doc();
          final scheduledDate =
              startDate.add(Duration(days: matchDay));

          // Get team names
          final homeDoc = await _firestore
              .collection(FirestorePaths.teams)
              .doc(teamIds[i])
              .get();
          final awayDoc = await _firestore
              .collection(FirestorePaths.teams)
              .doc(teamIds[j])
              .get();

          final homeData = homeDoc.data() as Map<String, dynamic>? ?? {};
          final awayData = awayDoc.data() as Map<String, dynamic>? ?? {};

          batch.set(docRef, {
            'tournamentId': tournamentId,
            'homeTeamId': teamIds[i],
            'homeTeamName': homeData['name'] ?? '',
            'awayTeamId': teamIds[j],
            'awayTeamName': awayData['name'] ?? '',
            'status': 'scheduled',
            'format': format,
            'overs': overs,
            'powerplayOvers': powerplayOvers,
            'scheduledAt': Timestamp.fromDate(scheduledDate),
            'fixtureRound': 'Round ${matchDay + 1}',
            'createdAt': FieldValue.serverTimestamp(),
          });
          matchDay++;
        }
      }
    } else if (type == 'knockout') {
      // Single elimination knockout
      int round = 1;
      List<String> currentTeams = List.from(teamIds);
      DateTime matchDate = startDate;

      while (currentTeams.length > 1) {
        final nextRound = <String>[];
        for (int i = 0; i < currentTeams.length - 1; i += 2) {
          final docRef = matchesRef.doc();

          final homeDoc = await _firestore
              .collection(FirestorePaths.teams)
              .doc(currentTeams[i])
              .get();
          final awayDoc = await _firestore
              .collection(FirestorePaths.teams)
              .doc(currentTeams[i + 1])
              .get();

          final homeData = homeDoc.data() as Map<String, dynamic>? ?? {};
          final awayData = awayDoc.data() as Map<String, dynamic>? ?? {};

          batch.set(docRef, {
            'tournamentId': tournamentId,
            'homeTeamId': currentTeams[i],
            'homeTeamName': homeData['name'] ?? '',
            'awayTeamId': currentTeams[i + 1],
            'awayTeamName': awayData['name'] ?? '',
            'status': 'scheduled',
            'format': format,
            'overs': overs,
            'powerplayOvers': powerplayOvers,
            'scheduledAt': Timestamp.fromDate(matchDate),
            'fixtureRound': round == 1
                ? 'Round of ${currentTeams.length}'
                : round == (teamIds.length ~/ 2)
                    ? 'Semi-Final'
                    : round == teamIds.length - 1
                        ? 'Final'
                        : 'Quarter-Final',
            'createdAt': FieldValue.serverTimestamp(),
          });
          nextRound.add(currentTeams[i]);
          matchDate = matchDate.add(const Duration(days: 2));
        }
        currentTeams = nextRound;
        round++;
      }
    }

    await batch.commit();
    await _firestore
        .collection(FirestorePaths.tournaments)
        .doc(tournamentId)
        .update({'status': 'active'});
  }
}

// ─── Team Service ────────────────────────────────────────────────────────────

class FirestoreTeamService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirestoreTeamService({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  Future<TeamModel> createTeam({
    required String name,
    required String shortName,
    required String captainId,
    required String captainName,
    String? homeGround,
  }) async {
    try {
      final docRef = _firestore.collection(FirestorePaths.teams).doc();
      final team = TeamModel(
        id: docRef.id,
        name: name,
        shortName: shortName,
        captainId: captainId,
        captainName: captainName,
        playerIds: [],
        stats: {},
        createdAt: DateTime.now(),
        homeGround: homeGround,
      );
      await docRef.set(team.toFirestore());

      await _firestore
          .collection(FirestorePaths.users)
          .doc(captainId)
          .update({
        'managedTeams': FieldValue.arrayUnion([docRef.id]),
      });

      return team;
    } catch (e) {
      throw FirestoreFailure(message: 'Failed to create team: $e');
    }
  }

  Future<void> updateTeam(String id, Map<String, dynamic> data) async {
    await _firestore
        .collection(FirestorePaths.teams)
        .doc(id)
        .update(data);
  }

  Future<void> deleteTeam(String id) async {
    await _firestore.collection(FirestorePaths.teams).doc(id).delete();
  }

  Stream<List<TeamModel>> watchCaptainTeams(String captainId) {
    return _firestore
        .collection(FirestorePaths.teams)
        .where('captainId', isEqualTo: captainId)
        .snapshots()
        .map((q) => q.docs.map(TeamModel.fromFirestore).toList());
  }

  Stream<List<TeamModel>> watchAllTeams() {
    return _firestore
        .collection(FirestorePaths.teams)
        .orderBy('name')
        .snapshots()
        .map((q) => q.docs.map(TeamModel.fromFirestore).toList());
  }

  Future<TeamModel?> getTeam(String id) async {
    final doc =
        await _firestore.collection(FirestorePaths.teams).doc(id).get();
    return doc.exists ? TeamModel.fromFirestore(doc) : null;
  }

  Future<List<TeamModel>> getTeamsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final docs = await Future.wait(
      ids.map((id) =>
          _firestore.collection(FirestorePaths.teams).doc(id).get()),
    );
    return docs
        .where((d) => d.exists)
        .map(TeamModel.fromFirestore)
        .toList();
  }

  Future<String?> uploadTeamLogo(String teamId, File file) async {
    final ref = _storage.ref().child('teams/$teamId/logo.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _firestore
        .collection(FirestorePaths.teams)
        .doc(teamId)
        .update({'logoUrl': url});
    return url;
  }

  Future<void> setViceCaptain(String teamId, String playerId) async {
    await _firestore
        .collection(FirestorePaths.teams)
        .doc(teamId)
        .update({'viceCaptainId': playerId});
    await _firestore
        .collection(FirestorePaths.players)
        .doc(playerId)
        .update({'isViceCaptain': true});
  }
}

// ─── Player Service ──────────────────────────────────────────────────────────

class FirestorePlayerService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirestorePlayerService({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  Future<PlayerModel> createPlayer({
    required String name,
    required String teamId,
    required String role,
    required String battingStyle,
    required String bowlingStyle,
    required int jerseyNumber,
    bool isWicketKeeper = false,
    bool isCaptain = false,
  }) async {
    try {
      final docRef = _firestore.collection(FirestorePaths.players).doc();
      final player = PlayerModel(
        id: docRef.id,
        name: name,
        teamId: teamId,
        role: role,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        jerseyNumber: jerseyNumber,
        isWicketKeeper: isWicketKeeper,
        isCaptain: isCaptain,
        isViceCaptain: false,
        battingStats: {},
        bowlingStats: {},
        createdAt: DateTime.now(),
      );
      await docRef.set(player.toFirestore());

      await _firestore.collection(FirestorePaths.teams).doc(teamId).update({
        'playerIds': FieldValue.arrayUnion([docRef.id]),
      });

      return player;
    } catch (e) {
      throw FirestoreFailure(message: 'Failed to create player: $e');
    }
  }

  Future<void> updatePlayer(String id, Map<String, dynamic> data) async {
    await _firestore
        .collection(FirestorePaths.players)
        .doc(id)
        .update(data);
  }

  Future<void> deletePlayer(String id, String teamId) async {
    await _firestore.collection(FirestorePaths.players).doc(id).delete();
    await _firestore
        .collection(FirestorePaths.teams)
        .doc(teamId)
        .update({
      'playerIds': FieldValue.arrayRemove([id]),
    });
  }

  Stream<List<PlayerModel>> watchTeamPlayers(String teamId) {
    return _firestore
        .collection(FirestorePaths.players)
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((q) => q.docs.map(PlayerModel.fromFirestore).toList());
  }

  Future<List<PlayerModel>> getPlayersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final docs = await Future.wait(
      ids.map((id) =>
          _firestore.collection(FirestorePaths.players).doc(id).get()),
    );
    return docs
        .where((d) => d.exists)
        .map(PlayerModel.fromFirestore)
        .toList();
  }

  Future<void> updatePlayerBattingStats({
    required String playerId,
    required int runs,
    required int balls,
    required int fours,
    required int sixes,
    required bool isOut,
  }) async {
    final doc = await _firestore
        .collection(FirestorePaths.players)
        .doc(playerId)
        .get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final stats =
        Map<String, dynamic>.from(data['battingStats'] as Map? ?? {});

    stats['matchesPlayed'] = ((stats['matchesPlayed'] as int?) ?? 0) + 1;
    stats['innings'] = ((stats['innings'] as int?) ?? 0) + 1;
    stats['totalRuns'] = ((stats['totalRuns'] as int?) ?? 0) + runs;
    stats['ballsFaced'] = ((stats['ballsFaced'] as int?) ?? 0) + balls;
    stats['fours'] = ((stats['fours'] as int?) ?? 0) + fours;
    stats['sixes'] = ((stats['sixes'] as int?) ?? 0) + sixes;
    if (!isOut) stats['notOuts'] = ((stats['notOuts'] as int?) ?? 0) + 1;
    if (runs > ((stats['highScore'] as int?) ?? 0)) {
      stats['highScore'] = runs;
    }
    if (runs >= 100) stats['hundreds'] = ((stats['hundreds'] as int?) ?? 0) + 1;
    else if (runs >= 50) stats['fifties'] = ((stats['fifties'] as int?) ?? 0) + 1;
    if (runs == 0 && isOut) stats['ducks'] = ((stats['ducks'] as int?) ?? 0) + 1;

    await _firestore
        .collection(FirestorePaths.players)
        .doc(playerId)
        .update({'battingStats': stats});
  }

  Future<void> updatePlayerBowlingStats({
    required String playerId,
    required int overs,
    required int runs,
    required int wickets,
    required int wides,
    required int noBalls,
    required int maidens,
  }) async {
    final doc = await _firestore
        .collection(FirestorePaths.players)
        .doc(playerId)
        .get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final stats =
        Map<String, dynamic>.from(data['bowlingStats'] as Map? ?? {});

    stats['oversBowled'] = ((stats['oversBowled'] as int?) ?? 0) + overs;
    stats['runsConceded'] = ((stats['runsConceded'] as int?) ?? 0) + runs;
    stats['wickets'] = ((stats['wickets'] as int?) ?? 0) + wickets;
    stats['maidens'] = ((stats['maidens'] as int?) ?? 0) + maidens;
    stats['wides'] = ((stats['wides'] as int?) ?? 0) + wides;
    stats['noBalls'] = ((stats['noBalls'] as int?) ?? 0) + noBalls;
    if (wickets >= 5) {
      stats['fiveWickets'] = ((stats['fiveWickets'] as int?) ?? 0) + 1;
    }
    if (wickets > ((stats['bestBowling'] as int?) ?? 0)) {
      stats['bestBowling'] = wickets;
      stats['bestBowlingRuns'] = runs;
    }

    await _firestore
        .collection(FirestorePaths.players)
        .doc(playerId)
        .update({'bowlingStats': stats});
  }
}
