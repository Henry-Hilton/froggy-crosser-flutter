import 'dart:math';

enum LaneKind { river, bank, car, truck, racer }

class Floater {
  Floater(this.x, this.width);
  double x;
  final double width;
}

class Lane {
  Lane(this.row, this.kind, this.speed, this.objects);
  final int row;
  final LaneKind kind;
  final double speed;
  final List<Floater> objects;
}

class RoundResult {
  const RoundResult(this.crossings, this.bonuses, this.accidents);
  final int crossings, bonuses, accidents;
  int get score => crossings * 100 + bonuses * 25;
  String get title => titleFor(crossings);
  static String titleFor(int n) => n >= 5
      ? 'Apex Amphibian'
      : [
          'Unlucky Amphibian',
          'Daring Tadpole',
          'Pond Explorer',
          'Agile Hopper',
          'Highway Navigator',
        ][n];
}

/// Coordinates are in tiles. Simulation runs in small steps to avoid tunnelling.
class GameEngine {
  GameEngine({Random? random, this.duration = 60})
    : random = random ?? Random() {
    lanes = [
      Lane(1, LaneKind.river, .65, [
        Floater(-.2, 2.6),
        Floater(3.5, 2.6),
        Floater(7.2, 2.6),
      ]),
      Lane(2, LaneKind.river, -.85, [
        Floater(.5, 2.5),
        Floater(4.1, 2.5),
        Floater(7.7, 2.5),
      ]),
      Lane(3, LaneKind.river, .55, [
        Floater(-1, 2.8),
        Floater(2.8, 2.8),
        Floater(6.6, 2.8),
      ]),
      Lane(5, LaneKind.racer, -2.6, [Floater(1, 1.0), Floater(5, 1.0)]),
      Lane(6, LaneKind.truck, .85, [Floater(-1, 1.9), Floater(4, 1.9)]),
      Lane(7, LaneKind.car, -1.45, [Floater(.3, 1.25), Floater(4.6, 1.25)]),
    ];
  }
  static const columns = 9;
  static const rows = 9;
  final Random random;
  final double duration;
  late final List<Lane> lanes;
  double x = 4.5, elapsed = 0, grace = 0, feedbackTime = 0;
  int row = 8, crossings = 0, bonuses = 0, accidents = 0;
  bool paused = false;
  String feedback = 'Find your moment. Make the leap.';
  int? flyColumn;
  double flyUntil = 0, nextFly = 5;
  bool get finished => elapsed >= duration;
  double get remaining => max(0, duration - elapsed);
  RoundResult get result => RoundResult(crossings, bonuses, accidents);
  void message(String text) {
    feedback = text;
    feedbackTime = 1.8;
  }

  void reset() {
    x = 4.5;
    row = 8;
    grace = .35;
  }

  void fail(String text) {
    accidents++;
    reset();
    message(text);
  }

  void move(int dx, int dy) {
    if (paused || finished || grace > 0) return;
    x = (x + dx).clamp(.5, 8.5);
    row = (row + dy).clamp(0, 8);
    if (row == 0) {
      crossings++;
      reset();
      message('+100 • Safe and sound!');
      return;
    }
    checkContact();
    collectFly();
  }

  void collectFly() {
    if (row == 4 && flyColumn != null && (x - (flyColumn! + .5)).abs() < .65) {
      bonuses++;
      flyColumn = null;
      message('+25 • Fly bonus!');
    }
  }

  void checkContact() {
    if (grace > 0) return;
    for (final lane in lanes.where((l) => l.row == row)) {
      if (lane.kind == LaneKind.river) {
        if (!lane.objects.any(
          (o) => x >= o.x + .15 && x <= o.x + o.width - .15,
        )) {
          fail('Splash! Try another log.');
        }
      } else if (lane.objects.any(
        (o) => x + .28 > o.x && x - .28 < o.x + o.width,
      )) {
        fail('Watch the traffic! Back to the bank.');
      }
    }
  }

  void update(double seconds) {
    if (paused || finished || seconds <= 0) return;
    double left = min(seconds, remaining);
    final targetElapsed = min(duration, elapsed + left);
    while (left > .000001) {
      final dt = min(left, 1 / 60);
      left -= dt;
      elapsed = min(duration, elapsed + dt);
      grace = max(0, grace - dt);
      feedbackTime = max(0, feedbackTime - dt);
      for (final lane in lanes) {
        if (row == lane.row && lane.kind == LaneKind.river) {
          x += lane.speed * dt;
        }
        for (final o in lane.objects) {
          o.x += lane.speed * dt;
          if (lane.speed > 0 && o.x > 9.5) o.x = -o.width - .5;
          if (lane.speed < 0 && o.x + o.width < -.5) o.x = 9.5;
        }
      }
      if (x < .25 || x > 8.75) {
        fail('Stay on the board!');
      }
      checkContact();
      collectFly();
      if (flyColumn != null && elapsed >= flyUntil) flyColumn = null;
      if (elapsed >= nextFly) {
        flyColumn = random.nextInt(9);
        flyUntil = elapsed + 5;
        nextFly = elapsed + 10;
      }
    }
    elapsed = targetElapsed;
  }
}
