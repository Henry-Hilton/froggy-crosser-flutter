import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_engine.dart';

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

class GameStore {
  GameStore(this.prefs);
  final SharedPreferences prefs;
  String? get username => prefs.getString('username');
  Future<void> login(String name) async {
    if (!await prefs.setString('username', name.trim())) {
      throw StateError('Could not save player');
    }
  }

  Future<void> logout() async {
    if (!await prefs.remove('username')) throw StateError('Could not sign out');
  }

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
      return [];
    }
  }

  int best(String name) => scores
      .where((s) => s.name == name)
      .fold(0, (a, b) => a > b.score ? a : b.score);
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
