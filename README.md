# Froggy Crosser

A Flutter portrait arcade game built from the UTS Emerging Technology brief.

## Run

```sh
flutter pub get
flutter run -d chrome --web-port 8765
```

For Android, connect a device or start an emulator, then run `flutter run`.
The app requests portrait orientation. Wide web windows keep the game board narrow.
Use a stable web port so browser-local player data persists between runs.

## Play

Enter a player name (no password). Play Game opens the instructions.
Swipe on the board to move one tile, or use the optional directional buttons.
Desktop controls: arrow keys or WASD.

- Each round lasts 60 active seconds.
- Reach the far bank to earn 100 points and bring one frog home.
- Cars, slower trucks, and faster race cars reset the frog on collision.
- River logs carry the frog. Water and drifting off the board reset it.
- Golden flies appear on the middle bank for 5 seconds and award 25 points.
- Pause freezes the timer and world. Switching apps pauses automatically.
- After a collision/crossing, a brief 0.35-second recovery prevents accidental repeated moves.

Results show score, crossings, fly count, and the six exact assignment titles.
Shared Preferences stores the login and each player's personal best. The leaderboard shows the best three distinct players, descending by score; ties use alphabetical name order. Names are case-sensitive. Logout preserves scores. Data stays on the device/browser and is not an online account.

## Code map

- `lib/main.dart`: five screens, navigation, gestures, lifecycle and animation ticker.
- `lib/game_engine.dart`: deterministic movement, lanes, collisions, timer and scoring.
- `lib/game_store.dart`: Shared Preferences and JSON score records.
- `lib/art.dart`: original Flutter canvas artwork.
- `assets/CREDITS.md`: artwork information.

Flutter's Ticker drives continuous motion; the game engine subdivides elapsed time into small steps for collision detection. The application uses the widgets, state, async storage and animation concepts from Weeks 1–7. No React or game-engine dependency is used.

## Checks

```sh
flutter analyze
flutter test
flutter build web
```

Tests cover collisions for all vehicle types, log support/drift, water, boundaries, scoring/titles, bonus collection, pause/timer completion, persistence, login/logout and screen navigation.

## Assignment packaging

Include `lib/`, `assets/`, and `pubspec.yaml` in a ZIP. Rename with your actual student numbers: `FroggyCrosser_NRP1_NRP2.zip` (use the naming expected by your lecturer for solo work). Review and understand the code before your demo. No submission is performed by this project.
