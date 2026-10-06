import 'dart:math';

/// Terrain and obstacle types used by collision detection and rendering.
enum LaneKind { river, bank, car, truck, racer }

/// A log or vehicle; [x] is its left edge and [width] is measured in tiles.
class Floater {
  Floater(this.x, this.width);
  double x;
  final double width;
}

/// Moving objects on one board row, with signed speed in tiles per second.
class Lane {
  Lane(this.row, this.kind, this.speed, this.objects);
  final int row;
  final LaneKind kind;
  final double speed;
  final List<Floater> objects;
}

/// Immutable round totals; accidents are tracked but do not deduct points.
class RoundResult {
  const RoundResult(this.crossings, this.bonuses, this.accidents);
  final int crossings, bonuses, accidents;
  int get score => crossings * 100 + bonuses * 25;
  String get title => titleFor(crossings);

  /// Maps a nonnegative crossing count to its achievement title.
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
  // Rows run from the destination (0) to the starting bank (8).
  static const columns = 9;
  static const rows = 9;
  final Random random;
  final double duration;
  late final List<Lane> lanes;
  // The frog uses a horizontal center coordinate; tile centers end in .5.
  double x = 4.5, elapsed = 0, grace = 0, feedbackTime = 0;
  int row = 8, crossings = 0, bonuses = 0, accidents = 0;
  bool paused = false;
  String feedback = 'Find your moment. Make the leap.';
  // Fly deadlines use active simulation time, so pausing freezes them.
  int? flyColumn;
  double flyUntil = 0, nextFly = 5;
  bool get finished => elapsed >= duration;
  double get remaining => max(0, duration - elapsed);
  RoundResult get result => RoundResult(crossings, bonuses, accidents);

  /// Shows temporary feedback for 1.8 seconds of active play.
  void message(String text) {
    feedback = text;
    feedbackTime = 1.8;
  }

  /// Returns the frog to the start without clearing round totals or time.
  void reset() {
    x = 4.5;
    row = 8;
    grace = .35;
  }

  /// Records an accident and starts a brief recovery period at the bank.
  void fail(String text) {
    accidents++;
    reset();
    message(text);
  }

  /// Applies a tile hop, then resolves arrival, hazards, and bonus collection.
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

  /// Collects a nearby fly only while the frog is on the middle bank.
  void collectFly() {
    if (row == 4 && flyColumn != null && (x - (flyColumn! + .5)).abs() < .65) {
      bonuses++;
      flyColumn = null;
      message('+25 • Fly bonus!');
    }
  }

  /// Tests log support or vehicle overlap on the frog's current row.
  void checkContact() {
    if (grace > 0) return;
    for (final lane in lanes.where((l) => l.row == row)) {
      if (lane.kind == LaneKind.river) {
        // Inset the log edges by .15 tiles to require secure footing.
        if (!lane.objects.any(
          (o) => x >= o.x + .15 && x <= o.x + o.width - .15,
        )) {
          fail('Splash! Try another log.');
        }
        // Traffic hits the frog when it overlaps its .56-tile-wide hitbox.
      } else if (lane.objects.any(
        (o) => x + .28 > o.x && x - .28 < o.x + o.width,
      )) {
        fail('Watch the traffic! Back to the bank.');
      }
    }
  }

  /// Advances active play by [seconds], stopping at the round deadline.
  /// Substeps of at most 1/60 second reduce missed collisions on slow frames.
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
          // A supported frog drifts with its river lane between hops.
          x += lane.speed * dt;
        }
        for (final o in lane.objects) {
          o.x += lane.speed * dt;
          // Wrap only after an object has cleared the board and its margin.
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
      // A fly lasts five seconds; the next spawn is ten seconds later.
      if (elapsed >= nextFly) {
        flyColumn = random.nextInt(9);
        flyUntil = elapsed + 5;
        nextFly = elapsed + 10;
      }
    }
    // Snap to the intended time to avoid accumulated substep rounding error.
    elapsed = targetElapsed;
  }
}
