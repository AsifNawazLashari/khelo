// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> managedTournaments;
  final List<String> managedTeams;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.managedTournaments = const [],
    this.managedTeams = const [],
  });

  bool get isOrganizer => role == 'organizer';
  bool get isCaptain => role == 'captain';
  bool get isScorer => role == 'scorer';
  bool get isPlayer => role == 'player';

  @override
  List<Object?> get props => [uid, email, role];
}

// lib/domain/entities/tournament_entity.dart
class TournamentEntity extends Equatable {
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

  const TournamentEntity({
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

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  int get registeredTeams => teamIds.length;

  @override
  List<Object?> get props => [id, name, status];
}

// lib/domain/entities/team_entity.dart
class TeamEntity extends Equatable {
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

  const TeamEntity({
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

  int get squadSize => playerIds.length;

  @override
  List<Object?> get props => [id, name, captainId];
}

// lib/domain/entities/player_entity.dart
class PlayerEntity extends Equatable {
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
  final PlayerStatsEntity battingStats;
  final PlayerStatsEntity bowlingStats;
  final DateTime createdAt;

  const PlayerEntity({
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

  @override
  List<Object?> get props => [id, name, teamId];
}

class PlayerStatsEntity extends Equatable {
  // Batting
  final int matchesPlayed;
  final int innings;
  final int totalRuns;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final int highScore;
  final int notOuts;
  final int fifties;
  final int hundreds;
  final int ducks;
  // Bowling
  final int oversBowled;
  final int runsConceded;
  final int wickets;
  final int maidens;
  final int wides;
  final int noBalls;
  final int fiveWickets;
  final int bestBowling;
  final int bestBowlingRuns;

  const PlayerStatsEntity({
    this.matchesPlayed = 0,
    this.innings = 0,
    this.totalRuns = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.highScore = 0,
    this.notOuts = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.ducks = 0,
    this.oversBowled = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.maidens = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.fiveWickets = 0,
    this.bestBowling = 0,
    this.bestBowlingRuns = 0,
  });

  double get battingAverage => innings > notOuts
      ? totalRuns / (innings - notOuts)
      : totalRuns.toDouble();
  double get strikeRate => ballsFaced > 0 ? (totalRuns / ballsFaced) * 100 : 0;
  double get bowlingAverage => wickets > 0 ? runsConceded / wickets : 0;
  double get economyRate => oversBowled > 0 ? runsConceded / oversBowled : 0;

  @override
  List<Object?> get props => [matchesPlayed, totalRuns, wickets];
}

// lib/domain/entities/match_entity.dart
class MatchEntity extends Equatable {
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
  final InningsEntity? firstInnings;
  final InningsEntity? secondInnings;
  final String? currentBattingTeamId;
  final String? scorerId;
  final String? scorerTokenId;
  final String? fixtureRound;
  final DateTime createdAt;

  const MatchEntity({
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
    this.firstInnings,
    this.secondInnings,
    this.currentBattingTeamId,
    this.scorerId,
    this.scorerTokenId,
    this.fixtureRound,
    required this.createdAt,
  });

  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';

  @override
  List<Object?> get props => [id, tournamentId, homeTeamId, awayTeamId];
}

class InningsEntity extends Equatable {
  final String id;
  final String battingTeamId;
  final String bowlingTeamId;
  final int totalRuns;
  final int totalWickets;
  final int totalBalls;
  final int extras;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final String status;
  final List<BatterScoreEntity> batterScores;
  final List<BowlerScoreEntity> bowlerScores;
  final List<FallOfWicketEntity> fallOfWickets;
  final String? currentBatter1Id;
  final String? currentBatter2Id;
  final String? currentBowlerId;
  final String? onStrikeBatterId;
  final int currentOverBalls;
  final List<int> currentOverRuns;

  const InningsEntity({
    required this.id,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalBalls,
    required this.extras,
    required this.wides,
    required this.noBalls,
    required this.byes,
    required this.legByes,
    required this.status,
    required this.batterScores,
    required this.bowlerScores,
    required this.fallOfWickets,
    this.currentBatter1Id,
    this.currentBatter2Id,
    this.currentBowlerId,
    this.onStrikeBatterId,
    required this.currentOverBalls,
    required this.currentOverRuns,
  });

  int get completedOvers => totalBalls ~/ 6;
  int get ballsInCurrentOver => totalBalls % 6;
  double get currentOverNumber => completedOvers + (ballsInCurrentOver / 10);
  double get runRate => totalBalls > 0 ? (totalRuns / totalBalls) * 6 : 0;
  String get score => '$totalRuns/$totalWickets';
  String get oversDisplay =>
      '$completedOvers.${ballsInCurrentOver}';

  @override
  List<Object?> get props => [id, battingTeamId, totalRuns, totalWickets];
}

class BatterScoreEntity extends Equatable {
  final String playerId;
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final String status;
  final String? dismissalType;
  final String? dismissedBy;
  final String? caughtBy;
  final bool isOnStrike;

  const BatterScoreEntity({
    required this.playerId,
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.status,
    this.dismissalType,
    this.dismissedBy,
    this.caughtBy,
    required this.isOnStrike,
  });

  double get strikeRate => balls > 0 ? (runs / balls) * 100 : 0;
  bool get isNotOut => status == 'not_out' || status == 'batting';

  @override
  List<Object?> get props => [playerId, runs, balls];
}

class BowlerScoreEntity extends Equatable {
  final String playerId;
  final String playerName;
  final int overs;
  final int balls;
  final int runs;
  final int wickets;
  final int maidens;
  final int wides;
  final int noBalls;

  const BowlerScoreEntity({
    required this.playerId,
    required this.playerName,
    required this.overs,
    required this.balls,
    required this.runs,
    required this.wickets,
    required this.maidens,
    required this.wides,
    required this.noBalls,
  });

  double get economy => overs > 0 ? runs / overs : 0;
  String get figuresDisplay => '$wickets/${runs}';
  String get oversDisplay => '$overs.$balls';

  @override
  List<Object?> get props => [playerId, overs, runs, wickets];
}

class FallOfWicketEntity extends Equatable {
  final int wicketNumber;
  final int runs;
  final int overs;
  final int balls;
  final String batsmanId;
  final String batsmanName;
  final int batsmanScore;

  const FallOfWicketEntity({
    required this.wicketNumber,
    required this.runs,
    required this.overs,
    required this.balls,
    required this.batsmanId,
    required this.batsmanName,
    required this.batsmanScore,
  });

  @override
  List<Object?> get props => [wicketNumber, runs, batsmanId];
}

class BallEntity extends Equatable {
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

  const BallEntity({
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

  bool get isExtra => type == 'wide' || type == 'no_ball' ||
      type == 'bye' || type == 'leg_bye';
  bool get countsAsBall => type != 'wide' && type != 'no_ball';

  @override
  List<Object?> get props => [id, overNumber, ballNumber];
}

class CommentaryEntity extends Equatable {
  final String id;
  final String matchId;
  final String inningsId;
  final int overNumber;
  final int ballNumber;
  final String text;
  final String type;
  final DateTime timestamp;
  final String authorId;

  const CommentaryEntity({
    required this.id,
    required this.matchId,
    required this.inningsId,
    required this.overNumber,
    required this.ballNumber,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.authorId,
  });

  @override
  List<Object?> get props => [id, matchId, overNumber, ballNumber];
}

class ScorerTokenEntity extends Equatable {
  final String id;
  final String matchId;
  final String tournamentId;
  final String organizerId;
  final String? assignedScorerId;
  final bool isUsed;
  final DateTime expiresAt;
  final DateTime createdAt;

  const ScorerTokenEntity({
    required this.id,
    required this.matchId,
    required this.tournamentId,
    required this.organizerId,
    this.assignedScorerId,
    required this.isUsed,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isValid => !isUsed && DateTime.now().isBefore(expiresAt);

  @override
  List<Object?> get props => [id, matchId, isValid];
}
