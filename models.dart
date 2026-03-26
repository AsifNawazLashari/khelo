// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> managedTournaments;
  final List<String> managedTeams;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.managedTournaments,
    required this.managedTeams,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'player',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      managedTournaments: List<String>.from(data['managedTournaments'] ?? []),
      managedTeams: List<String>.from(data['managedTeams'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'role': role,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    'managedTournaments': managedTournaments,
    'managedTeams': managedTeams,
  };

  UserEntity toEntity() => UserEntity(
    uid: uid,
    email: email,
    displayName: displayName,
    role: role,
    photoUrl: photoUrl,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt,
    managedTournaments: managedTournaments,
    managedTeams: managedTeams,
  );
}

// lib/data/models/tournament_model.dart
class TournamentModel {
  final String id;
  final String name;
  final String format;
  final String type;
  final int overs;
  final int powerplayOvers;
  final String organizerId;
  final String organizerName;
  final List<String> teamIds;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final String? logoUrl;
  final String? venueLocation;
  final int maxTeams;
  final Map<String, dynamic> settings;
  final DateTime createdAt;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.format,
    required this.type,
    required this.overs,
    required this.powerplayOvers,
    required this.organizerId,
    required this.organizerName,
    required this.teamIds,
    required this.status,
    required this.startDate,
    this.endDate,
    this.logoUrl,
    this.venueLocation,
    required this.maxTeams,
    required this.settings,
    required this.createdAt,
  });

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TournamentModel(
      id: doc.id,
      name: data['name'] ?? '',
      format: data['format'] ?? 'ODI',
      type: data['type'] ?? 'round_robin',
      overs: data['overs'] ?? 50,
      powerplayOvers: data['powerplayOvers'] ?? 10,
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      teamIds: List<String>.from(data['teamIds'] ?? []),
      status: data['status'] ?? 'upcoming',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      logoUrl: data['logoUrl'],
      venueLocation: data['venueLocation'],
      maxTeams: data['maxTeams'] ?? 8,
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'format': format,
    'type': type,
    'overs': overs,
    'powerplayOvers': powerplayOvers,
    'organizerId': organizerId,
    'organizerName': organizerName,
    'teamIds': teamIds,
    'status': status,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'logoUrl': logoUrl,
    'venueLocation': venueLocation,
    'maxTeams': maxTeams,
    'settings': settings,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  TournamentEntity toEntity() => TournamentEntity(
    id: id, name: name, format: format, type: type,
    overs: overs, powerplayOvers: powerplayOvers,
    organizerId: organizerId, organizerName: organizerName,
    teamIds: teamIds, status: status, startDate: startDate,
    endDate: endDate, logoUrl: logoUrl, venueLocation: venueLocation,
    maxTeams: maxTeams, settings: settings, createdAt: createdAt,
  );
}

// lib/data/models/team_model.dart
class TeamModel {
  final String id;
  final String name;
  final String shortName;
  final String captainId;
  final String captainName;
  final String? viceCaptainId;
  final String? logoUrl;
  final List<String> playerIds;
  final String? homeGround;
  final Map<String, dynamic> stats;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.captainId,
    required this.captainName,
    this.viceCaptainId,
    this.logoUrl,
    required this.playerIds,
    this.homeGround,
    required this.stats,
    required this.createdAt,
  });

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      shortName: data['shortName'] ?? '',
      captainId: data['captainId'] ?? '',
      captainName: data['captainName'] ?? '',
      viceCaptainId: data['viceCaptainId'],
      logoUrl: data['logoUrl'],
      playerIds: List<String>.from(data['playerIds'] ?? []),
      homeGround: data['homeGround'],
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'shortName': shortName,
    'captainId': captainId,
    'captainName': captainName,
    'viceCaptainId': viceCaptainId,
    'logoUrl': logoUrl,
    'playerIds': playerIds,
    'homeGround': homeGround,
    'stats': stats,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  TeamEntity toEntity() => TeamEntity(
    id: id, name: name, shortName: shortName,
    captainId: captainId, captainName: captainName,
    viceCaptainId: viceCaptainId, logoUrl: logoUrl,
    playerIds: playerIds, homeGround: homeGround,
    stats: stats, createdAt: createdAt,
  );
}

// lib/data/models/player_model.dart
class PlayerModel {
  final String id;
  final String name;
  final String teamId;
  final String role;
  final String battingStyle;
  final String bowlingStyle;
  final int jerseyNumber;
  final String? photoUrl;
  final bool isCaptain;
  final bool isViceCaptain;
  final bool isWicketKeeper;
  final Map<String, dynamic> battingStats;
  final Map<String, dynamic> bowlingStats;
  final DateTime createdAt;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.teamId,
    required this.role,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.jerseyNumber,
    this.photoUrl,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.isWicketKeeper,
    required this.battingStats,
    required this.bowlingStats,
    required this.createdAt,
  });

  factory PlayerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerModel(
      id: doc.id,
      name: data['name'] ?? '',
      teamId: data['teamId'] ?? '',
      role: data['role'] ?? 'batsman',
      battingStyle: data['battingStyle'] ?? 'right_hand',
      bowlingStyle: data['bowlingStyle'] ?? 'right_arm_medium',
      jerseyNumber: data['jerseyNumber'] ?? 0,
      photoUrl: data['photoUrl'],
      isCaptain: data['isCaptain'] ?? false,
      isViceCaptain: data['isViceCaptain'] ?? false,
      isWicketKeeper: data['isWicketKeeper'] ?? false,
      battingStats: Map<String, dynamic>.from(data['battingStats'] ?? {}),
      bowlingStats: Map<String, dynamic>.from(data['bowlingStats'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'teamId': teamId,
    'role': role,
    'battingStyle': battingStyle,
    'bowlingStyle': bowlingStyle,
    'jerseyNumber': jerseyNumber,
    'photoUrl': photoUrl,
    'isCaptain': isCaptain,
    'isViceCaptain': isViceCaptain,
    'isWicketKeeper': isWicketKeeper,
    'battingStats': battingStats,
    'bowlingStats': bowlingStats,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  PlayerEntity toEntity() => PlayerEntity(
    id: id, name: name, teamId: teamId, role: role,
    battingStyle: battingStyle, bowlingStyle: bowlingStyle,
    jerseyNumber: jerseyNumber, photoUrl: photoUrl,
    isCaptain: isCaptain, isViceCaptain: isViceCaptain,
    isWicketKeeper: isWicketKeeper,
    battingStats: _parseStats(battingStats, true),
    bowlingStats: _parseStats(bowlingStats, false),
    createdAt: createdAt,
  );

  PlayerStatsEntity _parseStats(Map<String, dynamic> data, bool batting) {
    if (batting) {
      return PlayerStatsEntity(
        matchesPlayed: data['matchesPlayed'] ?? 0,
        innings: data['innings'] ?? 0,
        totalRuns: data['totalRuns'] ?? 0,
        ballsFaced: data['ballsFaced'] ?? 0,
        fours: data['fours'] ?? 0,
        sixes: data['sixes'] ?? 0,
        highScore: data['highScore'] ?? 0,
        notOuts: data['notOuts'] ?? 0,
        fifties: data['fifties'] ?? 0,
        hundreds: data['hundreds'] ?? 0,
        ducks: data['ducks'] ?? 0,
      );
    } else {
      return PlayerStatsEntity(
        oversBowled: data['oversBowled'] ?? 0,
        runsConceded: data['runsConceded'] ?? 0,
        wickets: data['wickets'] ?? 0,
        maidens: data['maidens'] ?? 0,
        wides: data['wides'] ?? 0,
        noBalls: data['noBalls'] ?? 0,
        fiveWickets: data['fiveWickets'] ?? 0,
        bestBowling: data['bestBowling'] ?? 0,
        bestBowlingRuns: data['bestBowlingRuns'] ?? 0,
      );
    }
  }
}

// lib/data/models/match_model.dart
class MatchModel {
  final String id;
  final String tournamentId;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final String status;
  final String format;
  final int overs;
  final int powerplayOvers;
  final String? venue;
  final DateTime scheduledAt;
  final String? tossWinnerId;
  final String? tossDecision;
  final String? matchWinnerId;
  final String? winDescription;
  final String? scorerId;
  final String? scorerTokenId;
  final String? fixtureRound;
  final Map<String, dynamic>? firstInningsData;
  final Map<String, dynamic>? secondInningsData;
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.tournamentId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.status,
    required this.format,
    required this.overs,
    required this.powerplayOvers,
    this.venue,
    required this.scheduledAt,
    this.tossWinnerId,
    this.tossDecision,
    this.matchWinnerId,
    this.winDescription,
    this.scorerId,
    this.scorerTokenId,
    this.fixtureRound,
    this.firstInningsData,
    this.secondInningsData,
    required this.createdAt,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      homeTeamId: data['homeTeamId'] ?? '',
      homeTeamName: data['homeTeamName'] ?? '',
      awayTeamId: data['awayTeamId'] ?? '',
      awayTeamName: data['awayTeamName'] ?? '',
      status: data['status'] ?? 'scheduled',
      format: data['format'] ?? 'ODI',
      overs: data['overs'] ?? 50,
      powerplayOvers: data['powerplayOvers'] ?? 10,
      venue: data['venue'],
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tossWinnerId: data['tossWinnerId'],
      tossDecision: data['tossDecision'],
      matchWinnerId: data['matchWinnerId'],
      winDescription: data['winDescription'],
      scorerId: data['scorerId'],
      scorerTokenId: data['scorerTokenId'],
      fixtureRound: data['fixtureRound'],
      firstInningsData: data['firstInnings'] != null
          ? Map<String, dynamic>.from(data['firstInnings'])
          : null,
      secondInningsData: data['secondInnings'] != null
          ? Map<String, dynamic>.from(data['secondInnings'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'tournamentId': tournamentId,
    'homeTeamId': homeTeamId,
    'homeTeamName': homeTeamName,
    'awayTeamId': awayTeamId,
    'awayTeamName': awayTeamName,
    'status': status,
    'format': format,
    'overs': overs,
    'powerplayOvers': powerplayOvers,
    'venue': venue,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'tossWinnerId': tossWinnerId,
    'tossDecision': tossDecision,
    'matchWinnerId': matchWinnerId,
    'winDescription': winDescription,
    'scorerId': scorerId,
    'scorerTokenId': scorerTokenId,
    'fixtureRound': fixtureRound,
    'firstInnings': firstInningsData,
    'secondInnings': secondInningsData,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  MatchEntity toEntity() => MatchEntity(
    id: id, tournamentId: tournamentId,
    homeTeamId: homeTeamId, homeTeamName: homeTeamName,
    awayTeamId: awayTeamId, awayTeamName: awayTeamName,
    status: status, format: format, overs: overs,
    powerplayOvers: powerplayOvers, venue: venue,
    scheduledAt: scheduledAt,
    tossWinnerId: tossWinnerId, tossDecision: tossDecision,
    matchWinnerId: matchWinnerId, winDescription: winDescription,
    scorerId: scorerId, scorerTokenId: scorerTokenId,
    fixtureRound: fixtureRound, createdAt: createdAt,
    firstInnings: firstInningsData != null
        ? _parseInnings(firstInningsData!) : null,
    secondInnings: secondInningsData != null
        ? _parseInnings(secondInningsData!) : null,
  );

  InningsEntity _parseInnings(Map<String, dynamic> data) {
    final batterScores = (data['batterScores'] as List? ?? [])
        .map((b) => BatterScoreEntity(
          playerId: b['playerId'] ?? '',
          playerName: b['playerName'] ?? '',
          runs: b['runs'] ?? 0,
          balls: b['balls'] ?? 0,
          fours: b['fours'] ?? 0,
          sixes: b['sixes'] ?? 0,
          status: b['status'] ?? 'not_out',
          dismissalType: b['dismissalType'],
          dismissedBy: b['dismissedBy'],
          caughtBy: b['caughtBy'],
          isOnStrike: b['isOnStrike'] ?? false,
        )).toList();

    final bowlerScores = (data['bowlerScores'] as List? ?? [])
        .map((b) => BowlerScoreEntity(
          playerId: b['playerId'] ?? '',
          playerName: b['playerName'] ?? '',
          overs: b['overs'] ?? 0,
          balls: b['balls'] ?? 0,
          runs: b['runs'] ?? 0,
          wickets: b['wickets'] ?? 0,
          maidens: b['maidens'] ?? 0,
          wides: b['wides'] ?? 0,
          noBalls: b['noBalls'] ?? 0,
        )).toList();

    final fallOfWickets = (data['fallOfWickets'] as List? ?? [])
        .map((f) => FallOfWicketEntity(
          wicketNumber: f['wicketNumber'] ?? 0,
          runs: f['runs'] ?? 0,
          overs: f['overs'] ?? 0,
          balls: f['balls'] ?? 0,
          batsmanId: f['batsmanId'] ?? '',
          batsmanName: f['batsmanName'] ?? '',
          batsmanScore: f['batsmanScore'] ?? 0,
        )).toList();

    return InningsEntity(
      id: data['id'] ?? '',
      battingTeamId: data['battingTeamId'] ?? '',
      bowlingTeamId: data['bowlingTeamId'] ?? '',
      totalRuns: data['totalRuns'] ?? 0,
      totalWickets: data['totalWickets'] ?? 0,
      totalBalls: data['totalBalls'] ?? 0,
      extras: data['extras'] ?? 0,
      wides: data['wides'] ?? 0,
      noBalls: data['noBalls'] ?? 0,
      byes: data['byes'] ?? 0,
      legByes: data['legByes'] ?? 0,
      status: data['status'] ?? 'in_progress',
      batterScores: batterScores,
      bowlerScores: bowlerScores,
      fallOfWickets: fallOfWickets,
      currentBatter1Id: data['currentBatter1Id'],
      currentBatter2Id: data['currentBatter2Id'],
      currentBowlerId: data['currentBowlerId'],
      onStrikeBatterId: data['onStrikeBatterId'],
      currentOverBalls: data['currentOverBalls'] ?? 0,
      currentOverRuns: List<int>.from(data['currentOverRuns'] ?? []),
    );
  }
}

class BallModel {
  final String id;
  final String inningsId;
  final int overNumber;
  final int ballNumber;
  final String bowlerId;
  final String batsmanId;
  final String type;
  final int runs;
  final bool isWicket;
  final String? wicketType;
  final String? dismissedPlayerId;
  final String? fielderId;
  final bool isBoundary;
  final bool isSix;
  final String commentaryText;
  final DateTime timestamp;

  const BallModel({
    required this.id,
    required this.inningsId,
    required this.overNumber,
    required this.ballNumber,
    required this.bowlerId,
    required this.batsmanId,
    required this.type,
    required this.runs,
    required this.isWicket,
    this.wicketType,
    this.dismissedPlayerId,
    this.fielderId,
    required this.isBoundary,
    required this.isSix,
    required this.commentaryText,
    required this.timestamp,
  });

  factory BallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BallModel(
      id: doc.id,
      inningsId: data['inningsId'] ?? '',
      overNumber: data['overNumber'] ?? 0,
      ballNumber: data['ballNumber'] ?? 0,
      bowlerId: data['bowlerId'] ?? '',
      batsmanId: data['batsmanId'] ?? '',
      type: data['type'] ?? 'normal',
      runs: data['runs'] ?? 0,
      isWicket: data['isWicket'] ?? false,
      wicketType: data['wicketType'],
      dismissedPlayerId: data['dismissedPlayerId'],
      fielderId: data['fielderId'],
      isBoundary: data['isBoundary'] ?? false,
      isSix: data['isSix'] ?? false,
      commentaryText: data['commentaryText'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'inningsId': inningsId,
    'overNumber': overNumber,
    'ballNumber': ballNumber,
    'bowlerId': bowlerId,
    'batsmanId': batsmanId,
    'type': type,
    'runs': runs,
    'isWicket': isWicket,
    'wicketType': wicketType,
    'dismissedPlayerId': dismissedPlayerId,
    'fielderId': fielderId,
    'isBoundary': isBoundary,
    'isSix': isSix,
    'commentaryText': commentaryText,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  BallEntity toEntity() => BallEntity(
    id: id, inningsId: inningsId, overNumber: overNumber,
    ballNumber: ballNumber, bowlerId: bowlerId, batsmanId: batsmanId,
    type: type, runs: runs, isWicket: isWicket, wicketType: wicketType,
    dismissedPlayerId: dismissedPlayerId, fielderId: fielderId,
    isBoundary: isBoundary, isSix: isSix, commentaryText: commentaryText,
    timestamp: timestamp,
  );
}
