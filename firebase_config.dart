// lib/core/constants/firebase_config.dart
class FirebaseConfig {
  static const String apiKey = "AIzaSyATKUoiVdv9W50rXobgh5qFhsCehmff1Yg";
  static const String authDomain = "a7-cricket.firebaseapp.com";
  static const String databaseURL = "https://a7-cricket-default-rtdb.firebaseio.com";
  static const String projectId = "a7-cricket";
  static const String storageBucket = "a7-cricket.firebasestorage.app";
  static const String messagingSenderId = "127154040305";
  static const String appId = "1:127154040305:web:4c72b512da3910e771e850";
  static const String measurementId = "G-WSZZJ8T2YX";
}

// Firestore Collection Paths
class FirestorePaths {
  // Top-level collections
  static const String users = 'users';
  static const String tournaments = 'tournaments';
  static const String teams = 'teams';
  static const String players = 'players';
  static const String matches = 'matches';
  static const String scorerTokens = 'scorer_tokens';

  // Subcollections
  static String matchInnings(String matchId) => 'matches/$matchId/innings';
  static String inningsBalls(String matchId, String inningsId) =>
      'matches/$matchId/innings/$inningsId/balls';
  static String matchCommentary(String matchId) => 'matches/$matchId/commentary';
  static String playerStats(String playerId) => 'players/$playerId/stats';
  static String tournamentFixtures(String tournamentId) =>
      'tournaments/$tournamentId/fixtures';
  static String tournamentTeams(String tournamentId) =>
      'tournaments/$tournamentId/teams';
}
