// lib/data/datasources/firestore_match_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../../domain/entities/entities.dart';
import '../../core/constants/firebase_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

class FirestoreMatchService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FirestoreMatchService({
    required FirebaseFirestore firestore,
  })  : _firestore = firestore,
        _uuid = const Uuid();

  // ─── Match CRUD ─────────────────────────────────────────────

  Future<MatchModel> createMatch({
    required String tournamentId,
    required String homeTeamId,
    required String homeTeamName,
    required String awayTeamId,
    required String awayTeamName,
    required String format,
    required int overs,
    required int powerplayOvers,
    required DateTime scheduledAt,
    String? venue,
    String? fixtureRound,
  }) async {
    try {
      final docRef = _firestore.collection(FirestorePaths.matches).doc();
      final match = MatchModel(
        id: docRef.id,
        tournamentId: tournamentId,
        homeTeamId: homeTeamId,
        homeTeamName: homeTeamName,
        awayTeamId: awayTeamId,
        awayTeamName: awayTeamName,
        status: AppConstants.matchStatusScheduled,
        format: format,
        overs: overs,
        powerplayOvers: powerplayOvers,
        venue: venue,
        scheduledAt: scheduledAt,
        fixtureRound: fixtureRound,
        createdAt: DateTime.now(),
      );
      await docRef.set(match.toFirestore());
      return match;
    } catch (e) {
      throw FirestoreFailure(message: 'Failed to create match: $e');
    }
  }

  Future<void> updateToss({
    required String matchId,
    required String tossWinnerId,
    required String tossDecision,
    required String firstBattingTeamId,
  }) async {
    await _firestore.collection(FirestorePaths.matches).doc(matchId).update({
      'tossWinnerId': tossWinnerId,
      'tossDecision': tossDecision,
      'currentBattingTeamId': firstBattingTeamId,
      'status': AppConstants.matchStatusLive,
    });
  }

  Stream<MatchModel?> watchMatch(String matchId) {
    return _firestore
        .collection(FirestorePaths.matches)
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromFirestore(doc) : null);
  }

  Future<List<MatchModel>> getMatchesByTournament(String tournamentId) async {
    final query = await _firestore
        .collection(FirestorePaths.matches)
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('scheduledAt')
        .get();
    return query.docs.map(MatchModel.fromFirestore).toList();
  }

  Future<List<MatchModel>> getLiveMatches() async {
    final query = await _firestore
        .collection(FirestorePaths.matches)
        .where('status', isEqualTo: AppConstants.matchStatusLive)
        .orderBy('scheduledAt', descending: true)
        .get();
    return query.docs.map(MatchModel.fromFirestore).toList();
  }

  Stream<List<MatchModel>> watchLiveMatches() {
    return _firestore
        .collection(FirestorePaths.matches)
        .where('status', isEqualTo: AppConstants.matchStatusLive)
        .snapshots()
        .map((q) => q.docs.map(MatchModel.fromFirestore).toList());
  }

  // ─── Innings Management ──────────────────────────────────────

  Future<void> startInnings({
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required bool isFirstInnings,
    required List<String> battingOrder,
    required String openingBowlerId,
    required String openingBowlerName,
  }) async {
    final inningsKey = isFirstInnings ? 'firstInnings' : 'secondInnings';
    final inningsData = {
      'id': _uuid.v4(),
      'battingTeamId': battingTeamId,
      'bowlingTeamId': bowlingTeamId,
      'totalRuns': 0,
      'totalWickets': 0,
      'totalBalls': 0,
      'extras': 0,
      'wides': 0,
      'noBalls': 0,
      'byes': 0,
      'legByes': 0,
      'status': AppConstants.inningsStatusInProgress,
      'batterScores': [],
      'bowlerScores': [
        {
          'playerId': openingBowlerId,
          'playerName': openingBowlerName,
          'overs': 0,
          'balls': 0,
          'runs': 0,
          'wickets': 0,
          'maidens': 0,
          'wides': 0,
          'noBalls': 0,
        }
      ],
      'fallOfWickets': [],
      'currentBatter1Id': battingOrder.isNotEmpty ? battingOrder[0] : null,
      'currentBatter2Id': battingOrder.length > 1 ? battingOrder[1] : null,
      'currentBowlerId': openingBowlerId,
      'onStrikeBatterId': battingOrder.isNotEmpty ? battingOrder[0] : null,
      'currentOverBalls': 0,
      'currentOverRuns': [],
    };

    await _firestore.collection(FirestorePaths.matches).doc(matchId).update({
      inningsKey: inningsData,
      'currentBattingTeamId': battingTeamId,
    });
  }

  // ─── Core Scoring Engine ─────────────────────────────────────

  Future<void> recordBall({
    required String matchId,
    required bool isFirstInnings,
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
    final matchRef = _firestore.collection(FirestorePaths.matches).doc(matchId);
    final inningsKey = isFirstInnings ? 'firstInnings' : 'secondInnings';

    await _firestore.runTransaction((transaction) async {
      final matchDoc = await transaction.get(matchRef);
      if (!matchDoc.exists) throw Exception('Match not found');

      final matchData = matchDoc.data() as Map<String, dynamic>;
      final inningsData = Map<String, dynamic>.from(
          matchData[inningsKey] as Map<String, dynamic>);

      // ─── Ball validity ──────────────────────────────────────
      final isLegal = ballType != AppConstants.ballTypeWide &&
          ballType != AppConstants.ballTypeNoBall;

      // ─── Update runs ────────────────────────────────────────
      int totalRuns = inningsData['totalRuns'] as int;
      int totalBalls = inningsData['totalBalls'] as int;
      int totalWickets = inningsData['totalWickets'] as int;
      int extras = inningsData['extras'] as int;
      int wides = inningsData['wides'] as int;
      int noBalls = inningsData['noBalls'] as int;
      int byes = inningsData['byes'] as int;
      int legByes = inningsData['legByes'] as int;
      int currentOverBalls = inningsData['currentOverBalls'] as int;
      List<int> currentOverRuns =
          List<int>.from(inningsData['currentOverRuns'] as List);
      String? onStrikeBatterId = inningsData['onStrikeBatterId'] as String?;
      String? currentBatter1Id = inningsData['currentBatter1Id'] as String?;
      String? currentBatter2Id = inningsData['currentBatter2Id'] as String?;

      totalRuns += runs;

      if (ballType == AppConstants.ballTypeWide) {
        extras += 1;
        wides += 1;
        extras += (runs - 1).clamp(0, 100); // wide + overthrows
      } else if (ballType == AppConstants.ballTypeNoBall) {
        extras += 1;
        noBalls += 1;
        extras += (runs - 1).clamp(0, 100);
      } else if (ballType == AppConstants.ballTypeBye) {
        extras += runs;
        byes += runs;
      } else if (ballType == AppConstants.ballTypeLegBye) {
        extras += runs;
        legByes += runs;
      }

      if (isLegal) {
        totalBalls += 1;
        currentOverBalls += 1;
        currentOverRuns.add(runs);
      }

      // ─── Update Batter Scores ────────────────────────────────
      List<Map<String, dynamic>> batterScores =
          (inningsData['batterScores'] as List? ?? [])
              .map((b) => Map<String, dynamic>.from(b as Map))
              .toList();

      final batsmanIndex =
          batterScores.indexWhere((b) => b['playerId'] == batsmanId);

      if (batsmanIndex == -1) {
        batterScores.add({
          'playerId': batsmanId,
          'playerName': batsmanName,
          'runs': 0,
          'balls': 0,
          'fours': 0,
          'sixes': 0,
          'status': 'batting',
          'isOnStrike': true,
        });
      }

      final bi = batterScores.indexWhere((b) => b['playerId'] == batsmanId);
      if (ballType == AppConstants.ballTypeNormal ||
          ballType == AppConstants.ballTypeNoBall) {
        if (isLegal) batterScores[bi]['balls'] = (batterScores[bi]['balls'] as int) + 1;
        if (runs == 4) {
          batterScores[bi]['runs'] = (batterScores[bi]['runs'] as int) + runs;
          batterScores[bi]['fours'] = (batterScores[bi]['fours'] as int) + 1;
        } else if (runs == 6) {
          batterScores[bi]['runs'] = (batterScores[bi]['runs'] as int) + runs;
          batterScores[bi]['sixes'] = (batterScores[bi]['sixes'] as int) + 1;
        } else {
          batterScores[bi]['runs'] = (batterScores[bi]['runs'] as int) + runs;
        }
      } else if (isLegal) {
        batterScores[bi]['balls'] = (batterScores[bi]['balls'] as int) + 1;
      }

      // ─── Wicket Handling ─────────────────────────────────────
      List<Map<String, dynamic>> fallOfWickets =
          (inningsData['fallOfWickets'] as List? ?? [])
              .map((f) => Map<String, dynamic>.from(f as Map))
              .toList();

      if (isWicket && dismissedPlayerId != null) {
        totalWickets += 1;
        final di = batterScores.indexWhere(
            (b) => b['playerId'] == dismissedPlayerId);
        if (di != -1) {
          batterScores[di]['status'] = 'out';
          batterScores[di]['dismissalType'] = wicketType;
          batterScores[di]['dismissedBy'] = bowlerName;
          batterScores[di]['caughtBy'] = fielderName;
          batterScores[di]['isOnStrike'] = false;

          fallOfWickets.add({
            'wicketNumber': totalWickets,
            'runs': totalRuns,
            'overs': totalBalls ~/ 6,
            'balls': totalBalls % 6,
            'batsmanId': dismissedPlayerId,
            'batsmanName': dismissedPlayerName ?? '',
            'batsmanScore': batterScores[di]['runs'],
          });
        }

        // Bring next batsman in
        if (nextBatsmanId != null && nextBatsmanName != null) {
          batterScores.add({
            'playerId': nextBatsmanId,
            'playerName': nextBatsmanName,
            'runs': 0,
            'balls': 0,
            'fours': 0,
            'sixes': 0,
            'status': 'batting',
            'isOnStrike': dismissedPlayerId == onStrikeBatterId,
          });

          if (dismissedPlayerId == onStrikeBatterId) {
            onStrikeBatterId = nextBatsmanId;
            currentBatter1Id = nextBatsmanId;
          } else {
            currentBatter2Id = nextBatsmanId;
          }
        }
      }

      // ─── Strike Rotation ─────────────────────────────────────
      bool shouldRotate = strikeShouldRotate;

      // Odd runs rotate strike
      if (!isWicket && runs % 2 != 0 && ballType == AppConstants.ballTypeNormal) {
        shouldRotate = !shouldRotate;
      }

      // Rotate at end of over
      bool overCompleted = false;
      if (isLegal && currentOverBalls >= 6) {
        overCompleted = true;
        shouldRotate = !shouldRotate;
        currentOverBalls = 0;
        currentOverRuns = [];
      }

      if (shouldRotate) {
        final temp = currentBatter1Id;
        currentBatter1Id = currentBatter2Id;
        currentBatter2Id = temp;
        onStrikeBatterId =
            onStrikeBatterId == currentBatter1Id ? currentBatter2Id : currentBatter1Id;

        // Update isOnStrike flags
        for (int i = 0; i < batterScores.length; i++) {
          batterScores[i]['isOnStrike'] =
              batterScores[i]['playerId'] == onStrikeBatterId;
        }
      }

      // ─── Update Bowler Scores ─────────────────────────────────
      List<Map<String, dynamic>> bowlerScores =
          (inningsData['bowlerScores'] as List? ?? [])
              .map((b) => Map<String, dynamic>.from(b as Map))
              .toList();

      final bowlerIndex =
          bowlerScores.indexWhere((b) => b['playerId'] == bowlerId);
      if (bowlerIndex == -1) {
        bowlerScores.add({
          'playerId': bowlerId,
          'playerName': bowlerName,
          'overs': 0,
          'balls': 0,
          'runs': runs,
          'wickets': isWicket ? 1 : 0,
          'maidens': 0,
          'wides': ballType == AppConstants.ballTypeWide ? 1 : 0,
          'noBalls': ballType == AppConstants.ballTypeNoBall ? 1 : 0,
        });
      } else {
        final bwr = bowlerScores[bowlerIndex];
        bwr['runs'] = (bwr['runs'] as int) + runs;
        if (isLegal) {
          bwr['balls'] = (bwr['balls'] as int) + 1;
          if ((bwr['balls'] as int) >= 6) {
            bwr['overs'] = (bwr['overs'] as int) + 1;
            bwr['balls'] = 0;
            // Check maiden
            if (currentOverRuns.every((r) => r == 0)) {
              bwr['maidens'] = (bwr['maidens'] as int) + 1;
            }
          }
        }
        if (isWicket && wicketType != AppConstants.wicketRunOut) {
          bwr['wickets'] = (bwr['wickets'] as int) + 1;
        }
        if (ballType == AppConstants.ballTypeWide) {
          bwr['wides'] = (bwr['wides'] as int) + 1;
        }
        if (ballType == AppConstants.ballTypeNoBall) {
          bwr['noBalls'] = (bwr['noBalls'] as int) + 1;
        }
        bowlerScores[bowlerIndex] = bwr;
      }

      // ─── Check innings completion ─────────────────────────────
      final maxOvers = matchData['overs'] as int;
      String inningsStatus = inningsData['status'] as String;
      if (totalWickets >= 10 || totalBalls >= maxOvers * 6) {
        inningsStatus = AppConstants.inningsStatusCompleted;
      }

      // ─── Build updated innings ────────────────────────────────
      final updatedInnings = {
        ...inningsData,
        'totalRuns': totalRuns,
        'totalWickets': totalWickets,
        'totalBalls': totalBalls,
        'extras': extras,
        'wides': wides,
        'noBalls': noBalls,
        'byes': byes,
        'legByes': legByes,
        'batterScores': batterScores,
        'bowlerScores': bowlerScores,
        'fallOfWickets': fallOfWickets,
        'currentBatter1Id': currentBatter1Id,
        'currentBatter2Id': currentBatter2Id,
        'onStrikeBatterId': onStrikeBatterId,
        'currentOverBalls': currentOverBalls,
        'currentOverRuns': currentOverRuns,
        'status': inningsStatus,
      };

      // Check if second innings is won (target chased)
      String matchStatus = matchData['status'] as String;
      String? matchWinnerId;
      String? winDescription;

      if (!isFirstInnings) {
        final firstInnings = matchData['firstInnings'] as Map<String, dynamic>?;
        if (firstInnings != null) {
          final target = (firstInnings['totalRuns'] as int) + 1;
          if (totalRuns >= target) {
            matchStatus = AppConstants.matchStatusCompleted;
            matchWinnerId = inningsData['battingTeamId'] as String;
            final wicketsLeft = 10 - totalWickets;
            winDescription =
                '${_getTeamShortName(matchData, matchWinnerId)} won by $wicketsLeft wickets';
          }
        }
      }

      if (inningsStatus == AppConstants.inningsStatusCompleted && isFirstInnings) {
        matchStatus = AppConstants.matchStatusLive;
      }

      if (inningsStatus == AppConstants.inningsStatusCompleted && !isFirstInnings) {
        if (matchStatus != AppConstants.matchStatusCompleted) {
          // Second innings completed without chasing
          final firstInnings = matchData['firstInnings'] as Map<String, dynamic>?;
          if (firstInnings != null) {
            final firstRuns = firstInnings['totalRuns'] as int;
            if (totalRuns > firstRuns) {
              matchWinnerId = inningsData['battingTeamId'] as String;
              final diff = totalRuns - firstRuns;
              winDescription =
                  '${_getTeamShortName(matchData, matchWinnerId)} won by $diff runs';
            } else if (totalRuns < firstRuns) {
              matchWinnerId = inningsData['bowlingTeamId'] as String;
              final diff = firstRuns - totalRuns;
              winDescription =
                  '${_getTeamShortName(matchData, matchWinnerId)} won by $diff runs';
            } else {
              winDescription = 'Match tied';
            }
            matchStatus = AppConstants.matchStatusCompleted;
          }
        }
      }

      Map<String, dynamic> updateData = {
        inningsKey: updatedInnings,
        'status': matchStatus,
      };

      if (matchWinnerId != null) {
        updateData['matchWinnerId'] = matchWinnerId;
        updateData['winDescription'] = winDescription;
      }

      transaction.update(matchRef, updateData);

      // Store ball in subcollection
      final inningsId = inningsData['id'] as String;
      final ballRef = _firestore
          .collection(FirestorePaths.inningsBalls(matchId, inningsId))
          .doc();
      transaction.set(ballRef, {
        'inningsId': inningsId,
        'overNumber': totalBalls ~/ 6,
        'ballNumber': totalBalls % 6,
        'bowlerId': bowlerId,
        'batsmanId': batsmanId,
        'type': ballType,
        'runs': runs,
        'isWicket': isWicket,
        'wicketType': wicketType,
        'dismissedPlayerId': dismissedPlayerId,
        'fielderId': fielderId,
        'isBoundary': runs == 4,
        'isSix': runs == 6,
        'commentaryText': _generateCommentary(
          ballType: ballType, runs: runs, isWicket: isWicket,
          wicketType: wicketType, batsmanName: batsmanName,
          bowlerName: bowlerName, fielderName: fielderName,
        ),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Store commentary
      final commentRef = _firestore
          .collection(FirestorePaths.matchCommentary(matchId))
          .doc();
      transaction.set(commentRef, {
        'matchId': matchId,
        'inningsId': inningsId,
        'overNumber': totalBalls ~/ 6,
        'ballNumber': totalBalls % 6,
        'text': _generateCommentary(
          ballType: ballType, runs: runs, isWicket: isWicket,
          wicketType: wicketType, batsmanName: batsmanName,
          bowlerName: bowlerName, fielderName: fielderName,
        ),
        'type': isWicket ? 'wicket' : (runs >= 4 ? 'boundary' : 'normal'),
        'timestamp': FieldValue.serverTimestamp(),
        'authorId': bowlerId,
      });
    });
  }

  String _getTeamShortName(Map<String, dynamic> data, String teamId) {
    if (data['homeTeamId'] == teamId) return data['homeTeamName'] ?? '';
    return data['awayTeamName'] ?? '';
  }

  String _generateCommentary({
    required String ballType,
    required int runs,
    required bool isWicket,
    String? wicketType,
    required String batsmanName,
    required String bowlerName,
    String? fielderName,
  }) {
    if (isWicket) {
      switch (wicketType) {
        case AppConstants.wicketBowled:
          return '$bowlerName to $batsmanName, OUT! BOWLED! The stumps are rattled!';
        case AppConstants.wicketCaught:
          return '$bowlerName to $batsmanName, OUT! CAUGHT${fielderName != null ? ' by $fielderName' : ''}! Beautiful catch!';
        case AppConstants.wicketLBW:
          return '$bowlerName to $batsmanName, OUT! LBW! That would have hit the stumps!';
        case AppConstants.wicketRunOut:
          return '$batsmanName, RUN OUT! Direct hit from ${fielderName ?? 'the fielder'}! Gone!';
        case AppConstants.wicketStumped:
          return '$bowlerName to $batsmanName, OUT! STUMPED! $batsmanName is out of his crease!';
        default:
          return '$bowlerName to $batsmanName, OUT! $batsmanName has to walk back!';
      }
    }

    if (ballType == AppConstants.ballTypeWide) {
      return '$bowlerName bowls a wide! +1 extra.';
    }
    if (ballType == AppConstants.ballTypeNoBall) {
      return '$bowlerName oversteps! No ball! +1 extra.';
    }

    switch (runs) {
      case 0:
        return '$bowlerName to $batsmanName, dot ball! Good delivery!';
      case 1:
        return '$bowlerName to $batsmanName, 1 run, worked to the leg side.';
      case 2:
        return '$bowlerName to $batsmanName, 2 runs! Good running between the wickets.';
      case 3:
        return '$bowlerName to $batsmanName, 3 runs! Excellent placement.';
      case 4:
        return '$bowlerName to $batsmanName, FOUR! $batsmanName finds the boundary!';
      case 6:
        return '$bowlerName to $batsmanName, SIX! $batsmanName sends it into the stands!';
      default:
        return '$bowlerName to $batsmanName, $runs runs.';
    }
  }

  // ─── Scorer Token System ─────────────────────────────────────

  Future<String> generateScorerToken({
    required String matchId,
    required String tournamentId,
    required String organizerId,
  }) async {
    final docRef = _firestore.collection(FirestorePaths.scorerTokens).doc();
    final token = {
      'id': docRef.id,
      'matchId': matchId,
      'tournamentId': tournamentId,
      'organizerId': organizerId,
      'assignedScorerId': null,
      'isUsed': false,
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24))),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(token);
    return docRef.id;
  }

  Future<void> claimScorerToken({
    required String tokenId,
    required String scorerId,
  }) async {
    final tokenRef =
        _firestore.collection(FirestorePaths.scorerTokens).doc(tokenId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(tokenRef);
      if (!doc.exists) {
        throw const ScorerTokenFailure(message: 'Token not found');
      }
      final data = doc.data() as Map<String, dynamic>;
      if (data['isUsed'] as bool) {
        throw const ScorerTokenFailure(message: 'Token already used');
      }
      final expiry = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiry)) {
        throw const ScorerTokenFailure(message: 'Token has expired');
      }
      transaction.update(tokenRef, {
        'isUsed': true,
        'assignedScorerId': scorerId,
      });
      final matchId = data['matchId'] as String;
      transaction.update(
          _firestore.collection(FirestorePaths.matches).doc(matchId),
          {'scorerId': scorerId, 'scorerTokenId': tokenId});
    });
  }

  // ─── Change Bowler ───────────────────────────────────────────

  Future<void> changeBowler({
    required String matchId,
    required bool isFirstInnings,
    required String newBowlerId,
    required String newBowlerName,
  }) async {
    final inningsKey = isFirstInnings ? 'firstInnings' : 'secondInnings';
    final matchRef = _firestore.collection(FirestorePaths.matches).doc(matchId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(matchRef);
      final matchData = doc.data() as Map<String, dynamic>;
      final innings = Map<String, dynamic>.from(
          matchData[inningsKey] as Map<String, dynamic>);

      List<Map<String, dynamic>> bowlerScores =
          (innings['bowlerScores'] as List? ?? [])
              .map((b) => Map<String, dynamic>.from(b as Map))
              .toList();

      final exists =
          bowlerScores.any((b) => b['playerId'] == newBowlerId);
      if (!exists) {
        bowlerScores.add({
          'playerId': newBowlerId,
          'playerName': newBowlerName,
          'overs': 0,
          'balls': 0,
          'runs': 0,
          'wickets': 0,
          'maidens': 0,
          'wides': 0,
          'noBalls': 0,
        });
      }

      innings['currentBowlerId'] = newBowlerId;
      innings['bowlerScores'] = bowlerScores;

      transaction.update(matchRef, {inningsKey: innings});
    });
  }

  // ─── Commentary Stream ───────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchCommentary(String matchId) {
    return _firestore
        .collection(FirestorePaths.matchCommentary(matchId))
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((q) => q.docs.map((d) => d.data()).toList());
  }
}
