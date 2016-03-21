# Relief Valve [![Travis](https://img.shields.io/travis/mathphreak/ReliefValve.svg?style=flat-square)](https://travis-ci.org/mathphreak/ReliefValve) [![Codecov](https://img.shields.io/codecov/c/github/mathphreak/ReliefValve.svg?style=flat-square)](https://codecov.io/github/mathphreak/ReliefValve)

[![GitHub Release Downloads](https://img.shields.io/github/downloads/mathphreak/ReliefValve/latest/total.svg?style=flat-square)][latest release]
[![GitHub Latest Release](https://img.shields.io/github/release/mathphreak/ReliefValve.svg?style=flat-square)][latest release]
[![GitHub issues](https://img.shields.io/github/issues/mathphreak/ReliefValve.svg?style=flat-square)](https://github.com/mathphreak/ReliefValve/issues)

Prevents dangerous Steam buildups by letting you juggle games
between library locations.

# Usage
Relief Valve works on Windows, Mac, and Linux.
I'd say it's now better than [Steam Mover][].

0. Make sure Steam already knows about your existing libraries.
1. Exit Steam (this is important).
2. Download the [latest release][], extract it, and run `relief-valve`.
3. Wait for Relief Valve to populate all your Steam games.
4. Check the box next to one or more games.
5. Select a destination at the bottom of the window.
   Relief Valve will not let you move a game to the place where it already is.
6. Click "Move".
7. Wait for your selected games to finish moving.
   A progress bar should appear below the footer you just clicked inside.
8. Relaunch Steam. Your games will be in their new locations.

# Stack
Relief Valve is built on Electron and uses the Noto Sans fonts from Google,
Yahoo's pure.css, Font Awesome, Zepto.js, [Vex][], and
[all this stuff][npm dependencies].

# Design
Relief Valve is designed to imitate the [Pressure][] skin because it's the best.

[Steam Mover]: http://www.traynier.com/software/steammover
[latest release]: https://github.com/mathphreak/ReliefValve/releases/latest
[npm dependencies]: https://github.com/mathphreak/ReliefValve/blob/v0.15.0/package.json#L7-L46
[Pressure]: http://hydra.tf/pressure/
[Vex]: http://github.hubspot.com/vex/
