import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_engine.dart';

/// One player's saved personal best and its associated crossing count.
class ScoreEntry {
  const ScoreEntry(this.name, this.score, this.crossings);
  final String name;
  final int score, crossings;
  Map<String, Object> toJson() => {
    'name': name,
    'score': score,
    'crossings': crossings,
  };
}

/// Device-local player identity and leaderboard backed by SharedPreferences.
class GameStore {
  GameStore(this.prefs);
  final SharedPreferences prefs;
  String? get username => prefs.getString('username');

  /// Stores a trimmed, case-sensitive player name; no online account is used.
  Future<void> login(String name) async {
    if (!await prefs.setString('username', name.trim())) {
      throw StateError('Could not save player');
    }
  }

  /// Removes the active name while retaining every saved personal best.
  Future<void> logout() async {
    if (!await prefs.remove('username')) throw StateError('Could not sign out');
  }

  /// Decodes scores, ranked highest first with alphabetical name tie breaks.
  List<ScoreEntry> get scores {
    try {
      final raw = jsonDecode(prefs.getString('scores') ?? '[]') as List;
      final result = raw
          .map(
            (e) => ScoreEntry(
              e['name'] as String,
              e['score'] as int,
              e['crossings'] as int,
            ),
          )
          .toList();
      result.sort((a, b) {
        final order = b.score.compareTo(a.score);
        return order != 0 ? order : a.name.compareTo(b.name);
      });
      return result;
    } catch (_) {
      // Treat malformed stored data as an empty leaderboard so screens can load.
      return [];
    }
  }

  /// Returns the player's highest stored score, or zero if none exists.
  int best(String name) => scores
      .where((s) => s.name == name)
      .fold(0, (a, b) => a > b.score ? a : b.score);

  /// Keeps one best entry per name and persists it as JSON.
  /// Returns true for a newly saved positive best, false for ties/lower scores
  /// or a saved zero score. A storage failure throws [StateError].
  Future<bool> save(String name, RoundResult result) async {
    final all = scores;
    final existing = all.where((s) => s.name == name);
    if (existing.isNotEmpty && existing.first.score >= result.score) {
      return false;
    }
    all.removeWhere((s) => s.name == name);
    all.add(ScoreEntry(name, result.score, result.crossings));
    if (!await prefs.setString(
      'scores',
      jsonEncode(all.map((e) => e.toJson()).toList()),
    )) {
      throw StateError('Could not save score');
    }
    return result.score > 0;
  }
}
