import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'art.dart';
import 'game_engine.dart';
import 'game_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = GameStore(await SharedPreferences.getInstance());
  runApp(FroggyApp(store: store));
}

class FroggyApp extends StatelessWidget {
  const FroggyApp({super.key, required this.store});
  final GameStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Froggy Crosser',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        secondary: lime,
        surface: cream,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: cream,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 40,
          height: 1.05,
          fontWeight: FontWeight.w900,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
      ),
    ),
    home: store.username?.isNotEmpty == true
        ? HomeScreen(store: store)
        : LoginScreen(store: store),
  );
}

void openScreen(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
void resetTo(BuildContext context, Widget screen) => Navigator.of(context)
    .pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screen),
      (_) => false,
    );
void showError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not save on this device. Please try again.'),
      ),
    );

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(padding: const EdgeInsets.all(24), children: children),
      ),
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 2.4,
      fontWeight: FontWeight.w800,
      color: Color(0xff63776a),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store});
  final GameStore store;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.store.login(controller.text);
      if (mounted) resetTo(context, HomeScreen(store: widget.store));
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageBody(
      children: [
        const SizedBox(height: 32),
        const Eyebrow('A LITTLE FROG. A BIG ADVENTURE.'),
        const SizedBox(height: 30),
        const Hero(tag: 'frog', child: FrogArt(size: 150)),
        const SizedBox(height: 24),
        Text(
          'Froggy\nCrosser',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 58, letterSpacing: -2),
        ),
        const SizedBox(height: 16),
        const Text(
          'Busy roads. Drifting logs.\nHow many frogs can you bring home?',
          style: TextStyle(fontSize: 17, height: 1.5),
        ),
        const SizedBox(height: 36),
        Form(
          key: form,
          child: TextFormField(
            controller: controller,
            maxLength: 20,
            textInputAction: TextInputAction.go,
            onFieldSubmitted: (_) => login(),
            decoration: InputDecoration(
              labelText: 'Your player name',
              hintText: 'e.g. RiverRider',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            validator: (s) => s == null || s.trim().isEmpty
                ? 'Enter a name to start hopping.'
                : null,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : login,
          child: Text(busy ? 'Saving…' : 'Let’s hop in  →'),
        ),
        const SizedBox(height: 18),
        const Text(
          'No password needed. Your name and best score\nare remembered on this device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xff63776a), height: 1.5),
        ),
      ],
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});
  final GameStore store;
  Future<void> play(BuildContext context) async {
    final start = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('One small hop…'),
        content: const Text(
          'Swipe up, down, left or right to hop.\n\nAvoid cars, slow trucks, and fast racers. Ride the floating logs across the river and reach the far bank.\n\nYou have 60 seconds. Each crossing earns 100 points. Catch a golden fly on the middle bank for 25 extra points.\n\nA collision or a splash sends you back to the start. Keep trying!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (start == true && context.mounted) {
      openScreen(context, GameScreen(store: store));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'FROGGY / CROSSER',
        style: TextStyle(
          fontSize: 14,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    drawer: Drawer(
      backgroundColor: cream,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FrogArt(size: 72),
                  const SizedBox(height: 16),
                  const Eyebrow('PLAYER'),
                  Text(
                    store.username ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('High Score'),
              onTap: () {
                Navigator.pop(context);
                openScreen(context, ScoresScreen(store: store));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () async {
                try {
                  await store.logout();
                  if (context.mounted) {
                    resetTo(context, LoginScreen(store: store));
                  }
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Take a breath.\nThen take the leap.',
                style: TextStyle(color: Color(0xff63776a)),
              ),
            ),
          ],
        ),
      ),
    ),
    body: PageBody(
      children: [
        const SizedBox(height: 8),
        Eyebrow('WELCOME BACK, ${(store.username ?? '').toUpperCase()}'),
        const SizedBox(height: 14),
        Text(
          'The other side\nis calling.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'A 60-second dash from roadside to riverside.',
          style: TextStyle(color: Color(0xff63776a), fontSize: 16),
        ),
        const SizedBox(height: 28),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1.35,
            child: CustomPaint(
              painter: BoardPainter(GameEngine(), decorative: true),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Eyebrow('YOUR PERSONAL BEST')),
            const SizedBox(width: 12),
            Text(
              '${store.best(store.username ?? '')} pts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => play(context),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play Game'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => openScreen(context, ScoresScreen(store: store)),
          icon: const Icon(Icons.emoji_events_outlined),
          label: const Text('High Scores'),
        ),
        const SizedBox(height: 24),
        const Text(
          'SWIPE TO HOP  •  RIDE THE LOGS  •  GET HOME',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: Color(0xff63776a),
          ),
        ),
      ],
    ),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.store, this.engine});
  final GameStore store;
  final GameEngine? engine;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameEngine game;
  late final Ticker ticker;
  Duration? last;
  Offset swipe = Offset.zero;
  bool ending = false;
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    game = widget.engine ?? GameEngine();
    WidgetsBinding.instance.addObserver(this);
    ticker = createTicker(tick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !ending) {
      setState(() => game.paused = true);
      ticker.stop();
    }
    last = null;
  }

  void tick(Duration now) {
    final previous = last;
    last = now;
    if (previous == null || game.paused || ending) return;
    setState(() => game.update((now - previous).inMicroseconds / 1000000));
    if (game.finished) finish();
  }

  Future<void> finish() async {
    ending = true;
    ticker.stop();
    bool record = false;
    bool saved = true;
    try {
      record = await widget.store.save(widget.store.username!, game.result);
    } catch (_) {
      saved = false;
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            store: widget.store,
            result: game.result,
            record: record,
            saved: saved,
          ),
        ),
      );
    }
  }

  void move(int dx, int dy) {
    setState(() => game.move(dx, dy));
  }

  void pause() {
    setState(() {
      game.paused = !game.paused;
      last = null;
      if (game.paused) {
        ticker.stop();
      } else if (!ending) {
        ticker.start();
      }
    });
  }

  Future<void> exit() async {
    if (ending) return;
    game.paused = true;
    ticker.stop();
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Leave this round?'),
        content: const Text('This unfinished round will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      resetTo(context, HomeScreen(store: widget.store));
    } else {
      setState(() {
        game.paused = false;
        last = null;
        ticker.start();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) exit();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: exit,
          icon: const Icon(Icons.close),
          tooltip: 'Leave round',
        ),
        title: const Text(
          'Make the leap',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: pause,
            icon: Icon(game.paused ? Icons.play_arrow : Icons.pause),
            tooltip: game.paused ? 'Resume' : 'Pause',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      stat('SCORE', '${game.result.score}'),
                      stat('HOME', '${game.crossings}'),
                      stat(
                        'TIME LEFT',
                        '${game.remaining.ceil()}s',
                        alert: game.remaining <= 10,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: game.remaining / game.duration,
                      minHeight: 6,
                      color: game.remaining <= 10
                          ? const Color(0xffd8634c)
                          : ink,
                      backgroundColor: const Color(0xffdce2ce),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = min(
                        constraints.maxWidth - 24,
                        constraints.maxHeight * .9,
                      );
                      return Center(
                        child: SizedBox(
                          width: width,
                          height: width / .9,
                          child: KeyboardListener(
                            focusNode: focus,
                            autofocus: true,
                            onKeyEvent: (event) {
                              if (event is! KeyDownEvent) return;
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowUp ||
                                  event.logicalKey == LogicalKeyboardKey.keyW) {
                                move(0, -1);
                              }
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowDown ||
                                  event.logicalKey == LogicalKeyboardKey.keyS) {
                                move(0, 1);
                              }
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft ||
                                  event.logicalKey == LogicalKeyboardKey.keyA) {
                                move(-1, 0);
                              }
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight ||
                                  event.logicalKey == LogicalKeyboardKey.keyD) {
                                move(1, 0);
                              }
                            },
                            child: GestureDetector(
                              key: const Key('game-board'),
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (_) => swipe = Offset.zero,
                              onPanUpdate: (d) => swipe += d.delta,
                              onPanEnd: (_) {
                                if (swipe.distance < 14) return;
                                if (swipe.dx.abs() > swipe.dy.abs()) {
                                  move(swipe.dx > 0 ? 1 : -1, 0);
                                } else {
                                  move(0, swipe.dy > 0 ? 1 : -1);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CustomPaint(painter: BoardPainter(game)),
                                    if (game.paused)
                                      ColoredBox(
                                        color: ink.withValues(alpha: .88),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const FrogArt(size: 90),
                                              const Text(
                                                'Take a breather.',
                                                style: TextStyle(
                                                  color: cream,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: 180,
                                                child: FilledButton(
                                                  onPressed: pause,
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: lime,
                                                    foregroundColor: ink,
                                                  ),
                                                  child: const Text('Resume'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      game.feedbackTime > 0
                          ? game.feedback
                          : 'Swipe anywhere on the board to hop',
                      key: ValueKey(
                        game.feedbackTime > 0 ? game.feedback : 'hint',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    direction(Icons.arrow_back, -1, 0, 'Hop left'),
                    direction(Icons.arrow_upward, 0, -1, 'Hop up'),
                    direction(Icons.arrow_downward, 0, 1, 'Hop down'),
                    direction(Icons.arrow_forward, 1, 0, 'Hop right'),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget direction(IconData icon, int dx, int dy, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: IconButton.filledTonal(
      onPressed: () => move(dx, dy),
      tooltip: label,
      icon: Icon(icon),
    ),
  );
  Widget stat(String label, String value, {bool alert = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(label),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: alert ? const Color(0xffc8523d) : ink,
        ),
      ),
    ],
  );
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.store,
    required this.result,
    this.record = false,
    this.saved = true,
  });
  final GameStore store;
  final RoundResult result;
  final bool record, saved;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late bool saved = widget.saved;
  bool retrying = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Round complete'),
    ),
    body: PageBody(
      children: [
        const SizedBox(height: 12),
        const Center(child: Eyebrow('YOU MADE A SPLASH')),
        const SizedBox(height: 18),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .6, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: const FrogArt(size: 120),
        ),
        const SizedBox(height: 12),
        Text(
          widget.result.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        if (widget.record)
          const Text(
            'NEW PERSONAL BEST',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff527c30),
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text(
                'FINAL SCORE',
                style: TextStyle(color: lime, letterSpacing: 2, fontSize: 11),
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: widget.result.score),
                duration: const Duration(milliseconds: 900),
                builder: (_, value, _) => Text(
                  '$value',
                  style: const TextStyle(
                    color: cream,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${widget.result.crossings} frogs home  ·  ${widget.result.bonuses} flies caught',
                style: const TextStyle(color: cream),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.result.crossings} × 100 crossing points + ${widget.result.bonuses} × 25 bonus points',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xff63776a)),
        ),
        if (!saved) ...[
          const SizedBox(height: 12),
          const Text(
            'Score could not be saved on this device.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: retrying
                ? null
                : () async {
                    setState(() => retrying = true);
                    try {
                      await widget.store.save(
                        widget.store.username!,
                        widget.result,
                      );
                      if (mounted) setState(() => saved = true);
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    } finally {
                      if (mounted) setState(() => retrying = false);
                    }
                  },
            child: const Text('Retry saving'),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => GameScreen(store: widget.store),
            ),
          ),
          icon: const Icon(Icons.replay),
          label: const Text('Play Again'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () =>
              openScreen(context, ScoresScreen(store: widget.store)),
          child: const Text('High Scores'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => resetTo(context, HomeScreen(store: widget.store)),
          child: const Text('Main Menu'),
        ),
      ],
    ),
  );
}

class ScoresScreen extends StatelessWidget {
  const ScoresScreen({super.key, required this.store});
  final GameStore store;
  @override
  Widget build(BuildContext context) {
    final top = store.scores.take(3).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('High Scores')),
      body: PageBody(
        children: [
          const SizedBox(height: 20),
          const Eyebrow('THE POND’S FINEST'),
          const SizedBox(height: 12),
          Text(
            'Little frogs.\nLegendary leaps.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            'The top three personal bests on this device.',
            style: TextStyle(color: Color(0xff63776a)),
          ),
          const SizedBox(height: 30),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: i == 0 ? ink : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Rank ${i + 1}',
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 52,
                            color: [
                              const Color(0xffeacd7b),
                              const Color(0xffa3b6bb),
                              const Color(0xffc38e68),
                            ][i],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i < top.length ? top[i].name : 'Your spot awaits',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: i == 0 ? cream : ink,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            i < top.length
                                ? '${top[i].crossings} frogs brought home'
                                : 'Finish a round to join',
                            style: TextStyle(
                              color: i == 0
                                  ? const Color(0xffc4cfb9)
                                  : const Color(0xff63776a),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      i < top.length ? '${top[i].score}' : '—',
                      style: TextStyle(
                        color: i == 0 ? lime : ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Every crossing counts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff63776a)),
          ),
        ],
      ),
    );
  }
}
