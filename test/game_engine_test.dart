import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:froggy_crosser/game_engine.dart';
import 'package:froggy_crosser/game_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('All six assignment titles and score formula', () {
    expect(List.generate(6, RoundResult.titleFor), [
      'Unlucky Amphibian',
      'Daring Tadpole',
      'Pond Explorer',
      'Agile Hopper',
      'Highway Navigator',
      'Apex Amphibian',
    ]);
    expect(RoundResult.titleFor(20), 'Apex Amphibian');
    expect(const RoundResult(3, 2, 9).score, 350);
  });
  test('Four directions obey board bounds', () {
    final g = GameEngine();
    g.move(-1, 0);
    expect(g.x, 3.5);
    g.move(1, 0);
    expect(g.x, 4.5);
    g.row = 4;
    g.move(0, 1);
    expect(g.row, 5);
    g.move(0, -1);
    expect(g.row, 4);
    for (int i = 0; i < 20; i++) {
      g.move(-1, 0);
    }
    expect(g.x, .5);
    g.row = 8;
    g.move(0, 1);
    expect(g.row, 8);
  });
  test('All three vehicle types cause a reset', () {
    for (final kind in [LaneKind.car, LaneKind.truck, LaneKind.racer]) {
      final g = GameEngine();
      final lane = g.lanes.firstWhere((l) => l.kind == kind);
      g.row = lane.row;
      g.x = lane.objects.last.x + .5;
      g.checkContact();
      expect(g.accidents, 1);
      expect(g.row, 8);
      expect(g.x, 4.5);
    }
  });
  test('River supports, carries, drowns, and rejects out of bounds', () {
    final g = GameEngine();
    g.row = 1;
    g.x = 1;
    g.update(.2);
    expect(g.row, 1);
    expect(g.x, closeTo(1.13, .001));
    g.x = 3;
    g.checkContact();
    expect(g.row, 8);
    expect(g.accidents, 1);
    g.grace = 0;
    g.row = 1;
    g.x = 8.74;
    g.update(.2);
    expect(g.row, 8);
  });
  test('Crossing scores only once and returns frog to start', () {
    final g = GameEngine();
    g.row = 1;
    g.x = 1;
    g.move(0, -1);
    expect(g.crossings, 1);
    expect(g.result.score, 100);
    expect(g.row, 8);
    g.move(0, -1);
    expect(g.row, 8); // Brief respawn protection.
  });
  test('Fly appears, expires and can only be collected once', () {
    final g = GameEngine(random: Random(7));
    g.update(5.1);
    expect(g.flyColumn, isNotNull);
    g.row = 4;
    g.x = g.flyColumn! + .5;
    g.collectFly();
    g.collectFly();
    expect(g.bonuses, 1);
    expect(g.result.score, 25);
    g.update(10);
    expect(g.flyColumn, isNotNull);
    g.update(5.1);
    expect(g.flyColumn, isNull);
  });
  test('Pause freezes simulation and timer ends exactly', () {
    final g = GameEngine(duration: 1);
    g.paused = true;
    final x = g.lanes.first.objects.first.x;
    g.update(10);
    expect(g.elapsed, 0);
    expect(g.lanes.first.objects.first.x, x);
    g.paused = false;
    g.update(10);
    expect(g.finished, true);
    expect(g.remaining, 0);
    final before = g.x;
    g.move(1, 0);
    expect(g.x, before);
  });
  test(
    'Shared Preferences stores session and per-user best, sorted top three',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = GameStore(await SharedPreferences.getInstance());
      await s.login(' Henry ');
      expect(s.username, 'Henry');
      expect(await s.save('Henry', const RoundResult(3, 0, 0)), true);
      expect(await s.save('Henry', const RoundResult(2, 0, 0)), false);
      await s.save('Alice', const RoundResult(5, 0, 0));
      await s.save('Bob', const RoundResult(4, 0, 0));
      await s.save('Dee', const RoundResult(1, 0, 0));
      final restored = GameStore(await SharedPreferences.getInstance());
      expect(restored.username, 'Henry');
      expect(restored.scores.take(3).map((s) => s.name), [
        'Alice',
        'Bob',
        'Henry',
      ]);
      await restored.logout();
      expect(restored.username, isNull);
      expect(restored.best('Henry'), 300);
    },
  );
}
