# Relief Valve [![Travis](https://img.shields.io/travis/mathphreak/ReliefValve.svg?style=flat-square)](https://travis-ci.org/mathphreak/ReliefValve) [![Codecov](https://img.shields.io/codecov/c/github/mathphreak/ReliefValve.svg?style=flat-square)](https://codecov.io/github/mathphreak/ReliefValve)

[![GitHub Release Downloads](https://img.shields.io/github/downloads/mathphreak/ReliefValve/latest/total.svg?style=flat-square)][latest release]
[![GitHub Latest Release](https://img.shields.io/github/release/mathphreak/ReliefValve.svg?style=flat-square)][latest release]
[![GitHub issues](https://img.shields.io/github/issues/mathphreak/ReliefValve.svg?style=flat-square)](https://github.com/mathphreak/ReliefValve/issues)

[![Dependencies](https://img.shields.io/david/mathphreak/ReliefValve.svg?style=flat-square)](https://david-dm.org/mathphreak/ReliefValve)
[![Development Dependencies](https://img.shields.io/david/dev/mathphreak/ReliefValve.svg?style=flat-square)](https://david-dm.org/mathphreak/ReliefValve#info=devDependencies)

Prevents dangerous Steam buildups by letting you juggle games
between library locations.

# Usage
Relief Valve now works well on Windows and acceptably on Mac/Linux.
I'd say it's now better than [Steam Mover][]
in most ways, but it will keep improving.

0. Make sure Steam already knows about your existing libraries.
1. Exit Steam (this is important).
2. Download the [latest release][], extract it, and run `relief-valve`.
3. Wait for Relief Valve to populate all your Steam games.
4. Check the box next to one or more games.
5. Select a destination at the bottom of the window.
6. Click "Move".
7. Wait for your selected games to finish moving.
   A progress bar should appear below the footer you just clicked inside.
   It will animate and look cool.
8. Relaunch Steam. Your games will be in their new locations.

# Stack
Relief Valve is built on Electron and uses the Noto Sans fonts from Google,
Yahoo's pure.css, Font Awesome, Zepto.js, [Vex][], and
[all this stuff][npm dependencies].

# Design
Relief Valve is designed to imitate the [Pressure][] skin because it's the best.

[Steam Mover]: http://www.traynier.com/software/steammover
[latest release]: https://github.com/mathphreak/ReliefValve/releases/latest
[npm dependencies]: https://github.com/mathphreak/ReliefValve/blob/v0.11.0/package.json#L6-L41
[Pressure]: http://hydra.tf/pressure/
[Vex]: http://github.hubspot.com/vex/
