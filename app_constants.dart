// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'Cricket A7';
  static const String appTagline = 'Professional Cricket Management';
  static const String developer = 'Asif Lashari';
  static const String developerHandle = 'asifnawazlashari';
  static const String studio = 'A7 Studio';
  static const String version = '1.0.0';

  // User Roles
  static const String roleOrganizer = 'organizer';
  static const String roleCaptain = 'captain';
  static const String roleScorer = 'scorer';
  static const String rolePlayer = 'player';

  // Match Formats
  static const String formatODI = 'ODI';
  static const String formatT20 = 'T20';
  static const String formatTest = 'Test';
  static const String formatCustom = 'Custom';

  // Match Status
  static const String matchStatusScheduled = 'scheduled';
  static const String matchStatusLive = 'live';
  static const String matchStatusCompleted = 'completed';
  static const String matchStatusAbandoned = 'abandoned';

  // Innings Status
  static const String inningsStatusInProgress = 'in_progress';
  static const String inningsStatusCompleted = 'completed';

  // Ball Types
  static const String ballTypeNormal = 'normal';
  static const String ballTypeWide = 'wide';
  static const String ballTypeNoBall = 'no_ball';
  static const String ballTypeWicket = 'wicket';
  static const String ballTypeBye = 'bye';
  static const String ballTypeLegBye = 'leg_bye';

  // Wicket Types
  static const String wicketBowled = 'bowled';
  static const String wicketCaught = 'caught';
  static const String wicketLBW = 'lbw';
  static const String wicketRunOut = 'run_out';
  static const String wicketStumped = 'stumped';
  static const String wicketHitWicket = 'hit_wicket';
  static const String wicketRetiredHurt = 'retired_hurt';
  static const String wicketObstruct = 'obstructing_the_field';

  // Tournament Types
  static const String tournamentRoundRobin = 'round_robin';
  static const String tournamentKnockout = 'knockout';
  static const String tournamentGroupKnockout = 'group_knockout';

  // Default Values
  static const int defaultODIOvers = 50;
  static const int defaultT20Overs = 20;
  static const int defaultPowerplayOvers = 10;
  static const int playersPerTeam = 11;

  // Scorer Token
  static const int scorerTokenExpiryHours = 24;
}
