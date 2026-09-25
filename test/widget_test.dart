import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggy_crosser/main.dart';
import 'package:froggy_crosser/game_store.dart';
import 'package:froggy_crosser/game_engine.dart';

void main() {
  Future<GameStore> store([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return GameStore(await SharedPreferences.getInstance());
  }

  testWidgets('Login validation, instructions, all swipes, pause and exit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await store();
    await tester.pumpWidget(FroggyApp(store: s));
    await tester.tap(find.text('Let’s hop in  →'));
    await tester.pump();
    expect(find.text('Enter a name to start hopping.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Henry');
    await tester.tap(find.text('Let’s hop in  →'));
    await tester.pumpAndSettle();
    expect(s.username, 'Henry');
    await tester.tap(find.text('Play Game'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('game-board')), findsOneWidget);
    for (final offset in [
      const Offset(-60, 0),
      const Offset(60, 0),
      const Offset(0, -60),
      const Offset(0, 60),
    ]) {
      await tester.drag(find.byKey(const Key('game-board')), offset);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Take a breather.'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.tap(find.byTooltip('Leave round'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Play Game'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Saved user skips login; timer navigates to result and records score',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = await store({'username': 'Player'});
      await tester.pumpWidget(FroggyApp(store: s));
      expect(find.byType(HomeScreen), findsOneWidget);
      final engine = GameEngine(duration: .2)..crossings = 5;
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(store: s, engine: engine),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text('Apex Amphibian'), findsOneWidget);
      expect(s.best('Player'), 500);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('High Scores'), findsOneWidget);
      expect(find.text('Main Menu'), findsOneWidget);
      await tester.tap(find.text('High Scores'));
      await tester.pumpAndSettle();
      expect(find.text('Player'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GameScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Leave round'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Narrow phone layout and logout retain leaderboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await store({'username': 'Player'});
    await s.save('Player', const RoundResult(1, 0, 0));
    await tester.pumpWidget(FroggyApp(store: s));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(s.best('Player'), 100);
    expect(tester.takeException(), isNull);
  });
}
