import 'dart:math';

import 'package:flutter/material.dart';

import 'game_engine.dart';

/// Shared palette for the screens and procedurally drawn artwork.
const ink = Color(0xff142a24);
const lime = Color(0xffcefa72);
const cream = Color(0xfff5f4e8);

/// Original vector artwork, rendered directly by Flutter (no remote assets).
class BoardPainter extends CustomPainter {
  BoardPainter(this.game, {this.decorative = false}) : super();
  final GameEngine game;
  final bool decorative;
  @override
  void paint(Canvas canvas, Size size) {
    // Convert the engine's tile coordinates to the available canvas size.
    final w = size.width / 9, h = size.height / 9;
    final p = Paint();
    void box(Rect r, Color color, [double radius = 0]) {
      p.color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), p);
    }

    // Paint terrain first so moving objects and the frog appear above it.
    for (int row = 0; row < 9; row++) {
      final water = row >= 1 && row <= 3;
      final road = row >= 5 && row <= 7;
      box(
        Rect.fromLTWH(0, row * h, size.width, h),
        water
            ? Color(row.isEven ? 0xff387f80 : 0xff327577)
            : road
            ? const Color(0xff344441)
            : Color(row == 0 ? 0xff829e50 : 0xffa0b867),
      );
      if (water) {
        for (int i = 0; i < 12; i++) {
          final x = ((i * .9 + game.elapsed * .16) % 10 - .5) * w;
          box(
            Rect.fromLTWH(x, row * h + h * .68, w * .35, 2),
            const Color(0xff559795),
            2,
          );
        }
      } else if (road) {
        for (int i = 0; i < 9; i++) {
          box(
            Rect.fromLTWH(i * w + w * .2, row * h, w * .4, 2),
            const Color(0xff7b8980),
          );
        }
      } else {
        for (int i = 0; i < 18; i++) {
          box(
            Rect.fromLTWH(
              i * w * .55,
              row * h + (i.isEven ? .28 : .7) * h,
              3,
              5,
            ),
            const Color(0xff768e4e),
            1,
          );
        }
      }
    }
    for (int i = 0; i < 5; i++) {
      p.color = const Color(0xff647f3c);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset((i * 1.8 + .9) * w, h * .5),
          width: w * .9,
          height: h * .65,
        ),
        p,
      );
      p.color = const Color(0xffb8d47b);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset((i * 1.8 + .9) * w, h * .5),
          width: w * .65,
          height: h * .5,
        ),
        .3,
        5.5,
        true,
        p,
      );
    }
    // Render the same positions and widths used by collision detection.
    for (final lane in game.lanes) {
      for (final o in lane.objects) {
        final r = Rect.fromLTWH(
          o.x * w,
          lane.row * h + h * .16,
          o.width * w,
          h * .68,
        );
        if (lane.kind == LaneKind.river) {
          box(r.translate(0, 3), const Color(0xff235957), 10);
          box(r, const Color(0xffaa784b), 10);
          box(
            Rect.fromLTWH(r.left + 7, r.top + 5, r.width - 14, 4),
            const Color(0xffc89b64),
            2,
          );
          box(
            Rect.fromLTWH(r.left + 9, r.bottom - 9, r.width - 18, 2),
            const Color(0xff805738),
            1,
          );
          for (int n = 0; n < 3; n++) {
            box(
              Rect.fromLTWH(
                r.left + r.width * (.2 + n * .3),
                r.top + r.height * .5,
                w * .25,
                2,
              ),
              const Color(0xff805738),
              2,
            );
          }
        } else {
          final color = switch (lane.kind) {
            LaneKind.truck => const Color(0xffe8c873),
            LaneKind.racer => const Color(0xffef8978),
            _ => const Color(0xff99bdcf),
          };
          for (final dx in [.18, .75]) {
            box(
              Rect.fromLTWH(
                r.left + r.width * dx - 4,
                r.top - 3,
                9,
                r.height + 6,
              ),
              const Color(0xff1b2926),
              3,
            );
          }
          box(r, color, 6);
          // Place the windshield toward the direction of travel.
          final front = lane.speed > 0
              ? r.right - r.width * .34
              : r.left + r.width * .12;
          box(
            Rect.fromLTWH(front, r.top + 4, r.width * .22, r.height - 8),
            const Color(0xff2d5557),
            3,
          );
          if (lane.kind == LaneKind.truck) {
            box(
              Rect.fromLTWH(r.left + 4, r.top + 3, r.width * .6, r.height - 6),
              const Color(0xfff1dfa3),
              3,
            );
          }
          if (lane.kind == LaneKind.racer) {
            box(Rect.fromLTWH(r.left, r.center.dy - 2, r.width, 4), cream, 1);
          }
        }
      }
    }
    if (game.flyColumn != null) {
      final c = Offset(
        (game.flyColumn! + .5) * w,
        4.5 * h + sin(game.elapsed * 7) * 3,
      );
      p.color = const Color(0xfffce491);
      canvas.drawCircle(c, w * .32, p);
      p.color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(-5, -4), width: 9, height: 7),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(5, -4), width: 9, height: 7),
        p,
      );
      p.color = ink;
      canvas.drawOval(Rect.fromCenter(center: c, width: 7, height: 12), p);
    }
    drawFrog(
      canvas,
      Offset(game.x * w, (game.row + .5) * h),
      min(w, h) * .85,
      game.grace > 0 ? .6 : 1,
    );
  }

  /// Draws the reusable frog around [center], scaled from a 50-unit design.
  static void drawFrog(
    Canvas c,
    Offset center,
    double size, [
    double opacity = 1,
  ]) {
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(size / 50);
    final p = Paint();
    void oval(Rect r, Color color) {
      p.color = color.withValues(alpha: opacity);
      c.drawOval(r, p);
    }

    oval(const Rect.fromLTWH(-22, -12, 44, 38), const Color(0xff244a30));
    for (final dx in [-1.0, 1.0]) {
      oval(
        Rect.fromCenter(center: Offset(dx * 20, 15), width: 14, height: 17),
        const Color(0xff84c94e),
      );
      oval(
        Rect.fromCenter(center: Offset(dx * 19, -4), width: 12, height: 16),
        const Color(0xff84c94e),
      );
    }
    oval(const Rect.fromLTWH(-18, -18, 36, 39), const Color(0xffb2e667));
    oval(const Rect.fromLTWH(-11, 0, 22, 16), const Color(0xffd7f58e));
    for (final dx in [-10.0, 10.0]) {
      oval(
        Rect.fromCenter(center: Offset(dx, -15), width: 17, height: 19),
        const Color(0xffb2e667),
      );
      oval(
        Rect.fromCenter(center: Offset(dx, -17), width: 10, height: 11),
        cream,
      );
      oval(Rect.fromCenter(center: Offset(dx, -19), width: 5, height: 6), ink);
    }
    p
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    c.drawArc(const Rect.fromLTWH(-7, -7, 14, 9), .2, 2.7, false, p);
    c.restore();
  }

  @override
  // The engine mutates in place, so delegate identity cannot detect movement.
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}

/// Static frog illustration reused by menus, pause overlays, and results.
class FrogArt extends StatelessWidget {
  const FrogArt({super.key, this.size = 100});
  final double size;
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FrogPainter()),
    ),
  );
}

class _FrogPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => BoardPainter.drawFrog(
    canvas,
    Offset(size.width / 2, size.height / 2),
    size.width * .8,
  );
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
